# Linux Runner 完整设置指南

本指南帮助您从零开始配置可用的 Linux Runner，支持您的自搭建 GitLab 18.0。

## 🎯 您的选择

### 🆚 Linux Runner 部署方案

| 方案 | 成本 | 难度 | 性能 | 推荐场景 |
|------|------|------|------|----------|
| **🖥️ 现有 Linux 服务器** | 免费 | ⭐⭐ | 最高 | 有闲置 Linux 机器 |
| **☁️ 云服务器** | 按需付费 | ⭐⭐ | 高 | 无本地机器，追求稳定 |
| **🐳 Docker 容器** | 免费 | ⭐⭐⭐ | 中等 | 资源共享，轻量化 |
| **💻 虚拟机** | 免费 | ⭐⭐⭐⭐ | 中等 | 学习测试，资源有限 |

---

## 🚀 方案一：现有 Linux 服务器 (推荐)

### 前置条件
- ✅ 一台 Linux 机器 (Ubuntu 18.04+, CentOS 7+, Debian 9+)
- ✅ 可以访问您的 GitLab 服务器
- ✅ 有 sudo 权限

### 快速安装脚本

```bash
#!/bin/bash
# GitLab Runner 一键安装脚本

echo "🚀 开始安装 GitLab Runner..."

# 检测系统类型
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu 系统
    echo "📋 检测到 Debian/Ubuntu 系统"
    
    # 添加 GitLab 官方仓库
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
    
    # 安装 GitLab Runner
    sudo apt-get install gitlab-runner
    
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL 系统
    echo "📋 检测到 CentOS/RHEL 系统"
    
    # 添加 GitLab 官方仓库
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
    
    # 安装 GitLab Runner
    sudo yum install gitlab-runner
else
    echo "❌ 不支持的系统类型"
    exit 1
fi

# 检查安装是否成功
if command -v gitlab-runner &> /dev/null; then
    echo "✅ GitLab Runner 安装成功"
    gitlab-runner --version
else
    echo "❌ GitLab Runner 安装失败"
    exit 1
fi

echo "🎉 安装完成！下一步：注册 Runner"
```

### 手动安装步骤

#### Ubuntu/Debian 系统
```bash
# 1. 下载并添加 GPG 密钥
curl -L "https://packages.gitlab.com/gpg.key" | sudo apt-key add -

# 2. 添加仓库
echo "deb https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/runner_gitlab-runner.list

# 3. 更新包列表并安装
sudo apt-get update
sudo apt-get install gitlab-runner

# 4. 安装 Docker (用于 Docker 交叉编译)
sudo apt-get install docker.io
sudo systemctl start docker
sudo systemctl enable docker

# 5. 将 gitlab-runner 用户添加到 docker 组
sudo usermod -aG docker gitlab-runner
```

#### CentOS/RHEL 系统
```bash
# 1. 添加仓库
sudo tee /etc/yum.repos.d/runner_gitlab-runner.repo <<EOF
[runner_gitlab-runner]
name=runner_gitlab-runner
baseurl=https://packages.gitlab.com/runner/gitlab-runner/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=1
enabled=1
gpgkey=https://packages.gitlab.com/gpg.key
EOF

# 2. 安装 GitLab Runner
sudo yum install gitlab-runner

# 3. 安装 Docker
sudo yum install docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker gitlab-runner
```

### 注册 Linux Runner

#### 1. 获取注册信息
在您的 GitLab 项目中：
1. 访问：`Settings → CI/CD → Runners`
2. 展开 "Project runners" 部分
3. 复制 **URL** 和 **registration token**

#### 2. 注册 Runner (Shell 执行器)
```bash
# 基础注册命令
sudo gitlab-runner register \
  --url "http://您的GitLab地址" \
  --registration-token "您的注册令牌" \
  --name "linux-shell-runner" \
  --executor "shell" \
  --tag-list "linux,shell" \
  --description "Linux Shell执行器"
```

#### 3. 注册 Runner (Docker 执行器) 
```bash
# Docker 执行器注册
sudo gitlab-runner register \
  --url "http://您的GitLab地址" \
  --registration-token "您的注册令牌" \
  --name "linux-docker-runner" \
  --executor "docker" \
  --docker-image "ubuntu:20.04" \
  --tag-list "linux,docker" \
  --description "Linux Docker执行器"
```

#### 4. 验证注册
```bash
# 检查 Runner 状态
sudo gitlab-runner list

# 查看 Runner 服务状态
sudo systemctl status gitlab-runner
```

---

## ☁️ 方案二：云服务器

### 推荐云服务商

