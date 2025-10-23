#!/bin/bash

# 部署脚本 - 将生成的public文件提交到master分支
# 作者: Claude Code

echo "🚀 开始部署博客..."

# 检查是否有未提交的更改
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  检测到未提交的更改，请先提交或暂存这些更改："
    git status --porcelain
    echo "💡 提示: 运行 'git add .' 和 'git commit -m \"your message\"' 后再执行部署"
    exit 1
fi

# 确保在source分支（当前分支）
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📂 当前分支: $CURRENT_BRANCH"

# 生成静态文件
echo "🏗️  生成静态文件..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ 构建失败！"
    exit 1
fi

# 检查public文件夹是否存在
if [ ! -d "public" ]; then
    echo "❌ public文件夹不存在，构建可能失败了！"
    exit 1
fi

echo "📦 构建完成，public文件夹大小: $(du -sh public | cut -f1)"

# 进入public文件夹
cd public

# 初始化git仓库（如果还没初始化）
if [ ! -d ".git" ]; then
    echo "🔧 初始化git仓库..."
    git init
    git branch -m master
fi

# 添加远程仓库（如果还没添加）
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "🔗 添加远程仓库..."
    git remote add origin https://github.com/czj-dev/czj-dev.github.io.git
fi

# 获取最新的远程信息
echo "📥 获取远程仓库信息..."
git fetch origin

# 添加所有文件到暂存区
echo "📝 添加文件到暂存区..."
git add .

# 提交更改
echo "💾 提交更改..."
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
COMMIT_MESSAGE="📝 自动部署 - $TIMESTAMP

🤖 Generated with [Claude Code](https://claude.ai/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git commit -m "$COMMIT_MESSAGE"

# 强制推送到master分支
echo "🚀 推送到master分支..."
git push origin master --force

# 返回上级目录
cd ..

echo "✅ 部署完成！"
echo "🌐 你的博客将在几分钟后更新: https://czj-dev.github.io"
echo "⏱️  GitHub Pages通常需要1-2分钟来更新"