#!/bin/bash

# GitLab CI/CD 快速设置脚本
echo "🚀 GitLab CI/CD 自动构建设置向导"
echo "=================================="

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 错误: 请在 Git 项目根目录中运行此脚本"
    exit 1
fi

echo ""
echo "请选择配置类型:"
echo "1) 简化版 - 仅 Linux 构建 (推荐新手)"
echo "2) 完整版 - 跨平台构建 (需要多种 Runner)"
echo "3) 查看当前配置"
echo "4) 检查构建环境"

read -p "请输入选项 (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🔧 配置简化版 GitLab CI/CD..."
        
        # 备份现有配置
        if [ -f ".gitlab-ci.yml" ]; then
            mv .gitlab-ci.yml .gitlab-ci.yml.backup
            echo "✅ 已备份现有配置为 .gitlab-ci.yml.backup"
        fi
        
        # 使用简化版配置
        cp .gitlab-ci-simple.yml .gitlab-ci.yml
        echo "✅ 已启用简化版配置"
        
        echo ""
        echo "📋 简化版配置特点:"
        echo "   - 仅需要 Linux Runner (Docker 执行器)"
        echo "   - 构建 Linux 版本 (.deb, .AppImage)"
        echo "   - 支持前端构建验证"
        echo "   - 支持手动触发构建"
        
        echo ""
        echo "🎯 下一步操作:"
        echo "1. 确保 GitLab 有可用的 Linux Runner"
        echo "2. 推送代码: git add . && git commit -m '配置 GitLab CI/CD' && git push"
        echo "3. 查看构建状态: GitLab 项目 → CI/CD → Pipelines"
        ;;
        
    2)
        echo ""
        echo "🔧 配置完整版 GitLab CI/CD..."
        
        # 检查是否已经是完整版
        if [ -f ".gitlab-ci.yml" ] && grep -q "build:windows" .gitlab-ci.yml; then
            echo "✅ 已经是完整版配置"
        else
            echo "✅ 完整版配置已存在于 .gitlab-ci.yml"
        fi
        
        echo ""
        echo "📋 完整版配置特点:"
        echo "   - 支持 Windows, macOS, Linux 构建"
        echo "   - 需要对应的 Runner (windows, macos, linux 标签)"
        echo "   - 自动创建 GitLab Release"
        echo "   - 完整的产物管理"
        
        echo ""
        echo "⚠️  Runner 要求:"
        echo "   - Linux Runner (必需): 标签 'linux'"
        echo "   - Windows Runner (可选): 标签 'windows'"
        echo "   - macOS Runner (可选): 标签 'macos'"
        
        echo ""
        echo "🎯 下一步操作:"
        echo "1. 配置所需的 GitLab Runner"
        echo "2. 验证 Runner 标签是否正确"
        echo "3. 推送代码测试构建"
        ;;
        
    3)
        echo ""
        echo "📋 当前配置状态:"
        
        if [ -f ".gitlab-ci.yml" ]; then
            echo "✅ GitLab CI 配置文件存在"
            
            # 检查配置类型
            if grep -q "build:windows" .gitlab-ci.yml; then
                echo "📦 配置类型: 完整版 (跨平台)"
                echo "🎯 支持平台: Windows, macOS, Linux"
            else
                echo "📦 配置类型: 简化版 (Linux only)"
                echo "🎯 支持平台: Linux"
            fi
            
            # 显示构建阶段
            echo ""
            echo "🔄 构建阶段:"
            grep "stage:" .gitlab-ci.yml | sed 's/.*stage:/   -/' | sort -u
            
        else
            echo "❌ 未找到 GitLab CI 配置文件"
            echo "💡 运行选项 1 或 2 来创建配置"
        fi
        
        # 检查备用配置
        if [ -f ".gitlab-ci-simple.yml" ]; then
            echo "✅ 简化版配置可用"
        fi
        
        if [ -f ".gitlab-ci.yml.backup" ]; then
            echo "📄 发现备份配置: .gitlab-ci.yml.backup"
        fi
        ;;
        
    4)
        echo ""
        echo "🔍 检查构建环境..."
        
        # 检查基本工具
        echo "检查基本工具:"
        for tool in git node npm; do
            if command -v $tool &> /dev/null; then
                version=$(${tool} --version 2>/dev/null | head -1)
                echo "   ✅ $tool: $version"
            else
                echo "   ❌ $tool: 未安装"
            fi
        done
        
        # 检查 Rust
        if command -v rustc &> /dev/null; then
            rust_version=$(rustc --version)
            echo "   ✅ Rust: $rust_version"
        else
            echo "   ❌ Rust: 未安装"
        fi
        
        # 检查项目文件
        echo ""
        echo "检查项目文件:"
        for file in "package.json" "src-tauri/Cargo.toml" "src-tauri/tauri.conf.json"; do
            if [ -f "$file" ]; then
                echo "   ✅ $file"
            else
                echo "   ❌ $file"
            fi
        done
        
        # 检查 GitLab 相关
        echo ""
        echo "检查 GitLab 配置:"
        
        # 检查 remote
        if git remote get-url origin | grep -q gitlab; then
            echo "   ✅ Git remote 指向 GitLab"
            echo "   🔗 $(git remote get-url origin)"
        else
            echo "   ⚠️  Git remote 未指向 GitLab"
            echo "   🔗 $(git remote get-url origin)"
        fi
        
        # 检查 CI 配置
        if [ -f ".gitlab-ci.yml" ]; then
            echo "   ✅ GitLab CI 配置存在"
        else
            echo "   ❌ GitLab CI 配置不存在"
        fi
        
        echo ""
        echo "💡 环境检查完成！"
        ;;
        
    *)
        echo "❌ 无效选项，请选择 1-4"
        exit 1
        ;;
esac

echo ""
echo "📚 更多信息:"
echo "   - 详细指南: docs/gitlab-cicd-guide.md"
echo "   - GitHub Actions 对比: docs/github-actions-guide.md"
echo ""
echo "🎉 设置完成！" 