#### 腾讯云轻量应用服务器
```bash
# 最低配置建议
CPU: 2核
内存: 2GB
存储: 40GB
系统: Ubuntu 20.04
月费用: 约 24 元/月
```

#### 阿里云 ECS
```bash
# 最低配置建议  
实例规格: t5-c1m2.large
CPU: 2vCPU
内存: 4GB
存储: 40GB云盘
系统: Ubuntu 20.04
月费用: 约 30 元/月
```

#### 华为云 ECS
```bash
# 最低配置建议
规格: s6.large.2
CPU: 2vCPU  
内存: 4GB
存储: 40GB SSD
系统: Ubuntu 20.04
月费用: 约 25 元/月
```

### 云服务器快速配置脚本

```bash
#!/bin/bash
# 云服务器 GitLab Runner 配置脚本

echo "🌐 配置云服务器 GitLab Runner..."

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y curl wget git build-essential

# 安装 GitLab Runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# 安装 Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker gitlab-runner

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 重启 GitLab Runner 服务
sudo systemctl restart gitlab-runner

echo "✅ 云服务器配置完成！"
echo "📝 下一步：使用注册命令注册 Runner"
```

---

## 🐳 方案三：Docker 容器 Runner

### 使用 Docker 运行 GitLab Runner

#### 1. 拉取 GitLab Runner 镜像
```bash
docker pull gitlab/gitlab-runner:latest
```

#### 2. 创建配置目录
```bash
sudo mkdir -p /srv/gitlab-runner/config
```

#### 3. 运行 GitLab Runner 容器
```bash
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

#### 4. 注册 Runner
```bash
# 进入容器并注册
docker exec -it gitlab-runner gitlab-runner register \
  --url "http://您的GitLab地址" \
  --registration-token "您的注册令牌" \
  --name "docker-runner" \
  --executor "docker" \
  --docker-image "ubuntu:20.04" \
  --tag-list "linux,docker" \
  --description "Docker容器Runner"
```

### Docker Compose 部署 (推荐)

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    volumes:
      - ./config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_TLS_CERTDIR=""
```

启动服务：
```bash
# 启动 Runner
docker-compose up -d

# 注册 Runner
docker-compose exec gitlab-runner gitlab-runner register \
  --url "http://您的GitLab地址" \
  --registration-token "您的注册令牌" \
  --name "compose-runner" \
  --executor "docker" \
  --docker-image "ubuntu:20.04" \
  --tag-list "linux,docker"
```

---

## 💻 方案四：虚拟机部署

### VMware 虚拟机配置

#### 推荐配置
```
CPU: 2核
内存: 4GB  
硬盘: 40GB
网络: NAT 或桥接模式
系统: Ubuntu 20.04 Server
```

#### 网络配置
```bash
# 确保虚拟机可以访问您的 GitLab 服务器
# 测试网络连通性
ping 您的GitLab服务器IP

# 如果无法连接，检查：
# 1. 虚拟机网络设置
# 2. 防火墙配置  
# 3. GitLab 服务器网络设置
```

### VirtualBox 虚拟机配置

#### 1. 下载 Ubuntu Server
```
下载地址: https://ubuntu.com/download/server
版本推荐: Ubuntu 20.04 LTS Server
```

#### 2. 虚拟机设置
```
名称: gitlab-runner-vm
类型: Linux
版本: Ubuntu (64-bit)
内存: 4096 MB
硬盘: 40 GB (动态分配)
网络: 桥接网卡
```

#### 3. 安装后配置
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 SSH 服务 (方便远程管理)
sudo apt install openssh-server
sudo systemctl enable ssh

# 配置静态 IP (可选)
sudo nano /etc/netplan/00-installer-config.yaml
```

---

## 🔧 Runner 配置优化

### 1. 并发任务配置

编辑 `/etc/gitlab-runner/config.toml`：

```toml
concurrent = 4  # 同时运行的任务数

[[runners]]
  name = "linux-runner"
  url = "http://您的GitLab地址"
  token = "runner令牌"
  executor = "docker"
  
  [runners.docker]
    image = "ubuntu:20.04"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    
  [runners.cache]
    Type = "local"
    Path = "/cache"
```

### 2. 缓存配置
```toml
[[runners]]
  # ... 其他配置 ...
  
  [runners.cache]
    Type = "local"
    Path = "/opt/cache"
    Shared = true
    
  [runners.docker]
    # 挂载缓存目录
    volumes = ["/opt/cache:/cache:rw"]
