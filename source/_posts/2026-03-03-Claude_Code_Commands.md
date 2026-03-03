---
layout: post
title: Claude Code Commands 指南：打造你的专属 AI 工作流
subtitle: 工具介绍
date: 2026-03-03 21:00:00
author: Nutcracker
header_image: img/post-bg-claude-code.jpg
catalog: true
description: 深入了解 Claude Code Commands 命令系统，从基础配置到高级工具调用，掌握构建个性化 AI 编程工作流的完整指南。
keywords:
  - Claude Code
  - Commands
  - 斜杠命令
  - AI 编程
  - 工作流自动化
tags:
  - 开发工具
  - Claude Code
  - AI 助手
  - 技术教程
---

## 前言

Claude Code 的强大之处在于**可编程性**——通过配置文件、命令系统、工具调用，你可以定制属于自己的 AI 编程工作流。本文聚焦 **Commands**，这是 Claude Code 中能极大提升效率的核心功能。

> "工具不应该只是工具，而应该是你工作方式的延伸。"

## 📌 基本信息

| 属性   | 内容                                                      |
| ---- | ------------------------------------------------------- |
| 名称   | Claude Code Commands                                    |
| 官方文档 | https://docs.anthropic.com/en/docs/claude-code/commands |
| 存储位置 | `~/.claude/commands/`（用户级）或 `.claude/commands/`（项目级） |
| 作用范围 | 全局命令跨所有项目可用，项目级命令仅当前项目可用 |
| 本质   | Markdown 文件 + YAML Frontmatter                          |

## 🏗️ Claude Code 扩展体系

在深入 Commands 之前，先了解一下 Claude Code 的**五种核心扩展机制**：

| 机制 | 用途 | 触发方式 |
|------|------|----------|
| **Commands** | 手动触发的斜杠命令 | `/命令名` |
| **Skills** | 可复用的提示模板 | 自动识别或手动调用 |
| **Hooks** | 事件驱动的自动化脚本 | 工具调用前后、会话结束等 |
| **Subagents** | 专注特定任务的子代理 | 由主代理按需启动 |
| **MCP** | 连接外部服务的协议 | 通过 MCP 服务器调用 |

2025年10月，Anthropic 将这些机制统一为 **Commands → Skills → Agents** 协作架构，让它们可以无缝配合。本文重点介绍 Commands，其他机制将在后续文章中详解。

---

## ⚡ 核心特性

了解 Commands 是什么之后，你可能会问：它到底有什么特别之处？为什么不用普通的提示词就够了？Claude Code Commands 具有几个独特的能力，让它区别于普通的提示词：

### 1. 系统级预加载

Commands 在**对话开始前就已经被加载到系统配置中**，这意味着：
- 它们不需要 Claude 主动调用 `view` 工具来读取
- 可以在 frontmatter 中直接注册可用工具
- 拥有比 Skills 更高的优先级

### 2. 工具注册能力

这是 Commands 最强大的特性之一。你可以在命令文件的 frontmatter 中声明 `allowed-tools`，这样 Claude 就会真正拥有这些工具的调用权限：

```yaml
---
description: 代码审查工具
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
---
```

**注意**：这点与 Skills 完全不同。Skills 里的工具声明只是"建议"，而 Commands 里的声明是"授权"，它和 Skills 的其他差异点我们后续会单独说明。

### 3. 参数处理

Commands 支持 `$ARGUMENTS` 内置变量，可以捕获用户在命令后输入的所有内容：

```markdown
---
description: 问候用户
argument-hint: <姓名>
---
你好，$ARGUMENTS！很高兴见到你。
```

调用示例：
```
/hello X
# $ARGUMENTS = "X"
```

这三个特性让 Commands 成为一个强大的工具，但在实际使用中，我发现很多人容易将它与另一个概念混淆——**Skills**。理解两者的区别，是真正掌握 Claude Code 的关键一步。

## 🔄 Commands 与 Skills 的区别

这是我最初使用 Claude Code 时最容易混淆的地方，也是理解整个系统的关键：

