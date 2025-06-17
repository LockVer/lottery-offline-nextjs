#!/bin/bash

# Docker 安装修复脚本
# 解决 containerd.io 依赖冲突问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 图标定义
ROCKET="🚀"
CHECKMARK="✅"
WARNING="⚠️"
INFO="💡"
GEAR="⚙️"
TRASH="🗑️"

echo -e "${BLUE}${ROCKET} Docker 安装修复脚本${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""

# 检测系统类型
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo -e "${RED}无法检测系统类型${NC}"
        exit 1
    fi
    
    echo -e "${INFO} 系统：$OS $VER"
}

# 清理旧的 Docker 安装
cleanup_old_docker() {
    echo -e "${TRASH} 清理旧的 Docker 相关包..."
    
    # 停止 Docker 服务（如果正在运行）
    sudo systemctl stop docker.service docker.socket containerd.service 2>/dev/null || true
    
    # 移除冲突的包
    echo -e "${INFO} 移除冲突的包..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc containerd.io 2>/dev/null || true
    
    # 清理残留配置
    echo -e "${INFO} 清理残留配置..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    # 清理 apt 缓存
    sudo apt-get clean
    
    echo -e "${CHECKMARK} 旧版本清理完成"
}

# 修复包管理器
fix_package_manager() {
    echo -e "${GEAR} 修复包管理器..."
    
    # 修复损坏的包
    sudo apt-get install -f
    
    # 更新包列表
    sudo apt-get update
    
    # 升级系统包
    sudo apt-get upgrade -y
    
    echo -e "${CHECKMARK} 包管理器修复完成"
}

# 安装官方 Docker
install_official_docker() {
    echo -e "${ROCKET} 安装官方 Docker..."
    
    # 安装必要的依赖
    echo -e "${INFO} 安装依赖包..."
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common
    
    # 添加 Docker 官方 GPG 密钥
    echo -e "${INFO} 添加 Docker 官方 GPG 密钥..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 添加 Docker 官方仓库
    echo -e "${INFO} 添加 Docker 官方仓库..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新包列表
    sudo apt-get update
    
    # 安装 Docker Engine
    echo -e "${INFO} 安装 Docker Engine..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo -e "${CHECKMARK} Docker 安装完成"
}

