#!/bin/bash

# Windows 版本编译脚本
echo "开始编译 Windows 版本..."

# 检查是否安装了 Windows 目标
if ! rustup target list --installed | grep -q "x86_64-pc-windows-msvc"; then
    echo "正在安装 Windows 编译目标..."
    rustup target add x86_64-pc-windows-msvc
fi

# 编译 Windows 版本
echo "正在编译..."
npm run tauri build -- --target x86_64-pc-windows-msvc

echo "编译完成！Windows 安装包位于 src-tauri/target/x86_64-pc-windows-msvc/release/bundle/" 