use sqlx::{
  migrate::MigrateDatabase,
  sqlite::{SqlitePool, SqlitePoolOptions},
  Sqlite,
};
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

use once_cell::sync::OnceCell;

static DB_POOL: OnceCell<SqlitePool> = OnceCell::new();

pub struct Database;

impl Database {
  pub async fn init_db(app_handle: AppHandle) -> Result<SqlitePool, String> {
    let path = prepare_db_path(&app_handle)?;
    println!("数据库路径: {}", path.to_str().unwrap());
    let connection_string = format!("sqlite:{}", path.to_str().expect("文件夹路径不能为空！"));

    match std::fs::create_dir_all(path.parent().unwrap()) {
      Ok(_) => {}
      Err(err) => {
        return Err(format!("创建文件夹错误：{}", err));
      }
    }

    // 检查数据库是否存在，如果不存在则创建
    if !std::path::Path::new(&path).exists() {
      match Sqlite::create_database(&connection_string).await {
        Ok(_) => {}
        Err(e) => return Err(format!("创建数据库失败: {}", e)),
      }
    }

    // 创建数据库连接池
    let db = match SqlitePoolOptions::new()
      .max_connections(5)
      .connect(&connection_string)
      .await
    {
      Ok(pool) => pool,
      Err(e) => return Err(format!("连接数据库失败: {}", e)),
    };

    // 运行迁移
    match sqlx::migrate!("./migrations").run(&db).await {
      Ok(_) => {}
      Err(e) => return Err(format!("数据库迁移失败: {}", e)),
    }

    // 将连接池存入全局
DB_POOL.set(db.clone()).ok();
Ok(db)
  }
}

/// 获取全局数据库连接池
pub fn get_pool() -> Result<&'static SqlitePool, String> {
    DB_POOL.get().ok_or_else(|| "数据库尚未初始化".into())
}

// 准备数据库路径
fn prepare_db_path(app_handle: &AppHandle) -> Result<PathBuf, String> {
  let app_dir = app_handle
    .path()
    .app_data_dir()
    .map_err(|e| format!("无法获取应用数据目录: {}", e))?;

  // 确保目录存在
  std::fs::create_dir_all(&app_dir).map_err(|e| format!("无法创建应用数据目录: {}", e))?;

  // 返回数据库文件路径
  Ok(app_dir.join("ezlottery-offline.sqlite"))
}
