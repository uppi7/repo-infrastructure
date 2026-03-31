-- 大盘数据库初始化脚本
SET NAMES utf8mb4;

-- ---- 基础信息库 ----
CREATE DATABASE IF NOT EXISTS db_base
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_base;

CREATE TABLE IF NOT EXISTS teacher (
    id   INT PRIMARY KEY,
    name VARCHAR(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入初始测试数据
INSERT IGNORE INTO teacher (id, name) VALUES (1001, '张三');

-- ---- 排课库 ----
CREATE DATABASE IF NOT EXISTS db_course
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_course;

CREATE TABLE IF NOT EXISTS schedule (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id   INT NOT NULL,
    teacher_name VARCHAR(64),
    course       VARCHAR(128) NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
