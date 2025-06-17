#!/bin/bash

# Linux Runner 设置向导脚本
# 功能：交互式帮助用户选择和配置 Linux Runner

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 图标定义
ROCKET="🚀"
CHECKMARK="✅"
WARNING="⚠️"
INFO="💡"
QUESTION="❓"
GEAR="⚙️"

echo -e "${CYAN}${ROCKET} Linux Runner 设置向导${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# 检查操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# 显示方案选择菜单
show_options() {
    echo -e "${YELLOW}${QUESTION} 请选择您的部署方案：${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 🖥️  现有 Linux 服务器 (推荐 - 免费，性能最高)"
    echo -e "${GREEN}2.${NC} ☁️  云服务器 (稳定可靠，月费 25-50元)"
    echo -e "${GREEN}3.${NC} 🐳 Docker 容器 (轻量化，配置简单)"
    echo -e "${GREEN}4.${NC} 💻 虚拟机 (学习测试，资源有限)"
    echo -e "${GREEN}5.${NC} 📋 仅显示配置信息 (我已有 Runner)"
    echo -e "${GREEN}6.${NC} ❌ 退出"
    echo ""
}

# 检查必要工具
check_dependencies() {
    local missing_tools=()
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${WARNING} 缺少必要工具：${missing_tools[*]}"
        echo -e "${INFO} 请先安装这些工具再继续"
        return 1
    fi
    
    return 0
}

# 获取 GitLab 信息
get_gitlab_info() {
    echo -e "${INFO} 请提供您的 GitLab 信息："
    echo ""
    
    read -p "GitLab 服务器地址 (例如: http://gitlab.yourdomain.com): " GITLAB_URL
    read -p "项目注册令牌 (Settings → CI/CD → Runners): " REGISTRATION_TOKEN
    read -p "Runner 名称 (例如: my-linux-runner): " RUNNER_NAME
    
    if [ -z "$GITLAB_URL" ] || [ -z "$REGISTRATION_TOKEN" ] || [ -z "$RUNNER_NAME" ]; then
        echo -e "${RED}错误：所有字段都是必填的${NC}"
        return 1
    fi
    
    echo -e "${CHECKMARK} GitLab 信息已收集"
    return 0
}

# 方案1：现有 Linux 服务器
setup_existing_server() {
    echo -e "${ROCKET} 配置现有 Linux 服务器..."
    echo ""
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        DISTRO="debian"
        echo -e "${INFO} 检测到 Debian/Ubuntu 系统"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
        echo -e "${INFO} 检测到 CentOS/RHEL 系统"
    else
        echo -e "${WARNING} 无法检测系统类型，请手动安装"
        return 1
    fi
    
    echo -e "${GEAR} 开始安装 GitLab Runner..."
    
    if [ "$DISTRO" = "debian" ]; then
        # Debian/Ubuntu 安装
        echo "添加 GitLab 仓库..."
        curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
        
        echo "安装 GitLab Runner..."
        sudo apt-get install gitlab-runner -y
        
        echo "安装 Docker..."
        sudo apt-get install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker gitlab-runner
        
    elif [ "$DISTRO" = "redhat" ]; then
        # CentOS/RHEL 安装
        echo "添加 GitLab 仓库..."
        curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
        
        echo "安装 GitLab Runner..."
        sudo yum install gitlab-runner -y
        
        echo "安装 Docker..."
        sudo yum install docker -y
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker gitlab-runner
    fi
    
    echo -e "${CHECKMARK} GitLab Runner 安装完成"
    
    # 注册 Runner
    if get_gitlab_info; then
        register_runner "docker"
    fi
}

