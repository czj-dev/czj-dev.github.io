---
layout: post
title: Claude Code Commands 指南
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
summary: Claude Code Commands 指南全面介绍命令系统的核心特性，包括系统级预加载、工具注册能力、参数处理机制、Frontmatter 配置详解、工具调用语法、命令分组与优先级规则、最佳实践以及完整的智能 Git 提交命令实战示例。
---

## 前言

Claude Code 的强大之处在于**可编程性** —— 通过配置文件、命令系统、工具调用，你可以定制属于自己的 AI 编程工作流。本文聚焦于 Claude Code 的命令系统，也就是我们常说的 Commands，这是 Claude Code 中能极大提升效率的核心功能。

> "工具不应该只是工具，而应该是你工作方式的延伸。"

## 📌 基本信息

## Commands 简介

| 属性   | 内容                                                      |
| ---- | ------------------------------------------------------- |
| 名称   | Claude Code Commands                                    |
| 官方文档 | https://docs.anthropic.com/en/docs/claude-code/commands |
| 存储位置 | `~/.claude/commands/`（用户级）或 `.claude/commands/`（项目级）    |
| 作用范围 | 全局命令跨所有项目可用，项目级命令仅当前项目可用                                |
| 本质   | Markdown 文件 + YAML Frontmatter                          |

##  Claude Code 扩展体系

在深入 Commands 之前，先了解一下 Claude Code 的**五种核心扩展机制**：

| 机制 | 用途 | 触发方式 |
|------|------|----------|
| **Commands** | 手动触发的斜杠命令 | `/命令名` |
| **Skills** | 可复用的提示模板 | 自动识别或手动调用 |
| **Hooks** | 事件驱动的自动化脚本 | 工具调用前后、会话结束等 |
| **Subagents** | 专注特定任务的子代理 | 由主代理按需启动 |
| **MCP** | 连接外部服务的协议 | 通过 MCP 服务器调用 |

Anthropic 将这些机制统一为 **Commands → Skills → Agents** 的协作架构，让它们可以无缝配合。这意味着 Commands 可以调用 Skills，Skills 可以启动 Agents，形成完整的自动化链路。

#### 核心扩展机制说明

- **MCP (Model Context Protocol)**：连接 Claude Code 与外部服务（如自定义接口、第三方工具）的协议，让 Claude 能调用系统外的功能。

- **Subagents（子代理）**：专注处理特定任务的独立代理实例，由主代理按需启动，用于拆解复杂任务或并行执行独立工作。

- **Hooks（钩子）**：事件驱动的自动化脚本，在特定时机（如工具调用前后、会话结束时）自动执行，用于格式化代码、运行检查等。


```text
用户输入
    ↓
Commands（手动触发 /xxx）
    ↓
Skills（提供专业知识和流程）
    ↓
Agents（执行具体任务）
```

 我们也从协作架构的一开始的 Commands 来详细了解，其他机制将在后续文章中详解。

## 🚀 快速入门：10 分钟创建第一个命令

### 步骤 1：创建命令文件

```bash
mkdir -p ~/.claude/commands
cat > ~/.claude/commands/hello.md << 'EOF'
---
description: 向用户打招呼
argument-hint: <姓名>
---

你好，**$ARGUMENTS**！很高兴见到你。
EOF
```

### 步骤 2：使用命令

```bash
/hello 张三
```

### 步骤 3：进阶 - 带工具调用的命令

```bash
cat > ~/.claude/commands/time.md << 'EOF'
---
description: 显示当前时间
argument-hint: [时区]
allowed-tools:
  - Bash
---

使用 Bash 工具获取当前时间：
如果 $ARGUMENTS 为空，执行 `date`
否则执行 `TZ=$ARGUMENTS date`
EOF
```

使用示例：
```bash
/time                    # 本地时间
/time Asia/Shanghai      # 北京时间
```

## 🔄 Commands 与 Skills 的区别

有很多人发现 Skills 最简化的结构可能只有一个 Skills.md 与 commands.md 基本没有差别，这里我们也简单的说明下两者的区别，这也是理解整个系统的关键：

| 特性 | SKILL.md | Commands |
|--------|-----------|----------|
| 本质 | 普通文本文件 | 系统级配置 |
| 读取时机 | Claude 主动调用才能读取 | 对话开始前就已加载 |
| 作用范围 | 仅作为"提示内容" | 直接影响运行环境 |
| 工具注册 | ❌ 不能 | ✅ 可以 |

**为什么 Commands 里的声明有效？**

