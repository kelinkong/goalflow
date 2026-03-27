-- 习惯定义表 (身份塑造)
CREATE TABLE IF NOT EXISTS `habits` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `name` VARCHAR(100) NOT NULL COMMENT '我想成为什么样的人？所对应的习惯行为',
    `category` VARCHAR(32) DEFAULT 'DEFAULT',
    `status` VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE, ARCHIVED',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 习惯打卡记录表 (每日重复)
CREATE TABLE IF NOT EXISTS `habit_checkins` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `habit_id` BIGINT NOT NULL,
    `user_id` BIGINT NOT NULL,
    `date` DATE NOT NULL COMMENT '打卡日期',
    `is_done` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_habit_date` (`habit_id`, `date`),
    INDEX `idx_user_date` (`user_id`, `date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
