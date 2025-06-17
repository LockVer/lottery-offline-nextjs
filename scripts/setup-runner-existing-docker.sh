#!/bin/bash

# GitLab Runner 配置脚本（适用于已有 Docker 环境）
# 功能：在已有 Docker 的 Linux 系统上快速配置 GitLab Runner

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 图标定义
ROCKET="🚀"
CHECKMARK="✅"
WARNING="⚠️"
INFO="💡"
QUESTION="❓"
GEAR="⚙️"

echo -e "${CYAN}${ROCKET} GitLab Runner 快速配置（已有 Docker）${NC}"
echo -e "${CYAN}===========================================${NC}"
echo ""
echo -e "${INFO} ${YELLOW}适用于 GitLab 新版本（使用身份验证令牌）${NC}"
echo -e "${INFO} 如果您的 GitLab 显示 'Creating runners with runner registration tokens is disabled'"
echo -e "${INFO} 请按照脚本指导创建新的 Runner 并获取身份验证令牌"
echo ""

# 检查 Docker 状态
check_docker() {
    echo -e "${INFO} 检查 Docker 环境..."
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误：未找到 Docker 命令${NC}"
        exit 1
    fi
    
    echo -e "${CHECKMARK} Docker 已安装：$(docker --version)"
    
    # 检查 Docker 服务状态
    if ! sudo systemctl is-active --quiet docker; then
        echo -e "${WARNING} Docker 服务未运行，正在启动..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    echo -e "${CHECKMARK} Docker 服务运行正常"
    
    # 检查当前用户的 Docker 权限
    if groups $USER | grep -q docker; then
        echo -e "${CHECKMARK} 当前用户已在 docker 组中"
    else
        echo -e "${WARNING} 当前用户不在 docker 组中，正在添加..."
        sudo usermod -aG docker $USER
        echo -e "${INFO} 添加完成，请在配置完成后重新登录"
    fi
}

# 检查 GitLab Runner 状态
check_gitlab_runner() {
    echo -e "${INFO} 检查 GitLab Runner 状态..."
    
    if command -v gitlab-runner &> /dev/null; then
        echo -e "${CHECKMARK} GitLab Runner 已安装：$(gitlab-runner --version | head -n 1)"
        
        # 检查服务状态
        if sudo systemctl is-active --quiet gitlab-runner; then
            echo -e "${CHECKMARK} GitLab Runner 服务运行正常"
        else
            echo -e "${WARNING} GitLab Runner 服务未运行，正在启动..."
            sudo systemctl start gitlab-runner
            sudo systemctl enable gitlab-runner
        fi
        
        return 0
    else
        echo -e "${WARNING} GitLab Runner 未安装"
        return 1
    fi
}

# 安装 GitLab Runner
install_gitlab_runner() {
    echo -e "${ROCKET} 安装 GitLab Runner..."
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian 系统
        echo -e "${INFO} 检测到 Debian/Ubuntu 系统"
        
        # 添加 GitLab 官方仓库
        echo -e "${INFO} 添加 GitLab 官方仓库..."
        curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
        
        # 安装 GitLab Runner
        echo -e "${INFO} 安装 GitLab Runner..."
        sudo apt-get install gitlab-runner -y
        
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL 系统
        echo -e "${INFO} 检测到 CentOS/RHEL 系统"
        
        # 添加 GitLab 官方仓库
        echo -e "${INFO} 添加 GitLab 官方仓库..."
        curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
        
        # 安装 GitLab Runner
        echo -e "${INFO} 安装 GitLab Runner..."
        sudo yum install gitlab-runner -y
        
    else
        echo -e "${RED}不支持的系统类型${NC}"
        exit 1
    fi
    
    # 将 gitlab-runner 用户添加到 docker 组
    echo -e "${INFO} 配置 gitlab-runner 用户权限..."
    sudo usermod -aG docker gitlab-runner
    
    # 启动服务
    sudo systemctl start gitlab-runner
    sudo systemctl enable gitlab-runner
    
    echo -e "${CHECKMARK} GitLab Runner 安装完成"
}

