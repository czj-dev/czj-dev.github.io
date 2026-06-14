---
layout: post
title: "Obsidian 完全指南：从入门到 AI 驱动的知识管理"
subtitle: "工具推荐"
date: 2026-06-12 15:00:00
author: "Nutcracker"
header_image: "img/post-bg-obsidian-guide.jpg"
catalog: true
description: "从安装配置到插件推荐，再到用 Claude Code 实现 LLM Wiki 模式，一篇搞定 Obsidian 知识管理体系搭建。"
keywords:
  - Obsidian
  - 知识管理
  - Claude Code
  - LLM Wiki
  - Notion 迁移
tags:
  - 工具
  - 知识管理
  - 效率
---

你的笔记散落在多少个 App 里？微信收藏、Notion 表格、浏览器书签、备忘录…… 每次想找个东西，就像在十个抽屉里翻钥匙。

我用 Obsidian 搭建知识库有一段时间了，后来又接上 Claude Code 做 AI 辅助的知识管理，效果不错。这篇文章把我从安装到搭建 AI 知识库的完整路径整理出来，希望能省掉你踩坑的时间。

## 装好就能用

### 安装

去 [obsidian.md](https://obsidian.md/) 下载安装包。全平台支持——Windows、macOS、Linux、iOS、Android，个人使用免费，没有高级版锁定，没有「免费用户只能建 1000 条笔记」之类的限制。

打开后选「创建新仓库（Vault）」，指定一个文件夹路径。这一步值得想一下：选一个你不容易误删、方便同步的位置。比如 `D:\Obsidian\` 或者 Dropbox 里的某个文件夹。之后所有笔记、附件、插件配置都存在这里。

仓库建好后的第一件事：打开文件管理器，去那个文件夹看一眼。

你会看到一堆 `.md` 文件。随便用一个双击，用记事本打开——能读。用 Typora 打开——能读。用 VS Code 打开——能读。这就是 Obsidian 和 Notion、Roam Research 最本质的区别：你的笔记就是纯文本 Markdown 文件，不锁在任何平台里。今天不想用 Obsidian 了，文件搬走就行，什么都不会丢。

> 💡 如果你用多台设备，可以用 iCloud、OneDrive、Dropbox 或 Syncthing 同步仓库文件夹。国内用户可以试试中科云（[data.cstcloud.cn/my/app](https://data.cstcloud.cn/my/app)），免费同步方案。Obsidian 官方也有付费同步服务（Obsidian Sync），但不是必须的。

### 核心操作

Obsidian 的学习曲线不陡：

- 双向链接：用 `[[笔记名]]` 在笔记之间建立关联。比文件夹分类灵活得多——一个想法可以同时属于多个上下文
- 标签系统：用 `#标签` 做宽泛分类，跟链接互补
- 关系图谱：右上角的图谱视图能看到所有笔记之间的连接关系。刚开始用的时候，看着知识网络一点点长出来确实有点上瘾
- 每日笔记：一条命令创建当天日记，适合随手记碎片想法

> 接上 LLM Wiki 之后，AI 会帮你维护目录和索引，你只管写就行。

## 从 Notion 搬家到 Obsidian

从 Notion 迁移是很多人关心的问题。Obsidian 官方有专门的搬家工具，流程不复杂。

### 搬家工具：Obsidian Importer

![Importer](img/plugins/importer.png)

[Obsidian Importer](https://obsidian.md/plugins?id=obsidian-importer) 是官方出品的迁移插件（[GitHub](https://github.com/obsidianmd/obsidian-importer)），支持 Notion、Evernote、OneNote、Apple Notes、Bear、Google Keep、Roam Research 等平台一键导入。它把原始格式的笔记转换成 Markdown，保留尽可能多的内容和结构。

- 支持平台：Notion、Apple Notes、Bear、Evernote、Google Keep、OneNote、Roam Research
- 文件格式：HTML、CSV、Markdown 等通用格式
- 由 Obsidian 团队维护，兼容性有保障

### 迁移三步走

1. 在 Notion 设置里选「导出所有工作区内容」，格式选 Markdown & CSV，打开「包含子页面」
2. Obsidian 设置 → 社区插件 → 搜索「Importer」并安装
3. 打开 Importer，选 Notion 格式，指向导出的 ZIP，点击导入

Importer 会自动处理 Notion 的数据库、页面层级、内部链接。

> 导入前建议先在一个空 vault 里试一次，确认格式满意后再导入正式 vault。数据量大或关联复杂的情况，可以看看社区的 [notion2obsidian](https://github.com/bitbonsai/notion2obsidian)，对双向链接的处理更细致。

### 搬过来之后

搬过来之后有个思维转换的过程：

- Notion 的数据库很强，但 Obsidian 的优势在链接。试着用 `[[` 把相关笔记连起来，而不是把它们塞进一张表
- 复杂的 Notion 数据库迁移后可能需要手动调整，这正好是一次「知识瘦身」的机会
- 不必一次搬完。先迁最常用的部分，剩下的按需处理

## 插件推荐：16 个我实际在用的

Obsidian 开箱已经够用，但社区插件生态让它能走得更远。以下是我实际安装使用的 16 个插件，按用途分组。所有插件都可以在 [Obsidian 社区插件市场](https://community.obsidian.md/) 搜索安装。

### 整理和查找

#### Notebook Navigator — 替代默认文件浏览器

![Notebook Navigator](img/plugins/notebook-navigator.png)

Obsidian 默认的文件浏览器功能比较简单——一个文件夹列表，没了。Notebook Navigator 把它替换成一个双窗格界面：左侧是文件夹/标签/属性导航树，右侧是文件列表，**支持键盘导航、文件预览、高级搜索过滤**。上线两个月下载量超过 15 万，兼容 10 万+ 笔记的大型仓库。

- 双窗格布局：左侧导航 + 右侧文件列表，支持水平/垂直切换
- 高级过滤：文件名、标签、属性、日期组合筛选，支持 AND/OR 逻辑
- 完整键盘导航：方向键在窗格间切换，可配 VIM 风格快捷键
- 1-5 行笔记预览、自动缩略图、日期分组
- 置顶笔记、快捷方式、Folder Notes 支持

> 用过的双窗格文件管理器里做得最精致的一个。大仓库（笔记上千篇）强烈推荐，检索效率提升明显。

🔗 [GitHub](https://github.com/johansan/notebook-navigator) · [社区](https://obsidian.md/plugins?id=notebook-navigator)

#### Tag Wrangler

![Tag Wrangler](img/plugins/tag-wrangler.png)

右键点标签就能批量改名、合并、调整层级。

- 全库重命名：一键把 `#旧名` 改成 `#新名`，所有笔记自动更新
- 标签合并：把同义标签合成一个
- 标签页面：给标签创建「主页」，写说明和关联链接

> 重命名标签前先备份 vault，操作不可撤销。

🔗 [GitHub](https://github.com/pjeby/tag-wrangler) · [社区](https://obsidian.md/plugins?id=tag-wrangler)

#### Iconic — 换图标和颜色

![Iconic](img/plugins/iconic.webp)

默认的文件图标千篇一律。Iconic 可以给文件、文件夹、标签换上 1700 多个图标或 1900 多个 emoji，还能上色。

- 右键任何文件/文件夹/标签选择图标
- 按文件名、标签、扩展名自动分配图标
- 每个图标可选 9 种主题色

> 先设几条「文件夹规则」自动给不同目录上图标，比手动设效率高。

🔗 [GitHub](https://github.com/gfxholo/iconic) · [社区](https://obsidian.md/plugins?id=iconic)

### 最常用

#### Templater：增强版模板

![Templater](img/plugins/templater.png)

Obsidian 自带的模板功能比较基础，Templater 可以理解为它的增强版。模板里能插入变量（日期、文件名、剪贴板内容）、执行 JavaScript 代码、根据文件夹自动匹配不同模板。比如新建日记时自动插入日期和天气模板，新建会议记录时自动插入参会人员列表。

- 变量插值：`<% tp.date %>`、`<% tp.file.title %>` 等动态内容自动填充
- 文件夹自动模板：不同文件夹绑定不同模板
- 自定义脚本：复杂逻辑封装成 JS 脚本，模板中一行调用
- Hooks 回调：模板执行完后自动触发后续操作

> 开启 `Trigger Templater on new file creation` + 配置 Folder Templates，新建笔记会自动套用模板。

🔗 [GitHub](https://github.com/SilentVoid13/Templater) · [社区](https://obsidian.md/plugins?id=templater-obsidian)

#### Dataview — 把笔记库当数据库来查

![Dataview](img/plugins/dataview-table.png)

想看所有评分超过 8 分的书？列出本周未完成的任务？按项目分组显示进度？这些不用手动维护列表，一条查询语句就能自动生成表格。

- DQL 查询语言：`TABLE`/`LIST`/`TASK` 三种视图
- 内联字段：笔记中写 `rating:: 8`，就能被查询到
- DataviewJS：JavaScript 查询模式，灵活度最高
- 实时更新：源数据变了，结果自动刷新

> 先从 DQL 学起（`TABLE/LIST/TASK`），满足不了再上 DataviewJS。

🔗 [GitHub](https://github.com/blacksmithgu/obsidian-dataview) · [社区](https://obsidian.md/plugins?id=dataview)

#### Tasks

![Tasks](img/plugins/tasks-queries.png)

像一个能看穿所有笔记本的待办清单。在任意笔记里写待办事项（带截止日期 📅、重复周期 🔁、优先级 ⏫），然后在一个页面里汇总查看。打勾后源文件自动更新。

- 截止/计划/重复日期：emoji 标记，支持自然语言
- 任务查询块：按条件筛选（未完成、今天到期、按文件分组等）
- 可视化编辑弹窗：不用记语法
- 全局筛选：只识别带 `#task` 标记的待办

> 把「Toggle checkbox status」快捷键替换为 `Tasks: Toggle Done`，打勾会自动记录完成日期。

🔗 [GitHub](https://github.com/obsidian-tasks-group/obsidian-tasks) · [社区](https://obsidian.md/plugins?id=obsidian-tasks-plugin)

#### Omnisearch

![Omnisearch](img/plugins/omnisearch.gif)

Obsidian 自带搜索够用但不够强。Omnisearch 的优势在于智能权重排序（标题匹配优先于正文）、PDF 和图片内文字搜索、拼写容错。

- 智能权重：标题匹配的笔记排在前面
- PDF/图片搜索：配合 Text Extractor 插件
- 容错匹配：拼写错误也能找到
- 精确语法：`"精确短语"` 和 `-排除词`

> 中文用户需要额外安装 `cm-chs-patch` 插件才能正确分词。

🔗 [GitHub](https://github.com/scambier/obsidian-omnisearch) · [社区](https://obsidian.md/plugins?id=omnisearch)

#### Calendar

![Calendar](img/plugins/calendar.png)

侧边栏放一个迷你日历，点哪天就跳到那天的日记。日历上有小圆点显示每天写了多少字，一眼看出哪天在摸鱼。点击周数还能打开周记。

- 点日期跳转日记，没有的自动新建
- 小圆点显示每天字数（默认 250 字一个点）
- 点击周数打开周记
- Ctrl/Cmd + 悬停预览日记内容

> 配合核心插件「Daily Notes」使用，设好日记格式和存放文件夹。

🔗 [GitHub](https://github.com/liamcain/obsidian-calendar-plugin) · [社区](https://obsidian.md/plugins?id=calendar)

### 画图和批注

#### Excalidraw — 手绘风格白板

![Excalidraw](img/plugins/excalidraw.jpg)

把 Excalidraw 在线白板工具搬进了 Obsidian。随手画流程图、架构图、思维导图，手绘风格不死板。画里的元素能链接到笔记，笔记也能嵌入画。

功能很丰富，入门需要一点时间，但一旦上手会很依赖它。

- 手绘画板：自由绘制各类图表，支持触摸屏
- 笔记互链：画中元素可链接笔记，笔记可嵌入画
- 嵌入 Markdown：整篇笔记拖进画布显示
- 自动导出：保存时自动生成 PNG/SVG
- 脚本引擎：支持自定义脚本，有脚本商店

> 开启自动导出 SVG/PNG，博客和分享时不用打开 Obsidian 就能看到图。

🔗 [GitHub](https://github.com/zsviczian/obsidian-excalidraw-plugin) · [社区](https://obsidian.md/plugins?id=obsidian-excalidraw-plugin)

#### Annotator — 在笔记里给 PDF 划重点

![Annotator](img/plugins/annotator.gif)

不用离开 Obsidian 就能打开 PDF 或 EPUB，选中文字直接高亮和写批注。批注保存在本地 Markdown 文件里，可以搜索、链接、标签管理。

- PDF/EPUB 批注：选中即可高亮
- 批注自动存为 Markdown 引用块
- 全部本地存储
- 点击批注链接，自动打开 PDF 跳转到对应位置

> 不要重命名被批注的 PDF/EPUB 原文件，否则批注会丢失关联。

🔗 [GitHub](https://github.com/elias-sundqvist/obsidian-annotator) · [社区](https://obsidian.md/plugins?id=obsidian-annotator)

#### Mermaid Tools — 画流程图不用背语法

Obsidian 原生支持 Mermaid 语法画图，但你得记住代码写法。这个插件装了一个工具栏，把常用图表元素做成按钮，点一下就自动插入。

- 侧边栏列出常用元素，点击即插入
- 可自定义元素，打造个人素材库
- 实时预览

🔗 [GitHub](https://github.com/dartungar/mermaid-tools) · [社区](https://obsidian.md/plugins?id=mermaid-tools)

### 编辑体验

#### Hover Editor：悬浮编辑

原来鼠标悬停链接只弹出只读预览。Hover Editor 让弹出的窗口变成一个完整的迷你编辑器，能拖动、能缩放、能直接编辑。

- 预览窗口变成真正的编辑器
- 浮窗自由调整位置和大小
- 可同时打开多个浮窗对照查看

> 默认编辑模式建议设为「匹配当前文档模式」，体验最自然。

🔗 [GitHub](https://github.com/nothingislost/obsidian-hover-editor) · [社区](https://obsidian.md/plugins?id=obsidian-hover-editor)

#### Linter

![Style Settings](img/plugins/style-settings.png)

写完笔记不管格式多乱——多余空行、标题大小写不一致、中英文没空格——点一下 Linter，它按你设定的规则整理干净。支持 50 多条规则，每条独立开关。

- YAML 元数据整理：自动添加/去重/排序 frontmatter
- 中英文加空格：自动在两者之间插入空格
- 内容格式化：统一加粗/斜体风格、修正省略号、去除裸 URL
- 可设为保存时自动执行

> 初次使用只开「中英文间加空格」和「去除连续空行」两条，避免改动太大。

🔗 [GitHub](https://github.com/platers/obsidian-linter) · [社区](https://obsidian.md/plugins?id=obsidian-linter)

#### Admonition — 彩色提示框

![Admonition](img/plugins/admonition.png)

普通 Markdown 里，重要的提示和警告容易淹没在段落里。Admonition 给笔记加了蓝色备注、黄色警告、绿色小贴士等彩色提示框，关键信息一眼可见。内置 12 种类型，也能自定义。

- 12 种内置类型：note/info/tip/warning/danger 等
- 可折叠：长内容默认收起
- 可自定义类型

🔗 [GitHub](https://github.com/valentine195/obsidian-admonition) · [社区](https://obsidian.md/plugins?id=obsidian-admonition)

#### Style Settings：不用写 CSS 调主题

换主题就像买精装房，风格选定了但总有些细节想微调。以前改这些要手动编辑 CSS，Style Settings 让你拖拖滑块、选选颜色就能实时预览。

- 颜色选择器：可视化修改主题颜色
- 数值滑块：调整行宽、间距、圆角
- 明暗主题独立配色

> 安装后先去 Style Settings 面板看看当前主题有哪些可调选项。

🔗 [GitHub](https://github.com/mgmeyers/obsidian-style-settings) · [社区](https://obsidian.md/plugins?id=obsidian-style-settings)

### 记忆和复习

#### Spaced Repetition

![Spaced Repetition](img/plugins/spaced-repetition.png)

在笔记里写 `问题::答案` 就是一张卡片，插件根据记忆曲线自动安排复习时间。不用装 Anki，不用导出笔记。

- 多种格式：单行 `::`、双向 `:::`、填空 `==高亮==`
- 用 `#flashcards/主题` 层级标签分类牌组
- 整篇笔记也能按间隔重复复习
- 有统计面板查看复习数据

> 用 `#flashcards/主题名` 的层级标签管理牌组，避免所有卡片混在一起。

🔗 [GitHub](https://github.com/st3v3nmw/obsidian-spaced-repetition) · [社区](https://obsidian.md/plugins?id=obsidian-spaced-repetition)

---

插件不是越多越好。建议先装核心的 5 个（Templater + Dataview + Tasks + Calendar + Omnisearch），用熟了再按需加。

## 接上 AI：LLM Wiki 模式

### 接 AI：四个工具

让 AI 管知识库，涉及两类工具。**入口**决定你在哪和 AI 对话：Claudian 嵌在 Obsidian 里，Claude Code 在终端。**能力**决定 AI 怎么真正读写你的 vault：Obsidian Skills 教它懂格式，Obsidian CLI 让它能执行。入口挑一个就行，能力层的两个建议都装。后两个是 2026 年 Obsidian 官方新出的，下文展开。

#### Claudian：在 Obsidian 里用 AI

![Claudian](img/plugins/claudian.png)

[Claudian](https://community.obsidian.md/plugins/realclaudian)（[GitHub](https://github.com/YishenTu/claudian)）是当前 Obsidian 生态中最热门的 AI 集成插件，社区下载量超过 72 万。它让 AI 直接读写、搜索你的笔记，甚至执行命令，不用离开 Obsidian。

- 侧边栏多标签聊天窗口
- 行内编辑：选中文字按快捷键，AI 直接在原文上编辑，带差异对比
- 斜杠命令：`/` 调用提示模板和技能
- @上下文引用：`@` 引用仓库文件、子智能体、MCP 服务器
- Plan 模式：AI 先制定方案，确认后再执行
- 支持多后端：Claude Code、OpenAI Codex、Opencode

#### Claude Code：终端方案

如果你更喜欢终端，Claude Code 是 Anthropic 的命令行工具，功能同样强大。

```bash
# 在你的 Obsidian 仓库目录下启动
cd your-obsidian-vault
claude
```

#### Obsidian Skills：教 AI 懂 Obsidian 格式

这是 kepano（Obsidian 的 CEO）官方维护的一组 Agent Skill，放在 [github.com/kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)。它解决的问题很具体：AI 默认不懂 Obsidian 特有的写法——双向链接怎么嵌、callout 怎么折叠、frontmatter 字段叫什么、`.base` 数据库视图文件长什么样。装上这套 Skill，Claude Code（以及 Codex、OpenCode 等兼容 agent）就能写出语法正确的 Obsidian 文件，不会写坏链接或 callout。

五个 Skill 各管一类：

- obsidian-markdown：wikilink、callout、frontmatter、标签、嵌入这些笔记语法
- obsidian-bases：`.base` 文件，给 vault 建表格/卡片视图、过滤、公式（比如做个阅读进度看板）
- json-canvas：`.canvas` 画布文件，画思维导图和流程图
- obsidian-cli：教 agent 怎么正确调用 Obsidian CLI 命令
- defuddle：抓网页转成干净 markdown，做 Ingest 时比直接 WebFetch 噪声少

安装（Claude Code）：

```bash
/plugin marketplace add kepano/obsidian-skills
/plugin install obsidian@obsidian-skills
```

> 这套 Skill 和 Claudian/Claude Code 是正交关系：入口提供聊天界面，Skills 决定 Claude 在背后怎么处理你的文件。两者一起用。

#### Obsidian CLI：命令行操作 vault

Obsidian 官方在 2026 年新出的内置功能——把 vault 的操作能力开放给命令行。设置 → 通用里启用「命令行界面」，按提示注册到 PATH，就能在终端用 `obsidian` 命令读写运行中的仓库。注意它不是独立安装包，是 Obsidian 应用自带的。

为什么 LLM Wiki 场景需要它：agent 可以通过 CLI 直接搜笔记、读文件、追加 daily note、改属性、列任务，不用每次从头读遍整个 vault。配合脚本和 cron 还能做自动化，比如每天聚合周报、批量打标签。

常用命令：

```bash
obsidian search query="LLM Wiki"                          # 搜笔记
obsidian read file="index.md"                              # 读某篇
obsidian daily:append content="- [ ] 整理本周笔记"          # 往今日日记追加
obsidian tags counts                                       # 标签频次
obsidian property:set file="x.md" name="status" value="done"  # 改属性
```

> 一个限制：CLI 依赖 Obsidian 桌面端正在运行。如果要在服务器上 headless 跑 agent，需要配 Obsidian Sync 的 Headless 模式。

> 入口和能力是分开的。Claudian 和 Claude Code 通过仓库根目录的 `CLAUDE.md` 读规则，配置互通；Skills 和 CLI 是它们背后真正操作 vault 的手。入口挑一个，能力层的两个建议都装。

### LLM Wiki 是什么？

2026 年 4 月，Andrej Karpathy 发了一个 [Gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)，提出了 LLM Wiki 的概念。核心思想：

> 与其每次提问都让 AI 从原始文档里重新检索（RAG），不如让 AI 持续维护一个结构化的知识库。知识编译一次，持续复利。

#### 三层架构

```
原始资料层（只读）    ← PDF、文章、网页剪藏
       ↓
  Wiki 层（AI 维护）  ← AI 创建摘要页、概念页、交叉引用
       ↓
  Schema 层          ← 配置文件，告诉 AI 怎么维护这个知识库
```

原始资料是真相来源，永远不修改；Wiki 层由 AI 维护，负责提炼和连接；Schema 层是行为准则，确保 AI 按规矩办事。

Karpathy 的比喻很精准：Obsidian 是 IDE，AI 是程序员，Wiki 是代码库。

#### 三大操作

1. Ingest（摄取）：丢给 AI 一篇文章，它阅读后创建摘要页、更新相关概念页、维护索引。一篇资料可能触发 5-15 个页面更新
2. Query（查询）：对 wiki 提问，AI 在已有知识基础上综合回答。有价值的分析还会被保存回 wiki
3. Lint（维护）：定期检查矛盾、孤立页面、缺失链接

### 实际怎么搭？

这里提供两条路。

#### 方案一：让 AI 帮你搭（推荐新手）

最简单的方式：把 Karpathy 的原始 Gist 丢给 AI，让它帮你从零搭建。

1. 复制 [Karpathy 的 Gist 链接](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
2. 在 Claudian 或 Claude Code 里输入：

```
请阅读这个 Gist：https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
按照其中描述的 LLM Wiki 概念，在我的 Obsidian 仓库里搭建知识管理系统：
1. 创建 Wiki/ 目录和初始索引
2. 在仓库根目录生成 CLAUDE.md 配置文件
3. 给我一个我能理解的简要说明
```

3. AI 会创建目录结构、生成 `CLAUDE.md`、初始化索引文件
4. 检查生成的文件，按需微调

AI 会根据你的仓库现状适配方案，比照搬模板更贴合实际。

#### 方案二：手动搭建

如果你想理解每一步在做什么，可以参考我的结构手动搭建。

目录结构：

```
Vault/
├── Asset/           # 原始资料：PDF、图片、网页存档（只读）
├── Research/        # 研究资料（只读）
├── Wiki/            # AI 全权维护的知识库
│   ├── index.md     # 知识索引（AI 自动更新）
│   ├── log.md       # 操作日志
│   └── ...          # 按主题分类的摘要页和概念页
├── Workspace/       # 工作区：任务、周记
└── CLAUDE.md        # AI 行为配置文件
```

CLAUDE.md 初版模板——把下面内容保存为仓库根目录的 `CLAUDE.md`：

```markdown
# CLAUDE.md

## 项目概述
这是一个基于 Obsidian 的个人知识管理系统。

## 目录结构
- `Asset/` — 原始资料（PDF、图片），AI 只读
- `Wiki/` — AI 维护的知识库，AI 可以创建和修改
- `Workspace/` — 工作区，AI 可以创建和修改

## Wiki 维护规则
1. 每次操作 Wiki/ 后，更新 `Wiki/index.md` 索引
2. 新建页面必须有实质内容，不创建空壳页面
3. 修改文件时只改必须改的部分（最小侵入原则）
4. Wiki 中的事实陈述必须有来源，AI 分析标注为「AI 分析」
5. 对话中产生的高质量分析应保存回 Wiki，不让知识流失

## 三大操作
- **Ingest**：阅读资料 → 创建摘要页 → 更新相关概念页 → 维护索引
- **Query**：基于 Wiki 已有知识回答问题，有价值的分析回存
- **Lint**：检查矛盾、孤立页面、缺失链接

## 注意事项
- 不要修改 Asset/ 下的原始资料
- 删除文件或批量修改前需要确认
- 使用中文回复
```

> 这个模板是最小可用版本。跑起来之后，你会逐渐发现需要补充的规则。规则是长出来的，不是一次写完的。

---

搭好之后，使用方式是一样的：直接跟 AI 对话。丢一篇文章过去，它会自动 Ingest；提一个问题，它会在 Wiki 里检索回答。每次对话中产生的高质量分析，都会被保存回 wiki。

## 先跑起来

我自己的安装顺序，供参考：

1. Obsidian + 每日笔记，先写几天
2. Claudian（或 Claude Code）+ LLM Wiki，第一天就让 AI 开始干活
3. 如果有 Notion 数据要迁，另建一个仓库用 Importer 插件导入，再让 LLM 搬运有价值的内容进 Wiki
4. Templater + Calendar + Dataview，把日记和查询配好
5. 剩下的插件遇到痛点再装，用不上的卸掉

有问题可以在我博客评论区或 [GitHub](https://github.com/czj-dev/czj-dev.github.io) 留言。
