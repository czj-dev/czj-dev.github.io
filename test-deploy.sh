#!/bin/bash

# 测试部署脚本 - 仅测试git操作部分
echo "🧪 测试部署脚本..."

# 检查public文件夹
if [ ! -d "public" ]; then
    echo "❌ public文件夹不存在！"
    echo "🏗️  正在构建..."
    npm run build
fi

# 进入public文件夹
echo "📂 进入public文件夹..."
cd public

# 显示文件数量
echo "📊 生成的文件统计:"
echo "总文件数: $(find . -type f | wc -l)"
echo "总大小: $(du -sh . | cut -f1)"

# 检查git状态
echo ""
echo "🔍 Git状态检查:"
if [ -d ".git" ]; then
    echo "✅ Git仓库已初始化"
    git status
else
    echo "🔧 需要初始化Git仓库"
    echo "如需实际部署，请运行: deploy.sh 或 deploy.bat"
fi

echo ""
echo "✅ 测试完成！"
echo "💡 提示: 使用 'deploy.sh' (Linux/Mac) 或 'deploy.bat' (Windows) 进行实际部署"