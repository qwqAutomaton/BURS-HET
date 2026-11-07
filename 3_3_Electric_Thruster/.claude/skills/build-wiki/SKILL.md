---
name: build-wiki
description: 从 raw 目录中的原始文件构建或增量更新 wiki 知识库，生成带交叉引用和索引的条目文件
---

# build-wiki — 从 raw 文件构建/更新 wiki 知识库

## 前置条件

raw/ 目录下需已有文件。若为空，先提示用户放入文件。

## 两种运行模式

### 全量构建（首次运行）

当 `wiki/.manifest.json` 不存在时，执行全量构建。

### 增量更新（raw 文件变动后）

当 `wiki/.manifest.json` 已存在时，执行增量更新：只处理变化的 raw 文件，但全量刷新索引和链接。

## 增量更新流程

### 第一步：读取 manifest，检测变动

读取 `wiki/.manifest.json`，该文件记录了上次构建时每个 raw 文件的状态：

```json
{
  "files": {
    "raw/chapter1/topic.md": {
      "ref": "REF-0001",
      "hash": "abc123...",
      "entries": ["entries/主题名.md", "entries/主题名/子条目.md"]
    }
  },
  "nextRef": 5
}
```

对比当前 raw/ 目录，将文件分为三类：

| 类别 | 判断依据 | 操作 |
|------|----------|------|
| **新增** | 在 raw/ 中存在但 manifest 中无记录 | 分配新 REF 编号，读取并生成条目 |
| **修改** | 在 manifest 中有记录但 hash 已变化 | 保留原 REF 编号，重新读取并更新对应条目 |
| **删除** | 在 manifest 中有记录但 raw/ 中已不存在 | 删除对应条目文件，REF 编号标记为已释放不复用 |
| **未变** | hash 一致 | 跳过，不重新读取 |

### 哈希的唯一计算口径（跨平台稳定，必须严格遵守）

`hash` 必须按下面的口径计算——这是在 macOS / Windows 之间唯一稳定的定义：

```python
import hashlib, pathlib

def file_hash(path) -> str:
    data = pathlib.Path(path).read_bytes()   # 1) 必须二进制读取
    data = data.replace(b"\r\n", b"\n")      # 2) 换行符归一化，消除 CRLF/LF 差异
    return hashlib.sha256(data).hexdigest()[:16]
```

- **必须二进制读取**（`read_bytes()` / `open(p, "rb")`）。用文本模式会触发 Python 的 universal newlines 换行转换，并按平台默认编码解码（Windows 常见 GBK、macOS 为 UTF-8），中文文件必然算出不同哈希。
- **先 `CRLF → LF` 归一化再哈希，对文本与二进制文件统一执行**：无论 git 的换行符策略如何、还是「在 Windows 上未提交就用 CRLF 编辑过」，两台机器的哈希都保持一致。归一化必须对所有文件一视同仁，**不要引入「文本/二进制」分支**（git 自己的 text 判定只看前 8000 字节有无 NUL，本仓库已有 PDF 被误判为文本）。
- **manifest 的 key 只用「相对项目根的 posix 路径」**：分隔符固定为 `/`，不含盘符、不含绝对路径；并对文件名做 NFC 归一化 `unicodedata.normalize("NFC", rel)`，避免 macOS 的 NFD 与 Windows 的 NFC 对不上而被误判成「删除 + 新增」。
- **只用 `hashlib.sha256`**；禁止 Python 内置 `hash()`（每进程随机盐，永远不一致）。
- **禁止用 mtime / 文件大小判断是否改动**，一律以内容哈希为准。
- 仓库根应存在 `.gitattributes`（`* text=auto eol=lf`，且对 `*.pdf`、`*.pptx` 等显式 `-text`）。若哈希仍对不上，先用 `git ls-files --eol` 查换行符，**不要直接改 raw/ 文件**。

### 第二步：处理变动的文件

