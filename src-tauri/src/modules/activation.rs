use tauri::command;
use sha2::{Sha256, Digest};
use std::process::Command;
use base64::{engine::general_purpose, Engine as _};
use ed25519_dalek::{Verifier, VerifyingKey, Signature};
use serde::{Deserialize, Serialize};
use chrono::{NaiveDate, Utc};

// 引入密钥模块
use crate::modules::keys::ED25519_KEY_HEX as DEFAULT_PUBLIC_KEY_HEX;

const LICENSE_FILE_NAME: &str = ".license";

#[cfg(target_os = "windows")]
fn get_hardware_info() -> Vec<String> {
    let mut infos = Vec::new();
    // 主板序列号
    if let Ok(output) = Command::new("wmic").args(["baseboard", "get", "serialnumber"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        if let Some(code) = out.lines().nth(1) { infos.push(code.trim().to_string()); }
    }
    // CPU 序列号
    if let Ok(output) = Command::new("wmic").args(["cpu", "get", "ProcessorId"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        if let Some(code) = out.lines().nth(1) { infos.push(code.trim().to_string()); }
    }
    // 硬盘序列号
    if let Ok(output) = Command::new("wmic").args(["diskdrive", "get", "serialnumber"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        if let Some(code) = out.lines().nth(1) { infos.push(code.trim().to_string()); }
    }
    infos
}

#[cfg(target_os = "macos")]
fn get_hardware_info() -> Vec<String> {
    let mut infos = Vec::new();
    // 主板序列号（等同于系统序列号）
    if let Ok(output) = Command::new("system_profiler").args(["SPHardwareDataType"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        for line in out.lines() {
            if line.trim_start().starts_with("Serial Number") {
                if let Some(sn) = line.split(':').nth(1) { infos.push(sn.trim().to_string()); }
            }
        }
    }
    // CPU 信息
    if let Ok(output) = Command::new("sysctl").args(["-n", "machdep.cpu.brand_string"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        infos.push(out.trim().to_string());
    }
    // 硬盘序列号（首块磁盘）
    if let Ok(output) = Command::new("system_profiler").args(["SPSerialATADataType"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        for line in out.lines() {
            if line.trim_start().starts_with("Serial Number") {
                if let Some(sn) = line.split(':').nth(1) { infos.push(sn.trim().to_string()); break; }
            }
        }
    }
    infos
}

#[cfg(target_os = "linux")]
fn get_hardware_info() -> Vec<String> {
    let mut infos = Vec::new();
    // 主板序列号
    if let Ok(output) = Command::new("cat").args(["/sys/class/dmi/id/board_serial"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        infos.push(out.trim().to_string());
    }
    // CPU 信息
    if let Ok(output) = Command::new("cat").args(["/proc/cpuinfo"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        for line in out.lines() {
            if line.starts_with("processor") || line.starts_with("model name") {
                infos.push(line.trim().to_string());
            }
        }
    }
    // 硬盘序列号
    if let Ok(output) = Command::new("lsblk").args(["-o", "NAME,SERIAL", "-n", "-d"]).output() {
        let out = String::from_utf8_lossy(&output.stdout);
        if let Some(line) = out.lines().next() {
            infos.push(line.trim().to_string());
        }
    }
    infos
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_hardware_info() -> Vec<String> {
    vec!["unsupported-platform".to_string()]
}

#[derive(Deserialize, Serialize)]
struct LicensePayload {
    device_id: String,
    expires: String,
    features: Vec<String>,
}

fn format_activation_code(code: &str) -> String {
    code.as_bytes()
        .chunks(4)
        .map(|chunk| std::str::from_utf8(chunk).unwrap())
        .collect::<Vec<_>>()
        .join("-")
}

#[command]
pub fn get_machine_code() -> String {
    let infos = get_hardware_info();
    let concat = infos.join(":");
    let mut hasher = Sha256::new();
    hasher.update(concat.as_bytes());
    let hash = hasher.finalize();
    let hex = format!("{:x}", hash);
    format_activation_code(&hex)
}

#[command]
pub fn verify_license(license: String) -> Result<bool, String> {
    // 分离 payload 和 signature
    let mut parts = license.split('.');
    let payload_b64 = parts.next().ok_or("证书格式错误")?;
    let sig_b64 = parts.next().ok_or("证书格式错误")?;

    let payload_bytes = general_purpose::URL_SAFE_NO_PAD
        .decode(payload_b64)
        .map_err(|e| format!("Base64 解码失败: {}", e))?;
    let signature_bytes = general_purpose::URL_SAFE_NO_PAD
        .decode(sig_b64)
        .map_err(|e| format!("Base64 解码失败: {}", e))?;

    // 验证签名 (公钥是 SPKI DER base64)
    let public_key_der = general_purpose::STANDARD
        .decode(DEFAULT_PUBLIC_KEY_HEX)
        .map_err(|e| format!("公钥 base64 解码失败: {}", e))?;
    // 提取公钥的最后 32 字节
    let key_slice = public_key_der
        .get(public_key_der.len().saturating_sub(32)..)
        .ok_or("DER 格式错误")?;
    let key_array: [u8; 32] = key_slice.try_into().map_err(|_| "Key length")?;
    let verifying_key = VerifyingKey::from_bytes(&key_array)
        .map_err(|e| format!("创建验证密钥失败: {}", e))?;
    let sig_array: [u8;64] = signature_bytes.as_slice().try_into().map_err(|_| "Signature length")?;
    let signature = Signature::from_bytes(&sig_array);

    verifying_key
        .verify(&payload_bytes, &signature)
        .map_err(|e| format!("签名验证失败: {}", e))?;

    // 解析 payload JSON
    let payload: LicensePayload = serde_json::from_slice(&payload_bytes)
        .map_err(|e| format!("解析 payload 失败: {}", e))?;

    // 检查机器码匹配 (忽略连字符)
    let expected_code = get_machine_code().replace('-', "");
    let payload_code = payload.device_id.replace('-', "");
    if expected_code != payload_code {
        return Err("设备 ID 匹配失败".into());
    }

    // 检查过期日期
    let expiry_date = NaiveDate::parse_from_str(&payload.expires, "%Y-%m-%d")
        .map_err(|e| format!("过期日期解析失败: {}", e))?;
    let today = Utc::now().date_naive();
    if today > expiry_date {
        return Err("许可证已过期".into());
    }

    // Cache the license for future checks
    if let Err(e) = std::fs::write(LICENSE_FILE_NAME, &license) {
        log::warn!("缓存许可证失败: {}", e);
    }

    Ok(true)
}

/// Check if software is already activated by reading cached license file and verifying it
#[command]
pub fn is_software_activated() -> Result<bool, String> {
    use std::fs;
    use std::path::Path;

    let path = Path::new(LICENSE_FILE_NAME);
    if !path.exists() {
        return Ok(false);
    }

    let license_str = fs::read_to_string(path).map_err(|e| format!("读取许可证失败: {}", e))?;

    match verify_license(license_str) {
        Ok(true) => Ok(true),
        _ => Ok(false),
    }
}