| 特性 | SKILL.md | Commands |
|--------|-----------|----------|
| 本质 | 普通文本文件 | 系统级配置 |
| 读取时机 | Claude 主动调用才能读取 | 对话开始前就已加载 |
| 作用范围 | 仅作为"提示内容" | 直接影响运行环境 |
| 工具注册 | ❌ 不能 | ✅ 可以 |

**为什么 Commands 里的声明有效？**

```
用户发起对话
    ↓
平台/系统读取 Commands 配置
    ↓
真正地向 Claude 注册可用工具
    ↓
Claude 的工具列表里就有了这些工具
```

而 SKILL.md 里的声明，只是让 Claude "看到一段文字说要用某工具"，它只能用已有的工具去模拟或替代。

### 2025年10月架构更新

Anthropic 在 2025年10月统一了扩展机制，形成了 **Commands → Skills → Agents** 的协作架构：

```
用户输入
    ↓
Commands（手动触发 /xxx）
    ↓
Skills（提供专业知识和流程）
    ↓
Agents（执行具体任务）
```

这意味着 Commands 可以调用 Skills，Skills 可以启动 Agents，形成完整的自动化链路。

理解了 Commands 的本质和与 Skills 的区别后，让我们来详细看看如何配置一个 Command。

每个 Command 文件都是 **Markdown 文件**，文件**最开头**是 YAML 格式的配置区，用 `---` 符号包围——这就是 **Frontmatter**。

Frontmatter 定义了这个命令的元信息和行为约束，例如：
- 这个命令是做什么的（`description`）
- 接受什么参数（`argument-hint`）
- 可以使用哪些工具（`allowed-tools`）

它位于命令文件的**第一行**，在实际的命令内容之前。下面是一个完整的 Frontmatter 配置示例。

## 📝 Frontmatter 配置详解

### 完整配置示例

```yaml
---
# 官方支持的配置项

# 命令描述
description: 创建 git commit

# 参数提示
argument-hint: <提交消息类型> [--style=formal]

# 允许使用的工具
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep

# 指定使用的模型
model: claude-sonnet-4-6-20250929

# 禁用模型调用（用于纯文本替换）
disable-model-invocation: true
---
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|:-----:|------|
| `description` | string | 推荐 | 命令的一句话描述 |
| `argument-hint` | string | 否 | 输入/命令后显示的占位符 |
| `allowed-tools` | array | 否 | 限制命令可调用的工具 |
| `model` | string | 否 | 指定使用的模型 |
| `disable-model-invocation` | boolean | 否 | 禁用模型调用 |

配置好了 Frontmatter，接下来就是编写命令的主体内容——如何调用工具完成任务。Commands 支持多种工具调用方式，让我逐一介绍。

## 🔧 工具调用语法

### 内置工具调用

在 Commands 中，你不需要用编程语法来调用工具，而是用**自然语言描述**告诉 Claude 该做什么。Claude 会根据你的描述自动调用合适的工具。

```markdown
## 执行步骤

### 步骤1：读取配置文件
请使用 Read 工具读取项目根目录下的配置文件 `.claude/settings.json`，了解当前项目的配置情况。

### 步骤2：搜索TODO注释
请使用 Grep 工具在 `src/` 目录下搜索所有包含 "TODO" 或 "FIXME" 的注释，仅搜索 Python 文件（扩展名为 `.py`）。

### 步骤3：运行测试
请使用 Bash 工具执行测试命令 `npm run test`，查看测试结果并分析是否有失败用例。
```

这种方式让 Commands 更加灵活——你描述"做什么"，Claude 决定"怎么做"。

**常用工具与典型场景**：

| 工具名 | 功能 | 适用场景 |
|---------|------|---------|
| `Read` | 读取文件 | 分析代码、读取配置 |
| `Write` | 写入文件 | 创建文件、保存结果 |
| `Edit` | 编辑文件 | 修改现有代码 |
| `Bash` | 执行命令 | 运行脚本、Git操作 |
| `WebSearch` | 网络搜索 | 获取最新信息 |
| `Grep` | 按内容搜索 | 在代码中搜索关键词 |
| `Glob` | 按名称查找 | 批量查找特定类型的文件 |

### MCP 工具调用

MCP（Model Context Protocol）是 Claude Code 的扩展协议，让你可以调用外部工具。调用 MCP 工具时，使用 `mcp__<server-name>__<tool-name>` 的格式：

```
## 使用 MCP 工具