```text
用户发起对话
    ↓
平台/系统读取 Commands 配置
    ↓
真正地向 Claude 注册可用工具
    ↓
Claude 的工具列表里就有了这些工具
```

而 SKILL.md 里的声明，只是让 Claude "看到一段文字说要用某工具"，它只能用已有的工具去模拟或替代。

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

## 📝 Frontmatter 配置详解

理解了 Commands 的本质和与 Skills 的区别后，让我们来详细看看如何配置一个 Command。

每个命令文件都是 Markdown 文件，文件最开头是 YAML 格式的配置区，用 `---` 符号包围——这就是 **Frontmatter（前置元数据配置区）**。

Frontmatter 定义了这个命令的元信息和行为约束，例如：
- 这个命令是做什么的（`description`）
- 接受什么参数（`argument-hint`）
- 可以使用哪些工具（`allowed-tools`）

它位于命令文件的**第一行**，在实际的命令内容之前。下面是一个完整的 Frontmatter 配置示例。

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
| **`description`** | string | 推荐 | 命令的一句话描述 |
| `argument-hint` | string | 否 | 输入/命令后显示的占位符 |
| **`allowed-tools`** | array | 否 | 限制命令可调用的工具 |
| **`model`** | string | 否 | 指定使用的模型 |
| `disable-model-invocation` | boolean | 否 | 禁用模型调用 |

### 配置项使用场景

#### `model` 字段使用场景

```yaml
---
description: 高精度代码审查
model: claude-sonnet-4-6-20250929
allowed-tools:
  - Read
  - Write
  - Edit
---
```

**场景**：复杂重构、架构设计、深度代码审查等需要高精度的任务，指定 Sonnet 模型确保输出质量。

```yaml
---
description: 简单文本替换
model: claude-haiku-4-5-20250929
disable-model-invocation: true
---
```

**场景**：轻量文本替换任务，指定 Haiku 轻量模型提升响应速度。

#### `disable-model-invocation` 字段使用场景

```yaml
---
description: 纯文本问候
disable-model-invocation: true
---
你好，$ARGUMENTS！
```

**场景**：纯文本替换场景（问候命令、模板填充），禁用模型调用可减少响应时间。

> **小结**：Frontmatter 配置定义了命令的行为边界，包括可用工具、模型选择、参数提示等，是编写高质量命令的基础。

配置好了 Frontmatter，接下来就是编写命令的主体内容——如何调用工具完成任务。Commands 支持多种工具调用方式，让我逐一介绍。

## 🔧 工具调用语法

### 内置工具调用

在 Commands 中，工具调用遵循标准语法格式。以下是直接的工具调用示例：

```markdown
## 执行步骤

### 步骤1：读取配置文件
使用 Read 工具读取配置文件：
- file_path: .claude/settings.json

### 步骤2：搜索TODO注释
使用 Grep 工具搜索代码中的 TODO/FIXME 注释：
- pattern: (TODO|FIXME)
- path: src/
- glob: *.py

### 步骤3：运行测试
使用 Bash 工具执行测试：
- command: npm run test
```

这种格式让工具调用更加清晰明确，便于 Claude 准确执行操作。

**常用工具与典型场景**：

| 工具名 | 功能 | 适用场景 |
|---------|------|---------|
| **`Read`** | 读取文件 | 分析代码、读取配置 |
| **`Write`** | 写入文件 | 创建文件、保存结果 |
| **`Edit`** | 编辑文件 | 修改现有代码 |
| **`Bash`** | 执行命令 | 运行脚本、Git操作 |
| `WebSearch` | 网络搜索 | 获取最新信息 |
| **`Grep`** | 按内容搜索 | 在代码中搜索关键词 |
| **`Glob`** | 按名称查找 | 批量查找特定类型的文件 |

### MCP 工具调用

MCP（Model Context Protocol）是 Claude Code 的扩展协议，让你可以调用外部工具。调用 MCP 工具时，使用 `mcp__<server-name>__<tool-name>` 的格式：

```markdown
---
description: 使用 MCP 搜索网络并整理结果
argument-hint: <搜索关键词>
allowed-tools:
  - mcp__web-search-prime__webSearchPrime
---

使用 webSearchPrime 搜索 `$ARGUMENTS`（限定最近一周内容，medium 详细度），
将结果整理为易读格式展示，包含标题、链接和摘要。
```

### 嵌套工具调用

Commands 可以调用其他 Commands，实现多步骤工作流：

```markdown
## 步骤一：代码审查
调用 /review 命令，对当前代码进行审查

## 步骤二：创建提交
调用 /commit 命令，交互式拟定提交内容

## 步骤三：推送到远程仓库
使用 Bash 工具执行推送：
- command: git push
```

