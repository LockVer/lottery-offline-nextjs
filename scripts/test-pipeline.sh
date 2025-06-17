#!/bin/bash

# 测试 GitLab CI/CD Pipeline 脚本
# 功能：快速推送代码并触发构建

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 测试 GitLab CI/CD Pipeline${NC}"
echo -e "${BLUE}=============================${NC}"
echo ""

# 检查 git 状态
echo -e "${YELLOW}📋 检查 Git 状态...${NC}"
git status

echo ""
echo -e "${YELLOW}🔨 准备提交并推送...${NC}"

# 添加所有文件
git add .

# 创建提交
COMMIT_MSG="测试 Linux Runner Docker 交叉编译 Windows 版本 - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || echo "没有新的更改需要提交"

# 推送到远程仓库
echo -e "${YELLOW}📤 推送到 GitLab...${NC}"

# 检查远程仓库名称
REMOTE_NAME=$(git remote | head -n 1)
echo "使用远程仓库: $REMOTE_NAME"

git push $REMOTE_NAME main

echo ""
echo -e "${GREEN}✅ 代码已推送！${NC}"
echo ""
echo -e "${YELLOW}📝 下一步：${NC}"
echo "1. 访问 GitLab 项目页面"
echo "2. 查看 CI/CD → Pipelines"
echo "3. 观察构建进度"
echo ""
echo -e "${YELLOW}🎯 预期构建作业：${NC}"
echo "• test-code (Node.js 前端测试)"
echo "• build-windows-docker (Docker 交叉编译)"
echo "• build-windows-simple (如果是 develop 分支)"
echo ""
echo -e "${YELLOW}📱 监控命令：${NC}"
echo "curl -s '$CI_API_V4_URL/projects/$CI_PROJECT_ID/pipelines?private_token=YOUR_TOKEN' | jq ." 