### 搜索最新信息

请使用 `mcp__web-search-prime__webSearchPrime` 工具进行网络搜索：

- `search_query` 参数：使用用户输入的 `$ARGUMENTS` 作为搜索关键词
- `search_recency_filter` 参数：设置为 `oneWeek`，只搜索最近一周的内容
- `max_results` 参数：设置为 10，返回前 10 条搜索结果

获取搜索结果后，请整理成易读的格式展示给用户。
```

注意：同样使用自然语言描述工具的用途和参数，而不是编程语法。

### 嵌套工具调用

Commands 甚至可以调用其他 Commands，实现多步骤工作流：

```
## 步骤一
调用 /Review 命令，对当前代码进行审查

## 步骤二
调用 /commit 命令，交互式拟定提交内容

## 步骤三
请使用 Bash 工具执行 `git push`，将提交推送到远程仓库
```

## 📄 完整实战示例：智能 Git 提交命令

为了让你更直观地理解 Commands 的全貌，下面是一个完整的 `/commit` 命令示例。这个命令可以自动分析当前的 git 变更，然后生成规范的提交信息并提交代码。

### 命令文件位置

你可以将此命令保存到 `~/.claude/commands/commit.md`，作为**用户级全局命令**使用。如果只想在当前项目中使用，可以保存到项目的 `.claude/commands/commit.md` 作为**项目级命令**。

```
---
description: 分析变更并创建规范的 git commit
argument-hint: [可选：简要说明提交目的]
allowed-tools:
  - Bash(git status: *)
  - Bash(git diff: *)
  - Bash(git log: *)
  - Bash(git add: *)
  - Bash(git commit: *)
  - Bash(git push: *)
  - Read
  - Grep
---

## 任务目标

创建一个符合规范的 git commit，遵循 Conventional Commits 格式：
- feat: 新功能
- fix: Bug 修复
- refactor: 重构
- docs: 文档更新
- test: 测试相关
- chore: 构建/工具相关

## 执行步骤

### 步骤1：收集变更信息

请依次执行以下操作：

1. 运行 `git status` 查看当前仓库状态，了解有哪些文件被修改、新增或删除
2. 运行 `git diff HEAD` 查看所有变更的具体内容（包括已暂存和未暂存的）
3. 运行 `git log --oneline -10` 查看最近的提交历史，了解项目的提交风格

### 步骤2：分析变更类型

根据步骤1收集到的信息，判断这次变更属于哪种类型：

- **feat**: 如果这次变更引入了新功能或用户可见的新能力
- **fix**: 如果这次变更修复了 bug 或错误行为
- **refactor**: 如果代码逻辑重写但没有功能变化
- **docs**: 如果只是文档或注释的更新
- **test**: 如果只是测试代码的修改
- **chore**: 如果是配置文件、构建脚本等非业务代码的变更

### 步骤3：生成提交信息

根据变更类型和用户提供的 `$ARGUMENTS`（如果有的话），生成提交信息。

**提交信息格式**：

<type>(<scope>): <subject>

<body>

<footer>

**示例**：
feat(auth): 添加 OAuth2 登录支持

实现了基于 OAuth2 PKCE 流程的用户登录功能，支持以下特性：
- 支持多种 OAuth 提供商（Google、GitHub、GitLab）
- 自动 token 刷新机制
- 登录状态的持久化存储

