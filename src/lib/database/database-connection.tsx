import Database, { QueryResult } from "@tauri-apps/plugin-sql";

let dbInstance: Database | null = null;

const DB_URL = "sqlite:ezlottery-offline.sqlite";


export async function getDatabaseInstance(): Promise<Database> {
  if (!dbInstance) {
    dbInstance = await Database.load(DB_URL);
  }
  return dbInstance;
}