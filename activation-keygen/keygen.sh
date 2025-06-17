# 生成 Ed25519 私钥
openssl genpkey -algorithm ED25519 -out ed25519-priv.pem
# 导出 Ed25519 公钥 需要替换 key.rs 的内容为生成的内容 （别丢了，丢了就真 G 了）
openssl pkey -in  ed25519-priv.pem -pubout -out ed25519-pub.pem