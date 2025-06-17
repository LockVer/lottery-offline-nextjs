mod modules;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::Builder::new().build())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            crate::modules::activation::get_machine_code,
            crate::modules::activation::verify_license,
            crate::modules::activation::is_software_activated,
            crate::modules::project::import_project_dat,
        ])
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }
            
            // 初始化数据库
            let app_handle = app.handle().clone();
            tauri::async_runtime::block_on(async move {
                match crate::modules::database::Database::init_db(app_handle).await {
                    Ok(_) => log::info!("数据库初始化成功"),
                    Err(e) => {
                        log::error!("数据库初始化失败: {}", e);
                        panic!("数据库初始化失败: {}", e); 
                    }
                }
            });
            
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