# 安装简化版 Docker (如果官方版本失败)
install_simple_docker() {
    echo -e "${WARNING} 尝试安装简化版 Docker..."
    
    # 使用 snap 安装 Docker
    if command -v snap &> /dev/null; then
        echo -e "${INFO} 使用 snap 安装 Docker..."
        sudo snap install docker
        
        # 将用户添加到 docker 组
        sudo addgroup --system docker 2>/dev/null || true
        sudo adduser $USER docker 2>/dev/null || true
        
        echo -e "${CHECKMARK} Snap Docker 安装完成"
        return 0
    fi
    
    # 使用便携式 Docker
    echo -e "${INFO} 安装便携式 Docker..."
    
    # 下载 Docker 二进制文件
    DOCKER_VERSION="24.0.7"
    curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz
    
    # 解压并安装
    tar -xzf docker.tgz
    sudo cp docker/* /usr/local/bin/
    rm -rf docker docker.tgz
    
    # 创建 Docker 服务
    sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
    
    echo -e "${CHECKMARK} 便携式 Docker 安装完成"
}

# 配置 Docker
configure_docker() {
    echo -e "${GEAR} 配置 Docker..."
    
    # 启动并启用 Docker 服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到 docker 组
    sudo usermod -aG docker $USER
    
    # 将 gitlab-runner 用户添加到 docker 组（如果存在）
    if id "gitlab-runner" &>/dev/null; then
        sudo usermod -aG docker gitlab-runner
        echo -e "${INFO} 已将 gitlab-runner 添加到 docker 组"
    fi
    
    # 配置 Docker daemon
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    # 重启 Docker 服务以应用配置
    sudo systemctl restart docker
    
    echo -e "${CHECKMARK} Docker 配置完成"
}

# 验证 Docker 安装
verify_docker() {
    echo -e "${INFO} 验证 Docker 安装..."
    
    # 检查 Docker 版本
    if docker --version; then
        echo -e "${CHECKMARK} Docker 版本检查通过"
    else
        echo -e "${RED} Docker 版本检查失败${NC}"
        return 1
    fi
    
    # 检查 Docker 服务状态
    if sudo systemctl is-active --quiet docker; then
        echo -e "${CHECKMARK} Docker 服务运行正常"
    else
        echo -e "${RED} Docker 服务未运行${NC}"
        return 1
    fi
    
    # 运行测试容器
    echo -e "${INFO} 运行测试容器..."
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        echo -e "${CHECKMARK} Docker 功能测试通过"
    else
        echo -e "${WARNING} Docker 功能测试失败，但基础安装成功"
    fi
    
    echo ""
    echo -e "${CHECKMARK} ${GREEN}Docker 安装验证完成！${NC}"
    echo -e "${INFO} 请重新登录或运行 'newgrp docker' 以使用户组权限生效"
}

# 提供多种安装方案
show_install_options() {
    echo -e "${YELLOW}选择 Docker 安装方案：${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 🔧 完整修复（推荐）- 清理 + 官方安装"
    echo -e "${GREEN}2.${NC} 🚀 快速安装 - 仅安装官方 Docker"
    echo -e "${GREEN}3.${NC} 🛠️  替代方案 - Snap/便携式安装"
    echo -e "${GREEN}4.${NC} 🧹 仅清理 - 只清理不安装"
    echo -e "${GREEN}5.${NC} ❌ 退出"
    echo ""
}

# 主安装流程
main_install() {
    local option=$1
    
    case $option in
        1)
            echo -e "${ROCKET} 执行完整修复..."
            cleanup_old_docker
            fix_package_manager
            install_official_docker
            configure_docker
            verify_docker
            ;;
        2)
            echo -e "${ROCKET} 执行快速安装..."
            install_official_docker
            configure_docker
            verify_docker
            ;;
        3)
            echo -e "${ROCKET} 执行替代安装..."
            cleanup_old_docker
            install_simple_docker
            configure_docker
            verify_docker
            ;;
        4)
            echo -e "${TRASH} 执行清理..."
            cleanup_old_docker
            fix_package_manager
            echo -e "${CHECKMARK} 清理完成，可以手动安装 Docker"
            ;;
        5)
            echo -e "${CHECKMARK} 退出安装"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return 1
            ;;
    esac
}

# 错误处理
handle_error() {
    echo -e "${RED}安装过程中出现错误${NC}"
    echo -e "${WARNING} 可以尝试以下解决方案："
    echo "1. 运行选项3（替代方案）"
    echo "2. 手动清理后重试"
    echo "3. 检查网络连接"
    echo "4. 更新系统后重试"
}

# 主函数
main() {
    # 检测系统
    detect_system
    echo ""
    
    # 显示选项菜单
    while true; do
        show_install_options
        read -p "请选择 (1-5): " choice
        echo ""
        
        if main_install "$choice"; then
            break
        else
            handle_error
            echo ""
            read -p "按回车键继续尝试其他方案..." -r
            echo ""
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 Docker 安装脚本执行完成！${NC}"
    echo ""
    echo -e "${INFO} 下一步："
    echo "1. 重新登录或运行: newgrp docker"
    echo "2. 测试 Docker: docker run hello-world"
    echo "3. 继续配置 GitLab Runner"
}

# 检查是否以 root 权限运行
if [ "$EUID" -eq 0 ]; then
    echo -e "${WARNING} 请不要以 root 权限运行此脚本"
    echo -e "${INFO} 使用普通用户权限运行，脚本会在需要时请求 sudo"
    exit 1
fi

# 检查 sudo 权限
if ! sudo -n true 2>/dev/null; then
    echo -e "${INFO} 此脚本需要 sudo 权限，请输入密码"
    sudo true
fi

# 运行主函数
main "$@" 