> **小结**：通过标准语法格式描述工具调用，Claude 能够准确理解和执行。

## 📂 命令分组与优先级

### 命令分组

你可以在 `~/.claude/commands/` 下创建子目录来组织命令：

```text
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

```text
1. 项目级（最高）: .claude/commands/
2. 用户级: ~/.claude/commands/
3. 内置命令（最低）
```

> ⚠️ **重要**：核心系统命令（如 `/clear`、`/help`、`/compact`、`/doctor` 等）是受保护的，不能被自定义命令覆盖。

> **小结**：通过目录分组和优先级规则，有序管理命令库，避免命名冲突。

## 📄 完整实战示例：智能 Git 提交命令

为了让你更直观地理解 Commands 的全貌，下面是一个完整的 `/commit` 命令示例。这个命令可以自动分析当前的 git 变更，然后生成规范的提交信息并提交代码。

### 命令文件位置

你可以将此命令保存到 `~/.claude/commands/commit.md`，作为**用户级全局命令**使用。如果只想在当前项目中使用，可以保存到项目的 `.claude/commands/commit.md` 作为**项目级命令**。

---

description: 分析变更并创建规范的 git commit argument-hint: "[可选：简要说明提交目的，附加 --push 可在提交后推送]" allowed-tools:

- Bash(git *: *)
- Read
- Grep

---

## 目标

基于当前变更，生成并执行符合 **Conventional Commits** 规范的 git commit。

## 执行步骤

### 1. 收集变更信息

并行执行以下命令：

- `git status` — 查看文件变更状态
- `git diff HEAD` — 查看具体差异内容
- `git log --oneline -10` — 了解项目现有提交风格

### 2. 分析并生成提交信息

根据变更内容和 `$ARGUMENTS`（若有），确定提交类型和范围：

|类型|适用场景|
|---|---|
|`feat`|新功能、新能力|
|`fix`|Bug 修复|
|`refactor`|重构（无功能变化）|
|`docs`|文档 / 注释更新|
|`test`|测试代码变更|
|`chore`|配置、构建、工具等|

**格式**：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**约束**：

- `subject` 不超过 50 字符
- `body` 说明**为何**这样改，而非罗列改了什么
- 语言跟随 `$ARGUMENTS`：中文输入用中文，英文输入用英文，无输入默认中文
- 不提交敏感或临时文件（`.env`、`*.log`、`node_modules` 等）

**示例**：

```
feat(auth): 添加 OAuth2 登录支持

现有的账密登录无法满足企业 SSO 需求，引入 OAuth2 PKCE 流程以支持
第三方身份提供商，同时避免在客户端存储 client_secret。

支持提供商：Google、GitHub、GitLab
包含 token 自动刷新和登录状态持久化

Closes #123
```

### 3. 确认并提交

1. 向用户展示拟定的提交信息，**等待确认**
2. 确认后执行：
    
    ```bash
    git add -Agit commit -m "<subject>" -m "<body>"
    ```
    
3. 若 `$ARGUMENTS` 包含 `--push`，提交后执行 `git push`

## 使用示例

```bash
/commit
/commit 修复用户登录时 token 过期的问题
/commit fix login token expiry issue --push
```


Claude 会：
1. 查看 git 变更
2. 分析这是 fix 类型的提交
3. 生成规范的提交信息：`fix(auth): 修复 token 过期后的自动刷新逻辑`
4. 询问确认后执行提交

输入：

```bash
/commit 添加用户资料页 --push
```

Claude 会：
1. 分析变更类型为 `feat`
2. 生成提交信息并提交
3. 自动执行 `git push`

### 适用场景

这个命令适用于以下场景：
- 日常开发的代码提交
- 需要生成符合团队规范的提交信息
- 避免手动输入复杂的 git 命令
- 团队协作时保持提交风格一致

### 进阶使用

```bash
# 提交并推送
/commit 新功能开发 --push

# 简洁提交（跳过确认）
/commit fix: 修复登录bug

# 带上下文的提交
/commit 完成用户认证模块，包含OAuth和JWT支持
```

这个例子展示了 Commands 的几个核心能力：工具权限控制、多步骤流程、参数处理、自然语言交互。你可以把它当成一个"微型程序"，只是用 Markdown 编写而已。

### 命令分组

你可以在 `~/.claude/commands/` 下创建子目录来组织命令：

```text
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

```text
1. 项目级（最高）: .claude/commands/
2. 用户级: ~/.claude/commands/
3. 内置命令（最低）
```

