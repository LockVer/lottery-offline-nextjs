-- lottery-offline initial schema
PRAGMA foreign_keys = ON;

-- 1. 批次 / 项目
CREATE TABLE IF NOT EXISTS projects (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  description TEXT,
  total_tickets     INTEGER NOT NULL DEFAULT 0, -- 总票数
  redeemed_tickets  INTEGER NOT NULL DEFAULT 0, -- 已兑奖数量
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 票券主表
CREATE TABLE IF NOT EXISTS tickets (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id     INTEGER NOT NULL,
  prize          TEXT NOT NULL,
  manual_code    TEXT    NOT NULL UNIQUE,
  security_code     TEXT    NOT NULL,          -- 重复则拒绝兑换，插入时需要警告
  is_redeemed    BOOLEAN NOT NULL DEFAULT 0,
  redeemed_at    TIMESTAMP,                 -- 仅冗余记录，方便查询
  FOREIGN KEY (project_id)
    REFERENCES projects(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tickets_redeemed_at ON tickets(redeemed_at);

-- -- 3. 兑奖记录表（每张票仅兑奖一次，ticket_id UNIQUE）
-- CREATE TABLE IF NOT EXISTS redemptions (
--   id          INTEGER PRIMARY KEY AUTOINCREMENT,
--   ticket_id   INTEGER NOT NULL UNIQUE,
--   redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   FOREIGN KEY (ticket_id)
--     REFERENCES tickets(id)
--     ON DELETE CASCADE
-- );

-- CREATE INDEX IF NOT EXISTS idx_redemptions_redeemed_at ON redemptions(redeemed_at);