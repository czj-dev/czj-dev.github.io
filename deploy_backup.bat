@echo off
REM 部署脚本 - 将生成的public文件提交到master分支
REM Windows版本

echo 🚀 开始部署博客...

REM 检查是否有未提交的更改
for /f "tokens=*" %%i in ('git status --porcelain 2^>nul') do (
    if not "%%i"=="" (
        echo ⚠️  检测到未提交的更改，请先提交或暂存这些更改：
        git status --porcelain
        echo 💡 提示: 运行 'git add .' 和 'git commit -m "your message"' 后再执行部署
        pause
        exit /b 1
    )
)

REM 获取当前分支
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo 📂 当前分支: %CURRENT_BRANCH%

REM 生成静态文件
echo 🏗️  生成静态文件...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ 构建失败！
    pause
    exit /b 1
)

REM 检查public文件夹是否存在
if not exist "public" (
    echo ❌ public文件夹不存在，构建可能失败了！
    pause
    exit /b 1
)

echo 📦 构建完成

REM 进入public文件夹
cd public

REM 检查是否已经初始化git
if not exist ".git" (
    echo 🔧 初始化git仓库...
    git init
    git branch -m master
)

REM 检查是否添加了远程仓库
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔗 添加远程仓库...
    git remote add origin https://github.com/czj-dev/czj-dev.github.io.git
)

REM 获取最新的远程信息
echo 📥 获取远程仓库信息...
git fetch origin

REM 添加所有文件到暂存区
echo 📝 添加文件到暂存区...
git add .

REM 提交更改
echo 💾 提交更改...
for /f "tokens=*" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"') do set TIMESTAMP=%%i
set COMMIT_MESSAGE=📝 自动部署 - %TIMESTAMP%

git commit -m "%COMMIT_MESSAGE%

🤖 Generated with [Claude Code](https://claude.ai/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

REM 强制推送到master分支
echo 🚀 推送到master分支...
git push origin master --force

REM 返回上级目录
cd ..

echo ✅ 部署完成！
echo 🌐 你的博客将在几分钟后更新: https://czj-dev.github.io
echo ⏱️  GitHub Pages通常需要1-2分钟来更新
pause