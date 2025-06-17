# GitLab Windows 自动构建完整指南

本指南专门针对**第一次使用 GitLab CI/CD** 且只需要构建 **Windows 版本**的用户。

## 🎯 您将获得什么

- ✅ 自动构建 Windows 安装包 (.msi) 或可执行文件 (.exe)
- ✅ 自动创建 GitLab Release
- ✅ 构建产物自动保存 30 天
- ✅ 支持多种构建方案

## 📋 构建方案选择

### 🆚 方案对比

| 方案 | 需要设备 | 优势 | 劣势 | 推荐指数 |
|------|----------|------|------|----------|
| **🐳 Docker 交叉编译** | 仅需 Linux 机器 | 无需 Windows 机器<br/>配置简单<br/>成本最低 | 兼容性需测试<br/>功能可能受限 | ⭐⭐⭐⭐⭐ |
| **🔧 Windows 物理机** | Windows + Linux | 兼容性最好<br/>功能完整<br/>支持 .msi 安装包 | 需要额外设备<br/>配置复杂 | ⭐⭐⭐⭐ |

### 🎯 如何选择

- **推荐新手或预算有限**: 选择 **Docker 交叉编译**
- **追求最佳兼容性**: 选择 **Windows 物理机**
- **快速验证**: 先用 Docker，有问题再考虑 Windows 机器

---

## 🚀 方案一：Docker 交叉编译 (推荐)

### 前置要求
- ✅ 自搭建的 GitLab 18.0 (您已有)
- ✅ 一台 Linux 机器作为 Runner (支持 Docker)
- ✅ Tauri 项目托管在 GitLab 上

### 设置步骤

#### 第一步：配置 Docker 交叉编译
在项目根目录运行：

```bash
# 运行设置向导
./scripts/setup-windows-build.sh

# 选择选项 2：Docker 交叉编译
# 或者手动配置：
cp .gitlab-ci-docker-windows.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "配置 Docker 交叉编译"
git push origin main
```

#### 第二步：确保 Linux Runner 支持 Docker
1. 访问：`Settings → CI/CD → Runners`
2. 确保有可用的 Linux Runner
3. Runner 需要支持 Docker (executor: docker)

#### 第三步：运行构建
- 推送代码后自动触发构建
- 或在 `CI/CD → Pipelines` 手动运行

### Docker 方案特点
- ✅ **三种编译策略**: 标准、高级、简化
- ✅ **自动环境配置**: 自动安装所有编译工具
- ✅ **仅生成 .exe 文件**: 适用于大多数场景
- ⚠️ **兼容性提醒**: 建议在实际 Windows 环境测试

---

## 🚀 方案二：Windows 物理机构建

### 前置要求
- ✅ 自搭建的 GitLab 18.0 (您已有)
- ✅ 至少一台 Windows 机器作为 Runner
- ✅ 一台 Linux 机器作为辅助 Runner (可选，用于快速测试)

### 完整设置步骤

#### 第一步：准备 Windows Runner 机器

##### 1.1 安装 GitLab Runner
在您的 Windows 机器上：

1. **下载 GitLab Runner**
   ```powershell
   # 以管理员身份运行 PowerShell
   # 创建目录
   New-Item -Path "C:\GitLab-Runner" -ItemType Directory -Force
   cd C:\GitLab-Runner
   
   # 下载 Runner
   Invoke-WebRequest -Uri "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe" -OutFile "gitlab-runner.exe"
   ```

2. **安装为 Windows 服务**
   ```powershell
   # 安装服务
   .\gitlab-runner.exe install
   
   # 启动服务
   .\gitlab-runner.exe start
   ```

##### 1.2 注册 Windows Runner

1. **获取注册信息**
   - 在您的 GitLab 项目中，访问：`Settings → CI/CD → Runners`
   - 找到 "Project runners" 部分
   - 复制 "registration token"

2. **注册 Runner**
   ```powershell
   # 运行注册命令 (替换您的实际信息)
   .\gitlab-runner.exe register `
     --url "http://您的GitLab地址" `
     --registration-token "您的注册令牌" `
     --name "windows-builder" `
     --executor "shell" `
     --tag-list "windows" `
     --description "Windows构建机器"
   ```

