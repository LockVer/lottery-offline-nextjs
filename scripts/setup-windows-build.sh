#!/bin/bash

# Windows 构建设置脚本
echo "🪟 GitLab Windows 自动构建设置"
echo "================================"

# 检查基础环境
if [ ! -d ".git" ]; then
    echo "❌ 错误: 请在 Git 项目根目录中运行此脚本"
    exit 1
fi

if [ ! -f "src-tauri/Cargo.toml" ]; then
    echo "❌ 错误: 这不是一个 Tauri 项目"
    exit 1
fi

echo ""
echo "🎯 这个脚本将帮助您设置专门的 Windows 构建"
echo ""

# 显示设置选项
echo "请选择操作："
echo "1) 🔧 配置 Windows 构建 (需要 Windows 机器)"
echo "2) 🐳 配置 Docker 交叉编译 (仅需 Linux 机器) [推荐]"
echo "3) 📋 显示 Runner 设置指令"
echo "4) 🔍 检查当前配置状态"
echo "5) 📖 查看完整指南"

read -p "请输入选项 (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🔧 配置 Windows 专用构建..."
        
        # 备份现有配置
        if [ -f ".gitlab-ci.yml" ]; then
            mv .gitlab-ci.yml .gitlab-ci.yml.backup.$(date +%Y%m%d_%H%M%S)
            echo "✅ 已备份现有配置"
        fi
        
        # 使用 Windows 专用配置
        cp .gitlab-ci-windows.yml .gitlab-ci.yml
        echo "✅ 已配置 Windows 专用构建"
        
        echo ""
        echo "📋 配置特点:"
        echo "   ✅ 仅构建 Windows 版本 (.msi, .exe)"
        echo "   ✅ 自动安装 Node.js 和 Rust"
        echo "   ✅ 支持手动触发构建"
        echo "   ✅ 自动创建 GitLab Release"
        
        echo ""
        echo "🎯 下一步操作:"
        echo "1. 设置 Windows Runner (选择选项 3 查看详细指令)"
        echo "2. 推送配置: git add . && git commit -m 'Windows构建配置' && git push"
        echo "3. 在 GitLab 中监控构建: CI/CD → Pipelines"
        ;;
        
    2)
        echo ""
        echo "🐳 配置 Docker 交叉编译 (推荐方案)..."
        
        # 备份现有配置
        if [ -f ".gitlab-ci.yml" ]; then
            mv .gitlab-ci.yml .gitlab-ci.yml.backup.$(date +%Y%m%d_%H%M%S)
            echo "✅ 已备份现有配置"
        fi
        
        # 使用 Docker 交叉编译配置
        cp .gitlab-ci-docker-windows.yml .gitlab-ci.yml
        echo "✅ 已配置 Docker 交叉编译"
        
        echo ""
        echo "📋 Docker 方案特点:"
        echo "   ✅ 仅需要 Linux Runner (标签: linux)"
        echo "   ✅ 使用 Docker 容器交叉编译"
        echo "   ✅ 无需 Windows 机器"
        echo "   ✅ 自动配置编译环境"
        echo "   ✅ 支持多种编译方案"
        
        echo ""
        echo "🎯 下一步操作:"
        echo "1. 确保有 Linux Runner (支持 Docker)"
        echo "2. 推送配置: git add . && git commit -m 'Docker交叉编译配置' && git push"
        echo "3. 在 GitLab 中监控构建: CI/CD → Pipelines"
        
        echo ""
        echo "⚠️  注意事项:"
        echo "- 交叉编译的程序可能有兼容性差异"
        echo "- 建议在实际 Windows 环境中测试"
        echo "- 如需最高兼容性，仍推荐使用 Windows 机器编译"
        ;;
         
    3)
        echo ""
        echo "🏗️ Windows Runner 设置指令"
        echo ""
        
        echo "📝 需要在您的 Windows 机器上执行以下步骤："
        echo ""
        
        echo "第一步: 下载并安装 GitLab Runner"
        echo "在 Windows 上以管理员身份运行 PowerShell:"
        echo ""
        echo "# 创建目录并下载"
        echo "New-Item -Path \"C:\\GitLab-Runner\" -ItemType Directory -Force"
        echo "cd C:\\GitLab-Runner"
        echo "Invoke-WebRequest -Uri \"https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe\" -OutFile \"gitlab-runner.exe\""
        echo ""
        echo "# 安装服务"
        echo ".\\gitlab-runner.exe install"
        echo ".\\gitlab-runner.exe start"
        echo ""
        
        echo "第二步: 获取注册信息"
        echo "1. 在 GitLab 项目中访问: Settings → CI/CD → Runners"
        echo "2. 找到 'Project runners' 部分"
        echo "3. 复制 'registration token'"
        echo ""
        
        echo "第三步: 注册 Runner"
        echo "在 Windows PowerShell 中运行 (替换实际的 URL 和 Token):"
        echo ""
        echo ".\\gitlab-runner.exe register \\"
        echo "  --url \"http://您的GitLab地址\" \\"
        echo "  --registration-token \"您的注册令牌\" \\"
        echo "  --name \"windows-builder\" \\"
        echo "  --executor \"shell\" \\"
        echo "  --tag-list \"windows\" \\"
        echo "  --description \"Windows构建机器\""
        echo ""
        
        echo "第四步: 验证设置"
        echo "在 GitLab 项目的 Settings → CI/CD → Runners 中应该能看到:"
        echo "- 名称: windows-builder"
        echo "- 状态: 绿色 Available"
        echo "- 标签: windows"
        echo ""
        
        echo "💡 提示: 详细说明请查看 docs/gitlab-windows-build-guide.md"
        ;;
        
    4)
        echo ""
        echo "🔍 检查配置状态..."
        echo ""
        
        # 检查 CI 配置
        if [ -f ".gitlab-ci.yml" ]; then
            echo "✅ GitLab CI 配置文件存在"
            
            if grep -q "build-windows" .gitlab-ci.yml; then
                echo "✅ 已配置 Windows 构建"
                
                # 检查配置类型
                if grep -q "build:linux" .gitlab-ci.yml; then
                    echo "📦 配置类型: 跨平台构建"
                elif grep -q "docker:dind" .gitlab-ci.yml; then
                    echo "📦 配置类型: Docker 交叉编译"
                else
                    echo "📦 配置类型: Windows 专用构建"
                fi
            else
                echo "⚠️  未检测到 Windows 构建配置"
            fi
        else
            echo "❌ 未找到 GitLab CI 配置文件"
            echo "💡 运行选项 1 或 2 来创建配置"
        fi
        
        # 检查项目文件
        echo ""
        echo "项目文件检查:"
        
        required_files=(
            "package.json"
            "src-tauri/Cargo.toml"
            "src-tauri/tauri.conf.json"
        )
        
        for file in "${required_files[@]}"; do
            if [ -f "$file" ]; then
                echo "   ✅ $file"
            else
                echo "   ❌ $file (缺失)"
            fi
        done
        
        # 检查 Git 远程仓库
        echo ""
        echo "Git 仓库检查:"
        if git remote get-url origin | grep -i gitlab > /dev/null; then
            echo "   ✅ Git 远程仓库指向 GitLab"
            echo "   🔗 $(git remote get-url origin)"
        else
            echo "   ⚠️  Git 远程仓库未指向 GitLab"
            echo "   🔗 $(git remote get-url origin)"
        fi
        
        # 检查备份文件
        echo ""
        echo "备份文件:"
        backup_files=$(ls .gitlab-ci.yml.backup* 2>/dev/null | wc -l)
        if [ "$backup_files" -gt 0 ]; then
            echo "   📄 发现 $backup_files 个备份文件"
            ls -la .gitlab-ci.yml.backup* 2>/dev/null | sed 's/^/      /'
        else
            echo "   ℹ️  没有备份文件"
        fi
        
        echo ""
        echo "💡 配置检查完成！"
        ;;
        
    5)
        echo ""
        echo "📖 完整指南位置："
        echo ""
        echo "🎯 新手专用指南: docs/gitlab-windows-build-guide.md"
        echo "   - 完整的步骤说明"
        echo "   - 常见问题解决方案"
        echo "   - Runner 设置详解"
        echo ""
        echo "🔧 通用 GitLab 指南: docs/gitlab-cicd-guide.md"
        echo "   - 跨平台构建配置"
        echo "   - 高级配置选项"
        echo "   - 性能优化技巧"
        echo ""
        echo "📚 查看文件："
        if [ -f "docs/gitlab-windows-build-guide.md" ]; then
            echo "   ✅ Windows 构建指南存在"
        else
            echo "   ❌ Windows 构建指南缺失"
        fi
        
        if [ -f "docs/gitlab-cicd-guide.md" ]; then
            echo "   ✅ 通用 GitLab 指南存在"
        else
            echo "   ❌ 通用 GitLab 指南缺失"
        fi
        
        echo ""
        echo "💡 建议首先阅读 Windows 构建指南!"
        ;;
        
    *)
        echo "❌ 无效选项，请选择 1-5"
        exit 1
        ;;
esac

echo ""
echo "📚 相关资源:"
echo "   🎯 Windows 构建指南: docs/gitlab-windows-build-guide.md"
echo "   🔧 Runner 官方文档: https://docs.gitlab.com/runner/"
echo "   🚀 Tauri 构建文档: https://tauri.app/v1/guides/building/"
echo ""
echo "�� 设置完成！如有问题请查看详细指南。" 