# GitHub Actions 跨平台构建指南

本项目已配置 GitHub Actions 自动化工作流，支持跨平台编译 Tauri 应用程序，解决本地跨平台编译的复杂性问题。

## 🚀 工作流概览

### 1. 测试构建 (`test-build.yml`)
- **触发方式**: 推送到 `develop` 或 `test` 分支，或手动触发
- **用途**: 快速验证代码在各平台的编译情况
- **平台**: Ubuntu, Windows, macOS
- **产物保留**: 3天

### 2. 完整构建 (`build.yml`)
- **触发方式**: 推送到 `main/master` 分支，PR 合并，或发布版本
- **用途**: 完整的跨平台构建
- **平台**: macOS (Intel + Apple Silicon), Ubuntu, Windows
- **功能**: 自动发布和产物管理

### 3. 发布构建 (`release.yml`)
- **触发方式**: 推送版本标签 (`v*`) 或手动触发
- **用途**: 正式版本发布
- **平台**: 全平台支持
- **功能**: 自动创建 GitHub Release

## 📦 支持的平台

| 平台 | 架构 | 产物格式 | 说明 |
|------|------|----------|------|
| Windows | x64 | `.msi`, `.exe` | Windows 安装包 |
| macOS | Intel (x64) | `.dmg` | Intel Mac 版本 |
| macOS | Apple Silicon (ARM64) | `.dmg` | M1/M2 Mac 版本 |
| Linux | x64 | `.deb`, `.AppImage` | Ubuntu/Debian 包 |

## 🛠️ 使用方法

### 方法 1: 自动触发构建

1. **开发测试**: 推送代码到 `develop` 或 `test` 分支
   ```bash
   git checkout develop
   git add .
   git commit -m "测试跨平台构建"
   git push origin develop
   ```

2. **正式发布**: 创建版本标签
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### 方法 2: 手动触发构建

1. 访问 GitHub Actions 页面
2. 选择对应的工作流
3. 点击 "Run workflow" 按钮
4. 填写必要参数（如版本号）

## 📋 构建状态监控

### 查看构建进度
1. 访问项目的 **Actions** 标签页
2. 选择对应的工作流运行
3. 查看各平台的构建状态

### 下载构建产物
1. 在工作流运行页面找到 **Artifacts** 区域
2. 下载对应平台的构建产物
3. 解压后即可获得安装包

## 🔧 配置优化

### 加速构建的技巧

1. **依赖缓存**: 所有工作流都启用了 Rust 和 Node.js 缓存
2. **并行构建**: 多平台同时构建，节省时间
3. **增量编译**: 利用 Rust 增量编译特性

### 自定义构建

如需修改构建配置，编辑对应的工作流文件：
- `.github/workflows/test-build.yml` - 测试构建
- `.github/workflows/build.yml` - 完整构建  
- `.github/workflows/release.yml` - 发布构建

## 🐛 常见问题

### Q: 构建失败怎么办？
A: 
1. 检查 Actions 日志中的错误信息
2. 确保 `package.json` 中的脚本正确
3. 验证 Tauri 配置文件语法
4. 检查依赖版本兼容性

### Q: 如何添加新的目标平台？
A: 
1. 在工作流的 `matrix` 部分添加新平台
2. 配置对应的 `args` 和 `target`
3. 添加平台特定的依赖安装步骤

### Q: 构建产物找不到？
A: 
1. 检查 `src-tauri/tauri.conf.json` 中的 bundle 配置
2. 确认目标平台的产物格式
3. 查看构建日志中的产物路径

## 📊 构建时间参考

| 平台 | 预估时间 | 说明 |
|------|----------|------|
| Ubuntu | 5-8 分钟 | 最快 |
| Windows | 8-12 分钟 | 中等 |
| macOS | 10-15 分钟 | 最慢，但生成两个架构 |

## 🔒 安全注意事项

1. **密钥管理**: GitHub token 自动提供，无需额外配置
2. **权限设置**: 工作流已配置最小必要权限
3. **代码签名**: 正式发布时建议添加代码签名

## 📝 版本管理建议

### 语义化版本控制
使用 `v主版本.次版本.修订版本` 格式：
- `v1.0.0` - 首个正式版本
- `v1.1.0` - 新功能添加
- `v1.0.1` - 错误修复

### 发布流程
1. 更新版本号在 `src-tauri/tauri.conf.json`
2. 更新 `CHANGELOG.md`
3. 创建版本标签触发构建
4. 验证所有平台构建成功
5. 发布 GitHub Release

---

💡 **提示**: 使用 GitHub Actions 跨平台构建比本地交叉编译更加稳定可靠，推荐作为正式发布的标准流程。 