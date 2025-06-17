#!/bin/bash

# 本地构建测试脚本
# 用于验证构建配置是否正确，无需实际跨平台编译

set -e

echo "🔍 检查构建环境..."

# 检查必要的工具
echo "检查 Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    exit 1
fi
echo "✅ Node.js $(node --version)"

echo "检查 npm..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
fi
echo "✅ npm $(npm --version)"

echo "检查 Rust..."
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust 未安装"
    exit 1
fi
echo "✅ Rust $(rustc --version)"

echo "检查 Tauri CLI..."
if ! command -v tauri &> /dev/null; then
    echo "⚠️  Tauri CLI 未全局安装，将使用 npm run tauri"
fi

# 检查项目文件
echo ""
echo "🔍 检查项目配置..."

if [ ! -f "package.json" ]; then
    echo "❌ package.json 文件不存在"
    exit 1
fi
echo "✅ package.json 存在"

if [ ! -f "src-tauri/Cargo.toml" ]; then
    echo "❌ src-tauri/Cargo.toml 文件不存在"
    exit 1
fi
echo "✅ Cargo.toml 存在"

if [ ! -f "src-tauri/tauri.conf.json" ]; then
    echo "❌ tauri.conf.json 文件不存在"
    exit 1
fi
echo "✅ tauri.conf.json 存在"

# 安装依赖
echo ""
echo "📦 安装依赖..."
npm install

# 构建前端
echo ""
echo "🔨 构建前端..."
npm run build

# 检查 Tauri 配置
echo ""
echo "🔍 验证 Tauri 配置..."
npm run tauri info

echo ""
echo "✅ 所有检查通过！"
echo ""
echo "🚀 现在您可以："
echo "1. 推送代码到 GitHub 触发自动构建"
echo "2. 手动运行 GitHub Actions"
echo "3. 本地构建当前平台版本: npm run tauri build"
echo ""
echo "📖 详细说明请查看: docs/github-actions-guide.md" 