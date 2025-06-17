# GitLab CI/CD 自动构建指南

自搭建的 GitLab 完全支持 CI/CD 自动构建！本项目提供了完整的 GitLab CI/CD 配置，支持跨平台自动构建 Tauri 应用程序。

## 🏗️ Runner 要求

### 完整跨平台构建 (`.gitlab-ci.yml`)
需要配置以下类型的 GitLab Runner：

| Runner 类型 | 标签 | 用途 | 必需性 |
|------------|------|------|-------|
| **Linux** | `linux` | Linux 构建 + 测试 | ✅ 必需 |
| **Windows** | `windows` | Windows 构建 | 🔵 可选 |
| **macOS** | `macos` | macOS 构建 | 🔵 可选 |

### 简化构建 (`.gitlab-ci-simple.yml`)
仅需要：
- **Linux Runner** (使用 Docker 执行器)

## 📁 配置文件选择

### 1. 完整跨平台构建
```bash
# 重命名配置文件以启用完整构建
mv .gitlab-ci.yml .gitlab-ci-full.yml
cp .gitlab-ci.yml.template .gitlab-ci.yml
```

**适用场景**: 有多种类型 Runner，需要 Windows/macOS/Linux 全平台构建

### 2. 简化构建 (推荐新手)
```bash
# 使用简化版配置
mv .gitlab-ci-simple.yml .gitlab-ci.yml
```

**适用场景**: 只有 Linux Runner，主要构建 Linux 版本

## 🚀 快速开始

### 步骤 1: 配置 GitLab Runner

#### Docker 执行器 (推荐)
```bash
# 安装 GitLab Runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# 注册 Runner
sudo gitlab-runner register \
  --url "你的GitLab地址" \
  --registration-token "项目Token" \
  --executor "docker" \
  --docker-image "ubuntu:20.04" \
  --description "docker-runner" \
  --tag-list "linux,docker"
```

#### Shell 执行器
```bash
# 注册 Shell Runner
sudo gitlab-runner register \
  --url "你的GitLab地址" \
  --registration-token "项目Token" \
  --executor "shell" \
  --description "shell-runner" \
  --tag-list "linux,shell"
```

### 步骤 2: 选择配置文件

根据您的 Runner 情况选择合适的配置：

```bash
# 方案 A: 只有 Linux Runner (推荐开始)
cp .gitlab-ci-simple.yml .gitlab-ci.yml

# 方案 B: 有多平台 Runner
# 保持 .gitlab-ci.yml 原样，但需要配置对应的 Runner
```

### 步骤 3: 推送代码触发构建

```bash
git add .
git commit -m "配置 GitLab CI/CD 自动构建"
git push origin main
```

## 📋 构建流程

### 完整构建流程

1. **测试阶段** (`test`)
   - 快速验证代码和前端构建
   - 在 MR 和主分支上自动触发

2. **构建阶段** (`build`)
   - `build:linux` - Linux 版本构建
   - `build:windows` - Windows 版本构建 (需要 Windows Runner)
   - `build:macos-intel` - macOS Intel 版本构建 (需要 macOS Runner)
   - `build:macos-silicon` - macOS Apple Silicon 版本构建

3. **发布阶段** (`release`)
   - 收集所有平台的构建产物
   - 创建 GitLab Release
   - 仅在创建标签时触发

### 简化构建流程

1. **测试阶段** - 前端构建验证
2. **构建阶段** - Linux 完整构建
3. **打包阶段** - 准备发布文件

## 🎯 使用方法

### 自动触发构建

#### 1. 开发构建
```bash
# 推送到主分支或开发分支
git push origin main
git push origin develop
```

#### 2. 正式发布
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

#### 3. 合并请求 (MR)
- 创建 MR 时自动运行测试
- 验证代码质量和构建状态

### 手动触发构建

1. 访问项目的 **CI/CD → Pipelines** 页面
2. 点击 **"Run Pipeline"** 按钮
3. 选择分支并运行

或者触发手动任务：
1. 进入具体的 Pipeline
2. 找到 `manual-build` 或 `test-build` 任务
3. 点击播放按钮手动执行