仅对新增和修改的文件执行以下操作：

按照全量构建中的第三步和第四步，读取文件内容 → 分析题目/知识点 → 生成/更新 wiki 条目。

- **新增文件**：从 `nextRef` 开始分配新编号，生成新条目
- **修改文件**：保留原 REF 编号，删除旧条目文件，重新生成
- **删除文件**：删除对应的条目文件（目录为空则一并删除目录）

### 第三步：全量刷新索引和链接

无论变动范围多大，以下内容必须全量重写以保持一致性：

1. **更新 manifest** — 写入新的 `wiki/.manifest.json`，反映当前 raw/ 完整状态
2. **重建 REFERENCES.md** — 基于 manifest 的最新 file→ref 映射
3. **重建 INDEX.md** — 基于 `wiki/entries/` 的完整目录树
4. **全量验证链接** — 检查所有 `[[...]]` 链接、raw 文件链接、INDEX 链接

## 全量构建流程（首次运行或手动要求）

### 第一步：扫描 raw 目录，建立参考文献编号

遍历 raw/ 下所有文件（递归），为每一个文件分配唯一的文献编号 `REF-XXXX`（4 位数字，从 0001 起，编号不回收）。

记录每个文件的：编号、文件名、路径、类型、hash。

### 第二步：构建参考文献索引

生成 `wiki/REFERENCES.md`：

```markdown
# 参考文献索引

| 编号 | 原始文件 | 路径 | 格式 |
|------|----------|------|------|
| REF-0001 | xxx.md | raw/xxx.md | Markdown |
| REF-0002 | yyy.pdf | raw/yyy.pdf | PDF |
```

### 第三步：读取并分析每一个 raw 文件

对 raw 中的每一个文件，识别其中包含的独立"题目"或"知识点"：
- Markdown 文件中由各级标题（#, ##, ###）分隔的段落
- 题集文件中每道题视为一个独立条目
- 单篇文章中每个小节视为子条目

### 第四步：构建 wiki 条目

规则：
- **每个条目一个 md 文件**，存放在 `wiki/entries/` 目录下
- 文件名使用条目标题（去除特殊字符，用 `-` 连接）
- 若一个题目下子内容较多，为该题目创建子文件夹，内含多个 md 文件
- 每个条目文件头部包含元信息：

```markdown
# 条目标题

> **来源**: [原始文件名](../raw/xxx.md) | **编号**: [REF-XXXX](../REFERENCES.md#ref-xxxx)
```

条目正文中引用其他条目时，使用 `[[条目名]]` 格式指向对应条目文件。

### 第五步：构建目录索引

生成 `wiki/INDEX.md`，反映 wiki/entries/ 的完整目录树：

```markdown
# Wiki 目录索引

## 条目列表

- [条目1](entries/条目1.md)
  - [子条目1.1](entries/条目1/子条目1-1.md)
- [条目2](entries/条目2.md)
```

### 第六步：写入 manifest

生成 `wiki/.manifest.json`，记录本次构建的完整状态，作为下一次增量更新的基线。

### 第七步：验证超链接完整性

1. 所有 wiki 内部 `[[...]]` 链接的目标文件是否存在
2. 所有指向 raw 文件的链接是否有效
3. INDEX.md 中的链接是否能正确跳转
4. REFERENCES.md 中的文件路径是否正确

将验证结果连同增量/全量变更摘要输出给用户。

## 注意事项

- raw/ 只读不写，不做任何修改
- wiki/ 目录下的内容可完全重新生成，用户不会手动编辑
- 文件名避免使用空格和特殊字符
- 相对路径统一使用 `/` 作为分隔符
- 二进制文件（PDF、图片等）在条目中标注类型和位置，不做内容提取
- REF 编号一旦分配，永不回收，保持文献引用的稳定性
- `.manifest.json` 是 wiki 的内部状态文件，不出现在 INDEX.md 中