# 方案2：云服务器指导
setup_cloud_server() {
    echo -e "${ROCKET} 云服务器部署指导..."
    echo ""
    
    echo -e "${INFO} 推荐云服务器配置："
    echo "• CPU: 2核"
    echo "• 内存: 4GB"
    echo "• 存储: 40GB"
    echo "• 系统: Ubuntu 20.04"
    echo "• 月费用: 25-50元"
    echo ""
    
    echo -e "${YELLOW}推荐服务商：${NC}"
    echo "1. 腾讯云轻量应用服务器 (~24元/月)"
    echo "2. 阿里云 ECS (~30元/月)"
    echo "3. 华为云 ECS (~25元/月)"
    echo ""
    
    read -p "您是否已经有云服务器？(y/n): " has_server
    
    if [[ $has_server =~ ^[Yy]$ ]]; then
        echo -e "${INFO} 请在您的云服务器上运行以下命令："
        echo ""
        cat << 'EOF'
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

# 重启服务
sudo systemctl restart gitlab-runner
EOF
        echo ""
        echo -e "${CHECKMARK} 安装完成后，回到这里继续配置"
        
        read -p "安装完成了吗？(y/n): " install_done
        if [[ $install_done =~ ^[Yy]$ ]]; then
            if get_gitlab_info; then
                register_runner "docker"
            fi
        fi
    else
        echo -e "${INFO} 请先购买云服务器，然后重新运行此脚本"
    fi
}

# 方案3：Docker 容器
setup_docker_container() {
    echo -e "${ROCKET} 配置 Docker 容器 Runner..."
    echo ""
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${WARNING} Docker 未安装，请先安装 Docker"
        echo "Ubuntu/Debian: sudo apt install docker.io"
        echo "CentOS: sudo yum install docker"
        return 1
    fi
    
    echo -e "${INFO} 拉取 GitLab Runner 镜像..."
    docker pull gitlab/gitlab-runner:latest
    
    echo -e "${INFO} 创建配置目录..."
    sudo mkdir -p /srv/gitlab-runner/config
    
    echo -e "${INFO} 启动 GitLab Runner 容器..."
    docker run -d --name gitlab-runner --restart always \
        -v /srv/gitlab-runner/config:/etc/gitlab-runner \
        -v /var/run/docker.sock:/var/run/docker.sock \
        gitlab/gitlab-runner:latest
    
    echo -e "${CHECKMARK} Docker 容器已启动"
    
    # 注册 Runner
    if get_gitlab_info; then
        register_docker_runner
    fi
}

# 方案4：虚拟机指导
setup_virtual_machine() {
    echo -e "${ROCKET} 虚拟机部署指导..."
    echo ""
    
    echo -e "${INFO} 推荐虚拟机配置："
    echo "• CPU: 2核"
    echo "• 内存: 4GB"
    echo "• 硬盘: 40GB"
    echo "• 网络: 桥接模式"
    echo "• 系统: Ubuntu 20.04 Server"
    echo ""
    
    echo -e "${YELLOW}支持的虚拟化软件：${NC}"
    echo "1. VMware Workstation/Fusion"
    echo "2. VirtualBox (免费)"
    echo "3. Parallels Desktop (macOS)"
    echo ""
    
    echo -e "${INFO} 下载地址："
    echo "Ubuntu Server: https://ubuntu.com/download/server"
    echo ""
    
    echo -e "${WARNING} 注意事项："
    echo "• 确保虚拟机可以访问您的 GitLab 服务器"
    echo "• 配置静态 IP 或端口转发"
    echo "• 安装 SSH 服务方便远程管理"
    echo ""
    
    read -p "虚拟机是否已配置完成？(y/n): " vm_ready
    
    if [[ $vm_ready =~ ^[Yy]$ ]]; then
        echo -e "${INFO} 请在虚拟机中运行方案1的安装命令"
    else
        echo -e "${INFO} 请先配置虚拟机，然后重新运行此脚本"
    fi
}

# 注册 Runner
register_runner() {
    local executor=$1
    
    echo -e "${GEAR} 注册 GitLab Runner..."
    
    sudo gitlab-runner register \
        --url "$GITLAB_URL" \
        --registration-token "$REGISTRATION_TOKEN" \
        --name "$RUNNER_NAME" \
        --executor "$executor" \
        --docker-image "ubuntu:20.04" \
        --tag-list "linux,$executor" \
        --description "Linux $executor Runner"
    
    if [ $? -eq 0 ]; then
        echo -e "${CHECKMARK} Runner 注册成功！"
        
        # 验证注册
        echo -e "${INFO} 验证 Runner 状态..."
        sudo gitlab-runner list
        
        echo ""
        echo -e "${CHECKMARK} 🎉 Linux Runner 配置完成！"
        echo -e "${INFO} 您现在可以在 GitLab 项目中看到这个 Runner"
        echo -e "${INFO} 访问：Settings → CI/CD → Runners"
    else
        echo -e "${RED}Runner 注册失败，请检查信息是否正确${NC}"
    fi
}