3. **验证注册成功**
   - 在 GitLab 项目的 `Settings → CI/CD → Runners` 中
   - 应该能看到新注册的 "windows-builder" Runner
   - 状态应该是绿色的 "Available"

#### 第二步：配置项目 CI/CD

##### 2.1 启用 Windows 构建配置
在您的项目根目录：

```bash
# 运行设置向导选择 Windows 构建
./scripts/setup-windows-build.sh

# 选择选项 1：Windows 构建
# 或者手动配置：
cp .gitlab-ci-windows.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "配置 Windows 自动构建"
git push origin main
```

##### 2.2 验证配置
- 推送后，访问 GitLab 项目的 `CI/CD → Pipelines`
- 应该能看到一个新的 Pipeline 开始运行
- 如果失败了，不要担心，我们会在下面处理

---

## ⚙️ GitLab 项目设置 (通用)

### 启用 CI/CD
1. 在项目中访问：`Settings → General → Visibility, project features, permissions`
2. 确保 "CI/CD" 是启用状态 ✅

### 配置变量 (可选)
1. 访问：`Settings → CI/CD → Variables`
2. 可以添加以下变量来自定义构建：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `RUST_LOG` | `info` | Rust 日志级别 |
| `NODE_OPTIONS` | `--max-old-space-size=4096` | Node.js 内存限制 |

### 保护分支 (推荐)
1. 访问：`Settings → Repository → Protected branches`
2. 保护 `main` 分支，确保只有通过 CI 的代码才能合并

---

## 🎮 运行和使用

### 手动触发构建
1. 访问：`CI/CD → Pipelines`
2. 点击 "Run pipeline" 按钮
3. 选择 `main` 分支
4. 点击 "Run pipeline"

### 监控构建过程
1. 点击正在运行的 Pipeline
2. 查看各个阶段的执行情况：
   - `test-code` - 快速验证 (Linux Runner)
   - `build-windows` - Windows 构建 (Windows Runner 或 Docker)

### 查看构建日志
- 点击具体的任务可以查看详细日志
- 如果出错，日志会显示具体的错误信息

### 获取构建产物

#### 下载构建产物
构建成功后：
1. 在 Pipeline 页面，找到 `build-windows` 任务
2. 点击右侧的 "📦" (Artifacts) 按钮
3. 下载构建产物压缩包
4. 解压后找到 `.exe` 文件 (或 `.msi` 文件，如果是 Windows 物理机构建)