## 📦 构建产物

### 产物位置
- **任务产物**: `CI/CD → Jobs → [任务名] → Artifacts`
- **发布版本**: `Deployments → Releases`

### 产物类型

| 平台 | 格式 | 说明 |
|------|------|------|
| Linux | `.deb` | Debian/Ubuntu 安装包 |
| Linux | `.AppImage` | 通用 Linux 应用 |
| Windows | `.msi` | Windows 安装包 |
| Windows | `.exe` | Windows 可执行文件 |
| macOS | `.dmg` | macOS 磁盘镜像 |

## ⚙️ 高级配置

### 1. 添加环境变量

在 GitLab 项目中：
1. `Settings → CI/CD → Variables`
2. 添加构建需要的环境变量

常用变量：
```bash
RUST_LOG=debug          # Rust 日志级别
NODE_OPTIONS=--max-old-space-size=4096  # Node.js 内存限制
```

### 2. 配置缓存

GitLab CI 已配置缓存以加速构建：
- `node_modules/` - Node.js 依赖
- `target/` - Rust 编译缓存
- `~/.cargo/` - Cargo 缓存

### 3. 自定义 Runner 配置

#### Windows Runner 设置
```toml
# config.toml
[[runners]]
  name = "windows-runner"
  url = "你的GitLab地址"
  token = "token"
  executor = "shell"
  tags = ["windows"]
  [runners.custom_build_dir]
    enabled = true
```

#### macOS Runner 设置
```toml
# config.toml
[[runners]]
  name = "macos-runner"
  url = "你的GitLab地址"
  token = "token"
  executor = "shell"
  tags = ["macos"]
```

## 🔧 故障排查

### 常见问题

#### Q: Runner 无法连接？
```bash
# 检查 Runner 状态
sudo gitlab-runner status

# 重启 Runner
sudo gitlab-runner restart

# 检查日志
sudo gitlab-runner --debug run
```

#### Q: 构建失败？
1. 检查 Runner 是否有正确的标签
2. 验证依赖是否正确安装
3. 查看详细的构建日志

#### Q: 缓存不生效？
- 确保 Runner 有写入权限
- 检查缓存路径是否正确
- 可以在 GitLab 界面清除缓存

### 性能优化

#### 1. 使用本地 Docker Registry
```yaml
variables:
  DOCKER_REGISTRY: "你的GitLab地址:5050"
  
build:linux:
  image: $DOCKER_REGISTRY/ubuntu:20.04
```

#### 2. 并行构建
```yaml
build:linux:
  parallel: 2  # 并行运行 2 个实例
```

#### 3. 条件构建
```yaml
build:windows:
  only:
    changes:
      - "src-tauri/**/*"  # 仅在 Rust 代码更改时构建
```

## 🔒 安全配置

### 1. 保护分支
在 `Repository → Settings → Repository → Protected Branches`:
- 保护 `main` 分支
- 要求 CI 通过才能合并

### 2. Runner 权限
- 使用专用用户运行 Runner
- 限制 Runner 的系统权限
- 定期更新 Runner 软件

### 3. 敏感信息
- 使用 GitLab Variables 存储密钥
- 启用 `masked` 和 `protected` 选项
- 避免在代码中硬编码密钥

## 📊 监控和报告

### 构建统计
- 访问 `CI/CD → Analytics` 查看构建统计
- 监控构建时间和成功率
- 分析性能瓶颈

### 通知设置
1. `Settings → Integrations`
2. 配置邮件或聊天工具通知
3. 设置构建失败通知

---

## 💡 最佳实践

1. **从简化版开始**: 先使用 `.gitlab-ci-simple.yml` 验证基本功能
2. **逐步扩展**: 根据需要添加更多平台的 Runner
3. **监控资源**: 关注 Runner 的 CPU 和内存使用情况
4. **定期维护**: 更新 Runner 和清理旧的构建缓存
5. **文档记录**: 记录特定配置和问题解决方案

通过 GitLab CI/CD，您可以实现与 GitHub Actions 同样强大的自动构建功能，而且完全在自己控制的环境中运行！🚀 