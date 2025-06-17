#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { Buffer } from 'buffer';

/**
 * CSV 数据加密工具
 * 提供加密相关的功能作为可重用模块
 */

/**
 * 使用 RSA 公钥加密对称密钥
 * @param {Buffer} symmetricKey - 需要加密的对称密钥
 * @param {string} publicKeyPath - RSA 公钥路径
 * @returns {Buffer} - 加密后的对称密钥
 */
export function encryptSymmetricKey(symmetricKey, publicKeyPath) {
  const publicKey = fs.readFileSync(publicKeyPath, 'utf8');
  const keyObj = crypto.createPublicKey(publicKey);
  return crypto.publicEncrypt(
    {
      key: keyObj,
      padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
      oaepHash: 'sha256'
    },
    symmetricKey
  );
}

/**
 * 使用 AES-GCM 加密数据
 * @param {Buffer} data - 需要加密的数据
 * @param {Buffer} key - AES 对称密钥
 * @returns {Object} - 包含密文和认证标签的对象
 */
export function encryptData(data, key) {
  // 生成随机初始向量
  const iv = crypto.randomBytes(12);
  
  // 创建加密器
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  
  // 加密数据
  const encrypted = Buffer.concat([
    cipher.update(data),
    cipher.final()
  ]);
  
  // 获取认证标签
  const authTag = cipher.getAuthTag();
  
  return {
    iv,
    encrypted,
    authTag
  };
}

/**
 * 加密 CSV 文件为 .dat 格式
 * @param {string} csvFilePath - CSV 文件路径
 * @param {string} publicKeyPath - 公钥路径
 * @param {string} outputPath - 输出文件路径 (可选，默认为与输入相同目录的 .dat 文件)
 * @returns {Promise<string>} - 输出文件路径
 */
export async function encryptCsvFile(csvFilePath, publicKeyPath, outputPath = null) {
  // 验证文件存在
  if (!fs.existsSync(csvFilePath)) {
    throw new Error(`文件不存在: ${csvFilePath}`);
  }
  
  if (!fs.existsSync(publicKeyPath)) {
    throw new Error(`公钥文件不存在: ${publicKeyPath}`);
  }
  
  // 读取 CSV 文件内容
  const csvData = fs.readFileSync(csvFilePath);
  
  // 生成随机对称密钥 (32 字节 / 256 位 AES 密钥)
  const symmetricKey = crypto.randomBytes(32);
  
  // 使用 RSA 公钥加密对称密钥
  const encryptedKey = encryptSymmetricKey(symmetricKey, publicKeyPath);
  
  // 使用对称密钥加密 CSV 内容
  const { iv, encrypted, authTag } = encryptData(csvData, symmetricKey);
  
  // 创建输出格式 (文件头 + 加密密钥 + IV + 认证标签 + 加密数据)
  const output = Buffer.concat([
    Buffer.from('EZLOTTERY'),    // 8 字节文件头
    Buffer.from([1]),           // 1 字节版本号
    Buffer.alloc(3),            // 3 字节保留
    Buffer.from([encryptedKey.length & 0xFF, (encryptedKey.length >> 8) & 0xFF]), // 2 字节密钥长度
    encryptedKey,               // 加密后的对称密钥
    iv,                         // 12 字节初始向量
    authTag,                    // 16 字节认证标签
    encrypted                    // 加密后的 CSV 数据
  ]);
  
  // 生成输出文件路径 (如果未指定)
  if (!outputPath) {
    const baseName = path.basename(csvFilePath, path.extname(csvFilePath));
    outputPath = path.join(path.dirname(csvFilePath), `${baseName}.dat`);
  }
  
  // 写入加密文件
  fs.writeFileSync(outputPath, output);
  
  return outputPath;
}

// 如果直接作为脚本运行，则提供命令行界面
if (import.meta.url === `file://${process.argv[1]}`) {
  import('readline/promises').then(({ createInterface }) => {
    async function main() {
      console.log('\n=== CSV 数据加密工具 ===\n');

      try {
        const rl = createInterface({ input: process.stdin, output: process.stdout });
        
        // 获取输入文件路径 (默认: ./data.csv)
        const _csvPath = await rl.question('请输入 CSV 文件路径 (默认: ./data.csv): ');
        const csvPath = _csvPath.trim() || './data.csv';
        
        // 获取输出文件路径 (默认: ./data.dat)
        const _outputPath = await rl.question('请输入输出文件路径 (默认: ./data.dat): ');
        const outputPath = _outputPath.trim() || './data.dat';
        
        // 获取公钥路径 (默认: ./rsa-pub.pem)
        const _publicKeyPath = await rl.question('请输入公钥路径 (默认: ./rsa-pub.pem): ');
        const publicKeyPath = _publicKeyPath.trim() || './rsa-pub.pem';
        
        rl.close();
        
        console.log('\n开始加密过程...');
        
        // 执行加密
        const outPath = await encryptCsvFile(csvPath, publicKeyPath, outputPath);
        
        console.log(`\n✓ 加密完成!`);
        console.log(`✓ 输出文件: ${outPath}`);
        console.log('\n该文件现在可以安全地传输。只有持有私钥的运行环境才能解密。');
      } catch (err) {
        console.error(`错误: ${err.message}`);
        process.exit(1);
      }
    }

    main().catch(err => { console.error(`未处理错误: ${err}`); process.exit(1); });
  }).catch(err => {
    console.error(`模块导入错误: ${err}`);
    process.exit(1);
  });
}
