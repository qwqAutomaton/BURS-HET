\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{mynotes}[2026/06/25 v1.0 个人笔记模板]

% 基于 ctexrep 文档类（中文支持，支持 \chapter）
\LoadClass[
  a4paper,
  zihao=-4,
  fontset=windows
]{ctexrep}

% 伪加粗与伪斜体（CJK 字体通常无独立粗/斜体字型）
% 原理：ctex 将 \bfseries→黑体(BoldFont)、\itshape→楷体(ItalicFont)
% 这里将 BoldFont 和 ItalicFont 改回宋体，通过 fontspec 的 FakeBold/FakeSlant 实现伪效果
\setCJKmainfont{SimSun}[
  BoldFont       = {SimSun},
  BoldFeatures   = {FakeBold  = 2.5},
  ItalicFont     = {SimSun},
  ItalicFeatures = {FakeSlant = 0.20}
]

% 黑体（sans 字族，\heiti 命令使用）
\setCJKsansfont{SimHei}[
  BoldFont     = {SimHei},
  BoldFeatures = {FakeBold = 3.0}
]

% 加载必要的宏包
\RequirePackage{geometry}
\RequirePackage{setspace}
\RequirePackage{hyperref}
\RequirePackage{graphicx}
\RequirePackage{amsmath, amssymb}
\RequirePackage{booktabs}
\RequirePackage{multirow}
\RequirePackage{fancyhdr}
\RequirePackage{titlesec}
\RequirePackage{titletoc}
\RequirePackage{footmisc}
\RequirePackage{enumitem}
\RequirePackage{subcaption}

% 列表环境全局间距：条目内部与正文行距一致
\setlist{
  before=\setstretch{\mynotes@stretch},
  itemsep=0pt,
  parsep=0pt,
  topsep=0pt,
  partopsep=0pt,
  itemindent=0pt,
  leftmargin=2em
}

% 页面设置
\geometry{
  left=2cm,
  right=2cm,
  top=2.5cm,
  bottom=2cm,
  headheight=14pt
}

% 行间距因子（手动调节此值：1.0=单倍 1.2=1.2倍 1.5=1.5倍）
\newcommand{\mynotes@stretch}{1.25}

% 行距
\setstretch{\mynotes@stretch}

% 段间距为0，首行缩进两汉字
\setlength{\parskip}{6pt}
\setlength{\parindent}{2em}

% 页眉页脚设置
\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\small \leftmark}
\fancyhead[R]{\small \thepage}
\fancyfoot[C]{\small \thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

% 编号格式
% section 编号不包含 chapter，仅显示阿拉伯数字
\renewcommand{\thesection}{\arabic{section}}
\renewcommand{\thesubsection}{\thesection.\arabic{subsection}}

% 章节标题格式
% chapter：居中，汉字编号（第一章、第二章...）
\titleformat{\chapter}[block]
  {\LARGE\bfseries\centering}
  {第\chinese{chapter}章}{1em}{}

% section：左对齐，阿拉伯数字，三号，黑体
\titleformat{\section}[block]
  {\zihao{-3}\heiti}
  {\thesection}{1em}{}
\titlespacing{\section}{0pt}{2ex plus 1ex minus .5ex}{1ex plus .5ex minus .2ex}

% subsection：左对齐，阿拉伯数字，与正文同号，黑体
\titleformat{\subsection}[hang]
  {\heiti}
  {\thesubsection}{1em}{}
\titlespacing{\subsection}{0pt}{1.5ex plus .5ex minus .3ex}{0.5ex plus .3ex minus .2ex}

% subsubsection：保持原格式
\titleformat{\subsubsection}[block]
  {\bfseries}
  {\thesubsubsection}{1em}{}
\titlespacing{\subsubsection}{0pt}{1ex plus .5ex minus .3ex}{0.5ex plus .3ex minus .2ex}

% 目录设置
\setcounter{tocdepth}{2}
\setcounter{secnumdepth}{3}

% 超链接设置
\hypersetup{
  colorlinks=true,
  linkcolor=blue,
  citecolor=blue,
  urlcolor=blue,
  pdfborder=0 0 0
}

% 图表标题格式
\usepackage[labelsep=quad]{caption}

% 脚注设置
\setlength{\footnotemargin}{1em}