Closes #123
```

### 步骤4：确认并提交

1. 向用户展示拟定的提交信息，请用户确认
2. 如果用户同意，使用 `git add` 暂存所有相关文件
3. 使用 `git commit -m "<提交信息>"` 创建提交
4. 如果 `$ARGUMENTS` 中包含 `push` 或 `--push` 关键字，则执行 `git push`

## 注意事项

- 不要提交临时文件（如 .env、.log 等）
- 提交信息用中文撰写（如果 `$ARGUMENTS` 是中文）或英文（如果 `$ARGUMENTS` 是英文）
- 提交信息的 subject（标题）不超过 50 字符
- body（正文）详细说明变更原因和影响，而非"做了什么"

### 使用示例

在 Claude Code 会话中输入：

```
/commit 修复了用户登录时的 token 过期问题
```

Claude 会：
1. 查看 git 变更
2. 分析这是 fix 类型的提交
3. 生成规范的提交信息：`fix(auth): 修复 token 过期后的自动刷新逻辑`
4. 询问确认后执行提交

输入：

```
/commit 添加用户资料页 --push
```

Claude 会：
1. 分析变更类型为 `feat`
2. 生成提交信息并提交
3. 自动执行 `git push`

这个例子展示了 Commands 的几个核心能力：工具权限控制、多步骤流程、参数处理、自然语言交互。你可以把它当成一个"微型程序"，只是用 Markdown 编写而已。

随着你的命令越来越多，如何组织它们就成了一个问题。Commands 支持目录分组和优先级规则，让你可以有序地管理命令库。

## 📂 命令分组与优先级

### 命令分组

你可以在 `~/.claude/commands/` 下创建子目录来组织命令：

```
~/.claude/commands/
├── workflows/          # 多步骤工作流命令
│   ├── feature-development.md
│   └── smart-fix.md
└── tools/              # 单一用途工具命令
    ├── security-scan.md
    └── api-scaffold.md
```

调用时使用命名空间前缀：`/workflows:feature-development` 或 `/tools:security-scan`。

### 优先级规则

当同名命令存在于多个位置时，按以下优先级：

```
1. 项目级（最高）: .claude/commands/
2. 用户级: ~/.claude/commands/
3. 内置命令（最低）
```

> ⚠️ **重要**：核心系统命令（如 `/clear`、`/help`、`/compact`、`/doctor` 等）是受保护的，不能被自定义命令覆盖。

掌握了 Commands 的基本用法之后，如何写出高质量的命令？这里有一些经过实践验证的最佳实践，可以帮你少走弯路。

## 💡 最佳实践

### 1. 条件逻辑设计

虽然 Markdown 不支持编程逻辑，但通过精心设计的提示词可以实现条件分支：

```markdown
## 执行逻辑

根据 $ARGUMENTS 的内容判断执行路径：

**情况1：参数包含"深度"或"详细"**
→ 执行深度分析流程
→ 输出完整报告（3000字以上）

**情况2：参数包含"快速"或"简要"**
→ 执行快速分析
→ 输出简要报告（500字以内）

**情况3：其他情况（默认）**
→ 执行标准分析
→ 输出标准报告（1500字）
```

### 2. 从 .claude/ 到 Plugin 的演进路径

对于个人使用，先用 `.claude/commands/` 快速迭代；稳定后，打包成 Plugin 供团队共享：

```
实验阶段 → .claude/commands/
稳定阶段 → Plugin（可版本化、可分发）
```

### 3. 命令命名建议

- 使用动宾结构：`review-code`、`generate-docs`
- 避免 actionless 名词：`documentation`、`testing`
- 保持简洁：`test` 比 `run_tests` 更好

从零开始编写 Commands 到形成自己的命令库，是一个循序渐进的过程。最后，让我总结一下 Commands 的核心价值，并给你一些实践建议。

## 总结

Claude Code Commands 系统是一个被低估的强大功能。通过它，你可以：

1. **注册真正可用的工具**，而不是依赖 Claude 的"理解"
2. **构建多步骤工作流**，实现复杂任务的自动化
3. **组织个人知识**，形成可复用的命令库

如果你还在停留在"问个问题"的阶段，不妨从创建第一个自定义命令开始。比如写一个 `/review` 命令来自动审查你的代码，或者 `/commit` 命令来生成规范的提交信息。

这些小小的投入，会在日复一日的使用中产生巨大的回报。

---

## 参考资源

**官方文档**：
- [Claude Code 官方文档 - Commands](https://docs.anthropic.com/en/docs/claude-code/commands)
- [Claude Code 官方文档 - Tools Reference](https://www.vtrivedy.com/posts/claudecode-tools-reference)

**社区资源**：
- [claude-code-config 示例配置](https://github.com/jarrodwatts/claude-code-config)
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - Hackathon 冠军的完整配置

**相关文章**：
- 后续将推出 Skills、Hooks、MCP 等机制的深度解析