> ⚠️ **重要**：核心系统命令（如 `/clear`、`/help`、`/compact`、`/doctor` 等）是受保护的，不能被自定义命令覆盖。

掌握了 Commands 的基本用法之后，如何写出高质量的命令？这里有一些经过实践验证的最佳实践，可以帮你少走弯路。

## ❓ 常见问题与排错

### 问题 1：自定义命令输入后无响应？

**排查清单**：
- 文件路径是否正确？用户级 `~/.claude/commands/`，项目级 `.claude/commands/`
- 文件扩展名是否为 `.md`？
- Frontmatter 格式是否正确（用 `---` 包围，缩进正确）？
- 文件是否已保存？

**快速检查**：
```bash
ls -la ~/.claude/commands/
cat ~/.claude/commands/your-command.md
```

---
### 问题 2：命令执行速度很慢？

**优化建议**：
| 问题 | 解决方案 |
|------|----------|
| 模型选择不当 | 简单任务用 Haiku，复杂任务用 Sonnet |
| 读取过多文件 | 使用 Glob 精确定位，避免全目录扫描 |
| 未禁用模型调用 | 纯文本替换设置 `disable-model-invocation: true` |

## 💡 最佳实践

### 1. 权限最小化原则

只授予命令所需的最低权限。

```yaml
# ❌ 不安全：权限过大
---
description: 代码审查
allowed-tools:
  - Write  # 审查不需要写入
  - Bash   # 审查不需要执行任意命令
---

# ✅ 安全：权限最小化
---
description: 代码审查
allowed-tools:
  - Read   # 只需读取代码
  - Grep   # 只需搜索内容
---
```

**Git 命令精确控制**：
```yaml
allowed-tools:
  - Bash(git status: *)
  - Bash(git diff: *)
  - Bash(git commit: *)
```

---

### 2. 命令复用技巧

将通用流程抽离为基础命令，通过嵌套调用实现复杂工作流。

**不推荐**（单一大命令）：
```text
---
description: 完整开发流程
---

## 步骤1：代码审查
[详细流程...]

## 步骤2：运行测试
[详细流程...]

## 步骤3：提交代码
[详细流程...]
```

**推荐**（拆分复用）：
```markdown
# 基础命令：review.md
---
description: 代码审查
allowed-tools:
  - Read
  - Grep
---

# 组合命令：feature.md
---
description: 完整开发流程
allowed-tools:
  - Read
---

调用 /review 命令
调用 /test 命令
调用 /commit 命令
```

**优势**：每个命令可独立使用，修改更灵活。

---

### 3. 条件逻辑设计

虽然 Markdown 不支持编程逻辑，但通过精心设计的提示词可以实现条件分支：


## 执行逻辑
```markdown
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

---

### 4. 命令命名建议

- 使用动宾结构：`review-code`、`generate-docs`
- 避免 actionless 名词：`documentation`、`testing`
- 保持简洁：`test` 比 `run_tests` 更好
- 连字符分隔：`api-scaffold` 比 `apiScaffold` 更易读

| ❌ 不推荐 | ✅ 推荐 |
|----------|--------|
| `documentation` | `generate-docs` |
| `testing_runner` | `test` |

> **小结**：遵循权限最小化、命令复用、合理命名等原则，可以构建出既安全又高效的命令库。

从零开始编写 Commands 到形成自己的命令库，是一个循序渐进的过程。最后，让我总结一下 Commands 的核心价值，并给你一些实践建议。

## 总结

![alt][claude_code_commands_dense.png]


Claude Code Commands 系统是一个被低估的强大功能。通过它，你可以：

1. **注册真正可用的工具**，而不是依赖 Claude 的"理解"
2. **构建多步骤工作流**，实现复杂任务的自动化
3. **组织个人知识**，形成可复用的命令库

如果你还在停留在"问个问题"的阶段，不妨从创建第一个自定义命令开始。比如写一个 `/review` 命令来自动审查你的代码，或者 `/commit` 命令来生成规范的提交信息。

这些小小的投入，会在日复一日的使用中产生巨大的回报。

---

## 参考资源

**官方文档**：
- [Claude Code Commands](https://docs.anthropic.com/en/docs/claude-code/commands)
- [Tools Reference](https://www.vtrivedy.com/posts/claudecode-tools-reference)
- [Claude Code 官方社区](https://community.anthropic.com/)

**社区资源**：
- [claude-code-config](https://github.com/jarrodwatts/claude-code-config) - 50+ 常用命令集合
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) - Hackathon 冠军配置