# 获取 GitLab 信息
get_gitlab_info() {
    echo -e "${QUESTION} 请提供您的 GitLab 配置信息："
    echo ""
    
    # 检查 GitLab 版本并提供相应的指导
    echo -e "${INFO} ${YELLOW}GitLab 新版本注册方式：${NC}"
    echo "1. 访问 GitLab 项目：Settings → CI/CD → Runners"
    echo "2. 点击 'Create project runner' 按钮"
    echo "3. 填写 Runner 信息（标签、超时等）并创建"
    echo "4. 复制生成的身份验证令牌（glrt-xxx 格式）"
    echo ""
    echo -e "${WARNING} ${YELLOW}注意：${NC}使用身份验证令牌时，标签和其他配置在 GitLab 服务器端设置"
    echo ""
    echo -e "${INFO} ${YELLOW}示例信息：${NC}"
    echo "GitLab URL: http://gitlab.yourdomain.com"
    echo "身份验证令牌: glrt-xxxxxxxxxxxxxxxx"
    echo ""
    
    read -p "🌐 GitLab 服务器地址: " GITLAB_URL
    read -p "🔑 身份验证令牌 (glrt-开头): " AUTHENTICATION_TOKEN
    read -p "📝 Runner 名称 (例如: my-linux-runner): " RUNNER_NAME
    
    # 验证输入
    if [ -z "$GITLAB_URL" ] || [ -z "$AUTHENTICATION_TOKEN" ] || [ -z "$RUNNER_NAME" ]; then
        echo -e "${RED}错误：所有字段都是必填的${NC}"
        return 1
    fi
    
    # 检查令牌格式
    if [[ ! "$AUTHENTICATION_TOKEN" =~ ^glrt- ]]; then
        echo -e "${WARNING} 身份验证令牌应该以 'glrt-' 开头"
        read -p "是否继续？(y/n): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 测试连接
    echo -e "${INFO} 测试 GitLab 连接..."
    if curl -s --head "$GITLAB_URL" | head -n 1 | grep -q "200 OK\|302"; then
        echo -e "${CHECKMARK} GitLab 服务器连接正常"
    else
        echo -e "${WARNING} 无法连接到 GitLab 服务器，请检查 URL"
        read -p "是否继续？(y/n): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    echo -e "${CHECKMARK} GitLab 信息已收集"
    return 0
}

# 注册 GitLab Runner
register_runner() {
    echo -e "${GEAR} 注册 GitLab Runner..."
    
    # 选择执行器类型
    echo -e "${QUESTION} 选择执行器类型："
    echo "1. Docker (推荐 - 隔离性好，支持多种环境)"
    echo "2. Shell (直接在系统上运行)"
    echo ""
    
    read -p "请选择 (1-2): " executor_choice
    
    case $executor_choice in
        1)
            EXECUTOR="docker"
            DOCKER_IMAGE="ubuntu:20.04"
            ;;
        2)
            EXECUTOR="shell"
            DOCKER_IMAGE=""
            ;;
        *)
            echo -e "${WARNING} 无效选择，使用默认 Docker 执行器"
            EXECUTOR="docker"
            DOCKER_IMAGE="ubuntu:20.04"
            ;;
    esac
    
    # 执行注册 - 使用新的身份验证令牌方式
    echo -e "${INFO} 使用 $EXECUTOR 执行器注册 Runner..."
    
    # 使用新版本身份验证令牌方式 - 只保留必要参数
    if [ "$EXECUTOR" = "docker" ]; then
        sudo gitlab-runner register \
            --url "$GITLAB_URL" \
            --token "$AUTHENTICATION_TOKEN" \
            --name "$RUNNER_NAME - Docker $(hostname)" \
            --executor "$EXECUTOR" \
            --docker-image "$DOCKER_IMAGE" \
            --docker-privileged=false \
            --docker-disable-cache=false \
            --docker-volumes "/cache" \
            --non-interactive
    else
        sudo gitlab-runner register \
            --url "$GITLAB_URL" \
            --token "$AUTHENTICATION_TOKEN" \
            --name "$RUNNER_NAME - Shell $(hostname)" \
            --executor "$EXECUTOR" \
            --non-interactive
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${CHECKMARK} Runner 注册成功！"
        return 0
    else
        echo -e "${RED}Runner 注册失败${NC}"
        echo -e "${INFO} 可能的原因："
        echo "• 身份验证令牌无效或已过期"
        echo "• GitLab 服务器无法访问"
        echo "• Runner 名称已存在"
        echo "• 使用了不支持的配置参数"
        echo ""
        echo -e "${INFO} 解决方案："
        echo "• 确认身份验证令牌正确（glrt-开头）"
        echo "• 在 GitLab 服务器端设置标签和其他配置"
        echo "• 检查网络连接"
        return 1
    fi
}

# 验证配置
verify_setup() {
    echo -e "${INFO} 验证配置..."
    
    # 检查注册的 Runner
    echo -e "${INFO} 已注册的 Runners："
    sudo gitlab-runner list
    
    # 检查服务状态
    echo ""
    echo -e "${INFO} 服务状态："
    sudo systemctl status gitlab-runner --no-pager | head -10
    
    # 检查配置文件
    echo ""
    echo -e "${INFO} 配置文件路径：/etc/gitlab-runner/config.toml"
    
    # 提供测试建议
    echo ""
    echo -e "${CHECKMARK} ${GREEN}配置验证完成！${NC}"
}

