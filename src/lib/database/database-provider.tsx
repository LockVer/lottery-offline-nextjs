"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode } from "react";
import Database, { QueryResult } from "@tauri-apps/plugin-sql";
import { getDatabaseInstance } from "./database-connection";


interface DatabaseContextType {
  db: Database | null;
}

const DatabaseContext = createContext<DatabaseContextType | undefined>(undefined);

interface DatabaseProviderProps {
  children: ReactNode | ((context: DatabaseContextType) => ReactNode);
}

export function DatabaseProvider({ children }: DatabaseProviderProps) {
  const [db, setDb] = useState<Database | null>(null);

  // 初始化数据库连接
  useEffect(() => {
    async function initDatabase() {
      const db = await getDatabaseInstance();
      setDb(db);
    }
    initDatabase();

    // 组件卸载时关闭数据库连接
    return () => {
      if (db) {
        db.close()
          .then(() => console.log("数据库连接已关闭"))
          .catch((err) => console.error("关闭数据库连接失败:", err));
      }
    };
  }, []);

  const value = {
    db,
  };

  return (
    <DatabaseContext.Provider value={value}>
      {typeof children === 'function' ? children(value) : children}
    </DatabaseContext.Provider>
  );
}

export function useDatabase() {
  const context = useContext(DatabaseContext);
  if (context === undefined) {
    throw new Error("useDatabase必须在DatabaseProvider内部使用");
  }
  return context;
}