```

### 3. 性能优化
```bash
# 1. 调整系统资源限制
echo "gitlab-runner soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "gitlab-runner hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# 2. 配置 Docker 缓存清理
sudo tee /etc/cron.daily/docker-cleanup <<EOF
#!/bin/bash
# 清理未使用的 Docker 镜像和容器
docker system prune -f
EOF

sudo chmod +x /etc/cron.daily/docker-cleanup

# 3. 重启服务
sudo systemctl restart gitlab-runner
```

---

## 🚨 常见问题解决

### Q1: Runner 注册后显示离线
**症状**: GitLab 界面显示 Runner 状态为灰色

**解决方案**:
```bash
# 1. 检查 Runner 服务状态
sudo systemctl status gitlab-runner

# 2. 检查网络连通性
curl -I http://您的GitLab地址

# 3. 查看 Runner 日志
sudo journalctl -u gitlab-runner -f

# 4. 重启 Runner 服务
sudo systemctl restart gitlab-runner
```

### Q2: Docker 权限问题
**症状**: Pipeline 失败，提示 Docker 权限错误

**解决方案**:
```bash
# 1. 将 gitlab-runner 添加到 docker 组
sudo usermod -aG docker gitlab-runner

# 2. 重启 Docker 和 Runner 服务
sudo systemctl restart docker
sudo systemctl restart gitlab-runner

# 3. 验证权限
sudo -u gitlab-runner docker ps
```

### Q3: 内存不足问题
**症状**: 构建过程中出现内存溢出

**解决方案**:
```bash
# 1. 检查系统内存
free -h

# 2. 配置 swap 文件 (如果内存小于 4GB)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 3. 限制并发任务数
# 编辑 /etc/gitlab-runner/config.toml
concurrent = 1  # 减少并发数
```

### Q4: 网络连接问题
**症状**: Runner 无法连接到 GitLab

**解决方案**:
```bash
# 1. 检查防火墙设置
sudo ufw status

# 2. 如果启用了防火墙，允许出站连接
sudo ufw allow out 80
sudo ufw allow out 443

# 3. 检查 DNS 解析
nslookup 您的GitLab域名

# 4. 测试连接
telnet 您的GitLab服务器IP 80
```

---

## 🎯 验证 Runner 工作

### 1. 创建测试 Pipeline

在项目根目录创建 `.gitlab-ci.yml`：

```yaml
test-runner:
  stage: test
  script:
    - echo "🎉 Linux Runner 工作正常！"
    - uname -a
    - whoami
    - pwd
    - docker --version || echo "Docker 未安装"
    - node --version || echo "Node.js 未安装"
  tags:
    - linux
```

### 2. 推送代码测试
```bash
git add .gitlab-ci.yml
git commit -m "测试 Linux Runner"
git push origin main
```

### 3. 查看结果
访问 GitLab 项目的 `CI/CD → Pipelines` 查看运行结果。

---

## 📊 成本分析

### 自建 vs 云服务对比

| 方案 | 初始成本 | 月运行成本 | 维护成本 | 总体推荐 |
|------|----------|------------|----------|----------|
| **现有服务器** | 0 元 | 电费约 50 元 | 低 | ⭐⭐⭐⭐⭐ |
| **云服务器** | 0 元 | 25-50 元 | 低 | ⭐⭐⭐⭐ |
| **Docker 容器** | 0 元 | 宿主机成本 | 中 | ⭐⭐⭐ |
| **虚拟机** | 0 元 | 宿主机成本 | 高 | ⭐⭐ |

---

## 📝 下一步建议

### 立即行动
1. **✅ 选择合适方案**: 根据您的情况选择部署方式
2. **🚀 快速部署**: 使用提供的脚本快速安装
3. **🧪 测试验证**: 运行测试 Pipeline 验证功能
4. **🔧 优化配置**: 根据使用情况调整性能设置

### 长期规划
1. **📊 监控使用**: 关注 Runner 的资源使用情况
2. **🔄 定期维护**: 更新系统和 Docker 镜像
3. **📈 扩展规划**: 根据需要增加更多 Runner

---

## 🆘 获取支持

如果遇到问题：
1. **查看日志**: `sudo journalctl -u gitlab-runner -f`
2. **检查配置**: `sudo gitlab-runner verify`
3. **重启服务**: `sudo systemctl restart gitlab-runner`
4. **官方文档**: https://docs.gitlab.com/runner/

---

**🎉 现在您可以拥有稳定可靠的 Linux Runner 了！**

选择最适合您的方案开始吧：
- 💰 **预算充足**: 云服务器，稳定可靠
- 🏠 **有现成设备**: 现有服务器，成本最低  
- 🚀 **快速开始**: Docker 容器，配置简单 