# 创建测试 Pipeline
create_test_pipeline() {
    echo -e "${QUESTION} 是否创建测试 Pipeline？(y/n): "
    read -r create_test
    
    if [[ $create_test =~ ^[Yy]$ ]]; then
        echo -e "${INFO} 创建测试 Pipeline..."
        
        cat > .gitlab-ci.yml << 'EOF'
# Linux Runner 测试 Pipeline
stages:
  - test
  - build

# 基础系统测试
test-system:
  stage: test
  script:
    - echo "🎉 Linux Runner 工作正常！"
    - echo "=== 系统信息 ==="
    - uname -a
    - echo "=== 用户信息 ==="
    - whoami
    - id
    - echo "=== 工作目录 ==="
    - pwd
    - ls -la
    - echo "=== 环境变量 ==="
    - env | grep CI
  tags:
    - linux

# Docker 功能测试（仅当使用 Docker 执行器时）
test-docker:
  stage: test
  script:
    - echo "=== Docker 信息 ==="
    - docker --version
    - docker info
    - echo "=== 运行测试容器 ==="
    - docker run --rm hello-world
  tags:
    - linux
    - docker
  only:
    variables:
      - $CI_RUNNER_EXECUTOR == "docker"

# Node.js 构建测试
test-nodejs:
  stage: build
  image: node:18
  script:
    - echo "=== Node.js 环境测试 ==="
    - node --version
    - npm --version
    - echo "=== 安装依赖测试 ==="
    - npm install --version
  tags:
    - linux
    - docker
  only:
    variables:
      - $CI_RUNNER_EXECUTOR == "docker"
EOF
        
        echo -e "${CHECKMARK} 测试文件已创建：.gitlab-ci.yml"
        echo -e "${INFO} 推送代码到 GitLab 即可测试 Runner"
        echo ""
        echo -e "${INFO} 推送命令："
        echo "git add .gitlab-ci.yml"
        echo "git commit -m '添加 Runner 测试 Pipeline'"
        echo "git push origin main"
    fi
}

# 显示完成信息
show_completion_info() {
    echo ""
    echo -e "${GREEN}🎉 GitLab Runner 配置完成！${NC}"
    echo ""
    echo -e "${INFO} ${YELLOW}重要提醒：${NC}"
    echo "1. 如果当前用户被添加到了 docker 组，请重新登录以使权限生效"
    echo "2. 或者运行：newgrp docker"
    echo ""
    echo -e "${INFO} ${YELLOW}下一步操作：${NC}"
    echo "1. 访问 GitLab 项目：Settings → CI/CD → Runners"
    echo "2. 在 'Project runners' 部分确认看到您的 Runner"
    echo "3. 确认 Runner 状态为绿色（在线）"
    echo "4. 推送代码测试 Pipeline"
    echo ""
    echo -e "${INFO} ${YELLOW}常用命令：${NC}"
    echo "• 查看 Runner 状态：sudo gitlab-runner list"
    echo "• 查看服务状态：sudo systemctl status gitlab-runner"
    echo "• 查看日志：sudo journalctl -u gitlab-runner -f"
    echo "• 重启服务：sudo systemctl restart gitlab-runner"
    echo ""
    echo -e "${INFO} ${YELLOW}故障排查：${NC}"
    echo "• 如果 Runner 显示离线：检查网络连接和 GitLab URL"
    echo "• 如果构建失败：检查 Docker 权限和镜像拉取"
    echo "• 如果权限错误：确保用户在正确的组中"
}

# 主函数
main() {
    echo -e "${INFO} 开始配置 GitLab Runner..."
    echo ""
    
    # 1. 检查 Docker
    check_docker
    echo ""
    
    # 2. 检查并安装 GitLab Runner
    if ! check_gitlab_runner; then
        echo ""
        install_gitlab_runner
    fi
    echo ""
    
    # 3. 获取 GitLab 信息并注册
    if get_gitlab_info; then
        echo ""
        if register_runner; then
            echo ""
            verify_setup
            echo ""
            create_test_pipeline
            show_completion_info
        else
            echo -e "${RED}注册失败，请检查信息后重试${NC}"
            exit 1
        fi
    else
        echo -e "${RED}GitLab 信息收集失败${NC}"
        exit 1
    fi
}

# 检查运行权限
if [ "$EUID" -eq 0 ]; then
    echo -e "${INFO} 检测到以 root 权限运行，将直接执行命令"
else
    # 检查 sudo 权限
    if ! sudo -n true 2>/dev/null; then
        echo -e "${INFO} 此脚本需要 sudo 权限来安装和配置 GitLab Runner"
        sudo true
    fi
fi

# 运行主函数
main "$@" 