# 博客部署指南

本文档说明如何将生成的静态文件部署到GitHub Pages的master分支。

## 部署方式

### 方式1：使用批处理脚本（Windows推荐）

```bash
# 双击运行或在命令行执行
deploy.bat
```

或者使用npm命令：
```bash
npm run deploy:github
```

### 方式2：使用Shell脚本（Linux/Mac）

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 运行脚本
./deploy.sh
```

或者使用npm命令：
```bash
npm run deploy:manual
```

### 方式3：使用Hexo内置部署

```bash
npm run deploy
```

## 脚本功能

### deploy.bat / deploy.sh 功能特性：

1. **安全检查**：部署前检查是否有未提交的更改
2. **自动构建**：运行 `npm run build` 生成静态文件
3. **Git操作**：
   - 初始化public文件夹为git仓库
   - 添加远程仓库地址
   - 自动生成带时间戳的提交信息
   - 强制推送到master分支

4. **友好提示**：
   - 部署状态反馈
   - 完成后提供访问链接
   - 提示GitHub Pages更新时间

## 部署流程

1. **确保在source分支工作**
   ```bash
   git checkout source
   ```

2. **提交你的更改**
   ```bash
   git add .
   git commit -m "你的提交信息"
   ```

3. **运行部署脚本**
   ```bash
   # Windows
   deploy.bat

   # Linux/Mac
   ./deploy.sh
   ```

## 注意事项

- **分支管理**：确保在source分支进行开发，master分支由脚本自动管理
- **自动提交**：脚本会自动生成提交信息，包含时间戳
- **强制推送**：使用 `--force` 确保master分支与public文件夹同步
- **部署时间**：GitHub Pages通常需要1-2分钟来更新

## 故障排除

### 权限错误（Linux/Mac）
```bash
chmod +x deploy.sh
```

### Git认证问题
确保你有权限推送到目标仓库，或使用SSH密钥。

### 构建失败
检查Hexo配置和依赖是否正确安装：
```bash
npm install
hexo generate
```

### 端口占用
如果4000端口被占用，使用其他端口：
```bash
hexo server --port 4001
```