#### 创建正式发布
要创建正式的 Release：
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0
```

这会触发 `create-release` 任务，自动创建 GitLab Release。

---

## 🔧 常见问题和解决方案

### Docker 交叉编译相关

#### Q1: Docker 构建失败
**症状**: 构建过程中 Docker 相关错误

**解决方案**:
1. 确保 GitLab Runner 支持 Docker：
   ```bash
   # 检查 Runner 配置
   sudo gitlab-runner list
   ```
2. 确保 Docker 服务正在运行：
   ```bash
   sudo systemctl status docker
   ```
3. 检查 Runner 用户是否在 docker 组：
   ```bash
   sudo usermod -aG docker gitlab-runner
   sudo systemctl restart gitlab-runner
   ```

#### Q2: 交叉编译的程序在 Windows 上无法运行
**症状**: 生成的 .exe 文件在 Windows 上出现错误

**解决方案**:
1. 尝试在不同版本的 Windows 上测试
2. 检查是否缺少必要的运行时库
3. 考虑切换到 Windows 物理机构建方案

### Windows 物理机相关

#### Q3: Runner 注册失败
**症状**: 执行注册命令时报错连接失败

**解决方案**:
1. 检查 GitLab URL 是否正确（包含 http:// 或 https://）
2. 确保 Windows 机器能访问 GitLab 服务器
3. 检查防火墙设置
4. 验证注册令牌是否正确

#### Q4: 构建失败 - 找不到 Runner
**症状**: Pipeline 显示 "This job is stuck because you don't have any active runners"

**解决方案**:
1. 检查 Runner 状态：
   ```powershell
   cd C:\GitLab-Runner
   .\gitlab-runner.exe status
   ```
2. 如果服务停止了：
   ```powershell
   .\gitlab-runner.exe start
   ```
3. 确保 Runner 有正确的标签 (`windows` 或 `linux`)

#### Q5: Node.js 或 Rust 安装失败
**症状**: 构建过程中提示找不到 node 或 rustc 命令

**解决方案**:
在 Windows Runner 机器上预安装工具：

1. **安装 Node.js**:
   - 访问 https://nodejs.org/
   - 下载并安装 LTS 版本

2. **安装 Rust**:
   - 访问 https://rustup.rs/
   - 下载并安装 rustup

3. **重启 GitLab Runner 服务**:
   ```powershell
   .\gitlab-runner.exe restart
   ```

### 通用问题

#### Q6: 构建成功但找不到产物
**症状**: 构建显示成功，但没有 Artifacts

**解决方案**:
1. 检查 `src-tauri/tauri.conf.json` 中的 bundle 配置
2. 对于 Windows 物理机，确保包含 Windows 构建目标：
   ```json
   {
     "tauri": {
       "bundle": {
         "targets": ["msi", "nsis"]
       }
     }
   }
   ```

#### Q7: 权限问题
**症状**: 构建过程中出现权限错误

**解决方案**:
1. 确保 GitLab Runner 服务有足够权限
2. 对于 Docker 方案，确保 Runner 用户在 docker 组中
3. 对于 Windows 方案，确保以管理员权限运行

---

## 📊 构建流程说明

### 自动触发构建的情况
1. **推送到 main 分支** - 触发完整构建
2. **推送到 develop 分支** - 触发完整构建  
3. **创建标签** - 触发构建 + 创建 Release
4. **创建 Merge Request** - 仅触发测试阶段

### 构建阶段详解

#### Docker 交叉编译方案
1. **test-code** - 前端构建验证
2. **build-windows-docker** - Docker 交叉编译主构建
3. **build-windows-advanced** - 高级交叉编译 (手动触发)
4. **create-release** - 创建 GitLab Release (标签触发)

#### Windows 物理机方案
1. **test-code** - 快速验证 (Linux Runner)
2. **build-windows** - Windows 完整构建 (Windows Runner)
3. **create-release** - 创建 GitLab Release (标签触发)

---

## 🎯 使用建议

### 开发流程
1. **日常开发**: 推送到 `develop` 分支进行测试
2. **准备发布**: 合并到 `main` 分支
3. **正式发布**: 创建版本标签

### 调试技巧
1. **使用手动构建**: Pipeline 中的手动任务可以单独触发
2. **查看详细日志**: 点击具体任务查看完整输出
3. **本地测试**: 使用 `scripts/test-build.sh` 在本地验证前端构建

### 性能优化
1. **Docker 方案**: 利用容器缓存，构建速度较快
2. **Windows 方案**: 预安装工具，使用构建缓存
3. **并行构建**: 如果有多台机器，可以注册多个 Runner

---

## 📝 下一步建议

### 初次使用
1. **✅ 选择合适方案**: Docker 交叉编译 or Windows 物理机
2. **🧪 测试构建**: 推送代码验证构建流程
3. **🔍 验证产物**: 在 Windows 环境中测试生成的程序
4. **🚀 正式发布**: 创建标签发布第一个版本

### 长期使用
1. **📈 性能优化**: 根据使用情况调整配置
2. **🔄 方案切换**: 根据需要在不同方案间切换
3. **📊 监控构建**: 关注构建时间和成功率

---

## 🆘 获取帮助

如果遇到问题：
1. 查看 GitLab 的 CI/CD 日志获得详细错误信息
2. 运行 `./scripts/setup-windows-build.sh` 检查配置状态
3. 参考本文档的常见问题部分
4. 查看 GitLab 官方文档：https://docs.gitlab.com/runner/

---

**恭喜！🎉** 现在您已经拥有了灵活的 Windows 自动构建系统！
- 💰 **预算有限**: 使用 Docker 交叉编译
- 🎯 **追求完美**: 使用 Windows 物理机
- �� **灵活切换**: 随时可以更换方案 