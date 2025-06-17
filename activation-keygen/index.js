#!/usr/bin/env node

import fs from 'fs';
import readline from 'readline';
import crypto from 'crypto';
import { Buffer } from 'buffer';

function toBase64Url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function cleanMachineCode(code) {
  return code.replace(/[^a-zA-Z0-9]/g, '');
}


function generateLicense(machineCode, expiry, features, privKeyPath) {
  const payload = { device_id: machineCode, expires: expiry, features };
  const payloadBuf = Buffer.from(JSON.stringify(payload));

  // 读取并解析 PEM → KeyObject
  const privPem = fs.readFileSync(privKeyPath, 'utf8');
  const keyObj  = crypto.createPrivateKey({ key: privPem, format: 'pem' });

  // Ed25519 签名
  const sigBuf = crypto.sign(null, payloadBuf, keyObj);
  return `${toBase64Url(payloadBuf)}.${toBase64Url(sigBuf)}`;
}


function isValidDate(date) {
  return /^\d{4}-\d{2}-\d{2}$/.test(date);
}

async function prompt(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(res => rl.question(question, ans => { rl.close(); res(ans); }));
}

async function main() {
  console.log('\n=== 离线许可证签发工具 ===\n');

  // TODO: 替换为安全来源读取

  const rawCode = await prompt('请输入机器码: ');
  const machineCode = cleanMachineCode(rawCode);
  const expiryInput = await prompt('请输入过期日期 (YYYY-MM-DD): ');
  const expiryDate = isValidDate(expiryInput) ? expiryInput : '2099-12-31';
  const featuresInput = await prompt('请输入功能列表 (逗号分隔，留空为 all): ');
  const features = featuresInput.trim() ? featuresInput.split(',').map(s => s.trim()) : ['all'];

  const license = generateLicense(machineCode, expiryDate, features, './ed25519-priv.pem');
  console.log('\n生成的许可证:\n');
  console.log(license);

  const outFile = `license-${machineCode.slice(0,8)}.txt`;
  fs.writeFileSync(outFile, license);
  console.log(`\n已保存到 ${outFile}`);
}

main().catch(err => { console.error(err); process.exit(1); });