# 注册 Docker 容器 Runner
register_docker_runner() {
    echo -e "${GEAR} 注册 Docker 容器 Runner..."
    
    docker exec gitlab-runner gitlab-runner register \
        --url "$GITLAB_URL" \
        --registration-token "$REGISTRATION_TOKEN" \
        --name "$RUNNER_NAME" \
        --executor "docker" \
        --docker-image "ubuntu:20.04" \
        --tag-list "linux,docker" \
        --description "Docker Container Runner"
    
    if [ $? -eq 0 ]; then
        echo -e "${CHECKMARK} Docker Runner 注册成功！"
        
        # 验证注册
        echo -e "${INFO} 验证 Runner 状态..."
        docker exec gitlab-runner gitlab-runner list
        
        echo ""
        echo -e "${CHECKMARK} 🎉 Docker Runner 配置完成！"
    else
        echo -e "${RED}Docker Runner 注册失败${NC}"
    fi
}

# 显示配置信息
show_config_info() {
    echo -e "${INFO} 当前 GitLab Runner 配置信息："
    echo ""
    
    if command -v gitlab-runner &> /dev/null; then
        echo -e "${CHECKMARK} GitLab Runner 已安装"
        gitlab-runner --version
        echo ""
        
        echo "已注册的 Runners："
        sudo gitlab-runner list
        echo ""
        
        echo "服务状态："
        sudo systemctl status gitlab-runner --no-pager
    else
        echo -e "${WARNING} GitLab Runner 未安装"
    fi
    
    echo ""
    echo -e "${INFO} 配置文件位置："
    echo "• 主配置: /etc/gitlab-runner/config.toml"
    echo "• 日志: sudo journalctl -u gitlab-runner -f"
    echo ""
    
    echo -e "${INFO} 常用命令："
    echo "• 查看状态: sudo systemctl status gitlab-runner"
    echo "• 重启服务: sudo systemctl restart gitlab-runner"
    echo "• 查看日志: sudo journalctl -u gitlab-runner -f"
    echo "• 验证配置: sudo gitlab-runner verify"
}

# 创建测试 Pipeline
create_test_pipeline() {
    echo -e "${INFO} 创建测试 Pipeline..."
    
    cat > .gitlab-ci.yml << 'EOF'
# Linux Runner 测试 Pipeline
test-linux-runner:
  stage: test
  script:
    - echo "🎉 Linux Runner 工作正常！"
    - echo "系统信息:"
    - uname -a
    - echo "当前用户:"
    - whoami
    - echo "当前目录:"
    - pwd
    - echo "Docker 版本:"
    - docker --version || echo "Docker 未安装"
    - echo "Node.js 版本:"
    - node --version || echo "Node.js 未安装"
    - echo "Git 版本:"
    - git --version || echo "Git 未安装"
  tags:
    - linux
  only:
    - main
    - master
EOF
    
    echo -e "${CHECKMARK} 测试文件已创建：.gitlab-ci.yml"
    echo -e "${INFO} 推送代码后即可测试 Runner"
}

# 主菜单循环
main_menu() {
    while true; do
        show_options
        read -p "请选择 (1-6): " choice
        echo ""
        
        case $choice in
            1)
                if [ "$(detect_os)" = "linux" ]; then
                    setup_existing_server
                else
                    echo -e "${WARNING} 此选项仅适用于 Linux 系统"
                    echo -e "${INFO} 请在 Linux 服务器上运行此脚本"
                fi
                ;;
            2)
                setup_cloud_server
                ;;
            3)
                setup_docker_container
                ;;
            4)
                setup_virtual_machine
                ;;
            5)
                show_config_info
                ;;
            6)
                echo -e "${CHECKMARK} 感谢使用 Linux Runner 设置向导！"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1-6${NC}"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..." -r
        echo ""
    done
}

# 脚本主入口
main() {
    # 检查依赖
    if ! check_dependencies; then
        exit 1
    fi
    
    # 显示系统信息
    OS=$(detect_os)
    echo -e "${INFO} 检测到系统：$OS"
    echo ""
    
    # 启动主菜单
    main_menu
}

# 运行主函数
main "$@" 