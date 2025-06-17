use csv::ReaderBuilder;
use serde::Serialize;
use tauri::command;
use sqlx::Row;
use std::io::{Read, BufReader, Cursor};
use std::fs::File;
use std::path::Path;
use openssl::rsa::Rsa;
use openssl::symm::{Cipher, decrypt_aead};

use crate::modules::database::get_pool;
use crate::modules::keys::RSA_PRIVATE_KEY_PEM;

#[derive(Serialize)]
pub struct Project {
    pub id: i64,
    pub name: String,
    pub description: Option<String>,
    pub created_at: String,
    pub updated_at: String,
    pub total_tickets: i64,
    pub redeemed_tickets: i64,
}

// 解密加密的数据文件(.dat)
fn decrypt_dat_file(file_path: &str) -> Result<Vec<u8>, String> {
    // 打开加密文件
    let file = File::open(file_path).map_err(|e| format!("无法打开文件: {}", e))?;
    let mut reader = BufReader::new(file);
    
    // 读取文件头 (8 bytes)
    let mut header = [0u8; 8];
    reader.read_exact(&mut header).map_err(|e| format!("读取文件头失败: {}", e))?;
    
    // 验证文件头
    if &header != b"EZLOTTER" {  // 8 bytes header
        return Err("无效的加密文件格式，文件头不匹配".to_string());
    }
    
    // 读取版本号 (1 byte)
    let mut version = [0u8; 1];
    reader.read_exact(&mut version).map_err(|e| format!("读取版本号失败: {}", e))?;
    if version[0] != 1 {
        return Err(format!("不支持的文件版本: {}", version[0]));
    }
    
    // 跳过保留字节 (3 bytes)
    reader.read_exact(&mut [0u8; 3]).map_err(|e| format!("读取保留字节失败: {}", e))?;
    
    // 读取加密密钥的长度 (2 bytes, 小端)
    let mut key_len_bytes = [0u8; 2];
    reader.read_exact(&mut key_len_bytes).map_err(|e| format!("读取密钥长度失败: {}", e))?;
    let key_len = u16::from_le_bytes(key_len_bytes) as usize;
    
    // 读取加密的对称密钥
    let mut encrypted_key = vec![0u8; key_len];
    reader.read_exact(&mut encrypted_key).map_err(|e| format!("读取加密密钥失败: {}", e))?;
    
    // 读取初始向量 (12 bytes)
    let mut iv = [0u8; 12];
    reader.read_exact(&mut iv).map_err(|e| format!("读取初始向量失败: {}", e))?;
    
    // 读取认证标签 (16 bytes)
    let mut tag = [0u8; 16];
    reader.read_exact(&mut tag).map_err(|e| format!("读取认证标签失败: {}", e))?;
    
    // 读取加密的数据
    let mut encrypted_data = Vec::new();
    reader.read_to_end(&mut encrypted_data).map_err(|e| format!("读取加密数据失败: {}", e))?;
    
    // 使用 RSA 私钥解密对称密钥
    let rsa = Rsa::private_key_from_pem(RSA_PRIVATE_KEY_PEM.as_bytes())
        .map_err(|e| format!("无法解析 RSA 私钥: {}", e))?;
    
    // 使用 RSA 私钥解密对称密钥
    // 注意: 我们需要使用 PKCS1 填充以匹配 JavaScript 的加密
    let mut decrypted_key = vec![0u8; rsa.size() as usize];
    let key_size = rsa.private_decrypt(
        &encrypted_key, 
        &mut decrypted_key, 
        openssl::rsa::Padding::PKCS1
    ).map_err(|e| format!("无法解密对称密钥: {}", e))?;
    
    decrypted_key.truncate(key_size);
    
    // 使用 AES-GCM 解密数据
    let plaintext = decrypt_aead(
        Cipher::aes_256_gcm(), 
        &decrypted_key, 
        Some(&iv), 
        &[], // AAD (额外验证数据), 这里未使用
        &encrypted_data, 
        &tag
    ).map_err(|e| format!("AES-GCM 解密失败: {}", e))?;
    
    Ok(plaintext)
}

#[command]
pub async fn import_project_dat(path: String, name: String) -> Result<(), String> {
    let path_obj = Path::new(&path);
    let extension = path_obj.extension().and_then(|ext| ext.to_str()).unwrap_or("");
    
    // 根据文件扩展名决定是否需要解密
    let csv_data = if extension.eq_ignore_ascii_case("dat") {
        // 解密 .dat 文件为 CSV 数据
        let decrypted_data = decrypt_dat_file(&path)?;
        decrypted_data
    } else {
        // 直接读取 CSV 文件
        std::fs::read(&path).map_err(|e| format!("读取文件失败: {}", e))?
    };
    
    // 从解密或直接读取的数据创建 CSV 读取器
    let cursor = Cursor::new(&csv_data);
    let mut rdr = ReaderBuilder::new()
        .has_headers(true)
        .from_reader(cursor);
    
    let headers = rdr
        .headers()
        .map_err(|e| format!("读取标题失败: {e}"))?
        .clone();

    // 允许任意顺序，但必须包含 prize, manual_code, security_code
    let prize_idx = headers.iter().position(|h| h == "prize");
    let manual_idx = headers.iter().position(|h| h == "manual_code");
    let security_idx = headers.iter().position(|h| h == "security_code");

    if prize_idx.is_none() || manual_idx.is_none() || security_idx.is_none() {
        return Err("CSV 标题行必须包含: prize,manual_code,security_code (顺序不限)".into());
    }

    let prize_idx = prize_idx.unwrap();
    let manual_idx = manual_idx.unwrap();
    let security_idx = security_idx.unwrap();

    // 2. 获取数据库池
    let pool = get_pool()?;
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;

    // 3. 插入到 projects，返回 id
    let project_id: i64 = sqlx::query("INSERT INTO projects (name, total_tickets) VALUES (?, 0) RETURNING id")
        .bind(&name)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| e.to_string())?
        .get(0);
        
    // 计算总票数
    let mut ticket_count = 0;

    // 4. 遍历记录批量插入
    for result in rdr.records() {
        let record = result.map_err(|e| e.to_string())?;
        let prize: i64 = record[prize_idx]
            .trim()
            .parse()
            .map_err(|_| "prize 字段必须是整数".to_string())?;
        let manual_code = record[manual_idx].trim();
        let security_code = record[security_idx].trim();

        sqlx::query(
            "INSERT INTO tickets (project_id, prize, manual_code, security_code) VALUES (?,?,?,?)",
        )
        .bind(project_id)
        .bind(prize)
        .bind(manual_code)
        .bind(security_code)
        .execute(&mut *tx)
        .await
        .map_err(|e| format!("插入票券失败: {e}"))?;
        
        ticket_count += 1;
    }

    // 更新项目的总票数
    sqlx::query("UPDATE projects SET total_tickets = ? WHERE id = ?")
        .bind(ticket_count)
        .bind(project_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| format!("更新总票数失败: {e}"))?;
        
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}