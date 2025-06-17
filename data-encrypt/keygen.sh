#!/bin/bash

# 创建密钥存储目录
mkdir -p keys

# 生成 RSA 2048 bit 密钥对
echo "正在生成 RSA 密钥对..."
openssl genpkey -algorithm RSA -out rsa-priv.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in rsa-priv.pem -out rsa-pub.pem

# 显示生成的密钥信息
echo ""
echo "密钥对已生成:"
echo "- 私钥: rsa-priv.pem (用于数据解密，保存在服务器端)"
echo "- 公钥: rsa-pub.pem (用于数据加密，分发给数据生产方)"
echo ""
echo "注意: 私钥必须安全保管，不能泄露或丢失！"
echo "已完成密钥生成。"