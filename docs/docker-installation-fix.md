# Docker 安装问题修复指南

当您遇到以下错误时：
```
containerd.io : Conflicts: containerd
                Conflicts: runc
E: Error, pkgProblemResolver::Resolve generated breaks
```

## 🚀 快速解决方案

### 方案一：使用修复脚本（推荐）
```bash
# 运行我们提供的修复脚本
chmod +x scripts/fix-docker-installation.sh
./scripts/fix-docker-installation.sh
```

### 方案二：手动命令修复
```bash
# 1. 停止所有 Docker 相关服务
sudo systemctl stop docker.service docker.socket containerd.service 2>/dev/null || true

# 2. 完全清理旧版本
sudo apt-get remove -y docker docker-engine docker.io containerd runc containerd.io

# 3. 清理残留
sudo apt-get autoremove -y
sudo apt-get autoclean

# 4. 修复包管理器
sudo apt-get install -f
sudo apt-get update

# 5. 安装官方 Docker
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 6. 启动并配置
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo usermod -aG docker gitlab-runner  # 如果有 gitlab-runner 用户
```

### 方案三：替代安装方法
如果官方方法仍然失败，可以使用 Snap：
```bash
# 使用 Snap 安装 Docker
sudo snap install docker
sudo adduser $USER docker
```

## 🧪 验证安装
```bash
# 检查版本
docker --version

# 测试功能
sudo docker run hello-world

# 检查服务状态
sudo systemctl status docker
```

## ⚠️ 注意事项
1. 安装完成后需要重新登录或运行 `newgrp docker`
2. 确保当前用户在 docker 组中
3. 如果是为 GitLab Runner 安装，确保 gitlab-runner 用户也在 docker 组中

## 🔧 故障排查
- **权限问题**: 确保用户在 docker 组中
- **服务未启动**: `sudo systemctl start docker`
- **端口冲突**: 检查是否有其他容器运行时在使用
- **存储空间**: 确保有足够的磁盘空间

## 📞 获取帮助
如果问题仍然存在：
1. 运行 `docker info` 查看详细信息
2. 查看日志：`sudo journalctl -u docker.service`
3. 检查系统兼容性和内核版本 