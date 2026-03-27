-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户 ID',
  email VARCHAR(255) NOT NULL UNIQUE COMMENT '邮箱',
  password VARCHAR(255) NOT NULL COMMENT '密码',
  nickname VARCHAR(255) COMMENT '昵称',
  avatar MEDIUMTEXT COMMENT '头像数据或 URL',
  created_at DATETIME COMMENT '创建时间'
) COMMENT='用户表';

-- 目标表
CREATE TABLE IF NOT EXISTS goals (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '目标 ID',
  user_id BIGINT NOT NULL COMMENT '所属用户 ID（逻辑关联）',
  name VARCHAR(255) NOT NULL COMMENT '目标名称',
  emoji VARCHAR(32) COMMENT '目标图标 emoji',
  description TEXT COMMENT '目标描述',
  total_days INT NOT NULL COMMENT '计划总天数',
  status VARCHAR(32) COMMENT '状态：ACTIVE, COMPLETED 等',
  created_at DATETIME COMMENT '创建时间'
) COMMENT='目标表';

-- 目标计划项表
CREATE TABLE IF NOT EXISTS goal_plan_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '计划项 ID',
  goal_id BIGINT NOT NULL COMMENT '所属目标 ID（逻辑关联）',
  day_number INT COMMENT '第几天（从 0 开始）',
  task_text TEXT COMMENT '任务内容'
) COMMENT='目标计划项表';

-- 每日记录表
CREATE TABLE IF NOT EXISTS day_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '记录 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  goal_id BIGINT NOT NULL COMMENT '目标 ID（逻辑关联）',
  date DATE NOT NULL COMMENT '实际日期',
  day_number INT COMMENT '计划中的第几天'
) COMMENT='每日记录表';

-- 任务记录表
CREATE TABLE IF NOT EXISTS task_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '任务记录 ID',
  day_record_id BIGINT NOT NULL COMMENT '所属每日记录 ID（逻辑关联）',
  task_index INT COMMENT '任务索引（当天的第几个任务）',
  task_text TEXT NOT NULL COMMENT '任务内容',
  is_done TINYINT(1) DEFAULT 0 COMMENT '是否已完成',
  is_deferred TINYINT(1) DEFAULT 0 COMMENT '是否已延期',
  is_makeup TINYINT(1) DEFAULT 0 COMMENT '是否是补做的任务',
  done_at DATETIME COMMENT '完成时间',
  deferred_to VARCHAR(32) COMMENT '延期到的日期'
) COMMENT='任务记录表';

-- 每日复盘主表
CREATE TABLE IF NOT EXISTS daily_reviews (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '复盘主记录 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  date DATE NOT NULL COMMENT '复盘日期',
  tomorrow_top_priority VARCHAR(255) NOT NULL COMMENT '明日最重要的事',
  created_at DATETIME NOT NULL COMMENT '创建时间',
  updated_at DATETIME NOT NULL COMMENT '更新时间',
  UNIQUE KEY uniq_user_date (user_id, date),
  KEY idx_daily_reviews_user_id (user_id),
  KEY idx_daily_reviews_date (date)
) COMMENT='每日复盘主表';

-- 每日复盘维度项表
CREATE TABLE IF NOT EXISTS daily_review_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '复盘维度项 ID',
  review_id BIGINT NOT NULL COMMENT '复盘主记录 ID（逻辑关联）',
  dimension VARCHAR(32) NOT NULL COMMENT '维度枚举',
  status VARCHAR(16) NOT NULL COMMENT '状态枚举',
  comment VARCHAR(500) NOT NULL COMMENT '维度备注',
  UNIQUE KEY uniq_review_dimension (review_id, dimension),
  KEY idx_daily_review_items_review_id (review_id)
) COMMENT='每日复盘维度项表';

-- 习惯表
CREATE TABLE IF NOT EXISTS habits (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '习惯 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  name VARCHAR(100) NOT NULL COMMENT '习惯名称',
  category VARCHAR(32) COMMENT '习惯分类',
  status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE, ARCHIVED',
  created_at DATETIME NOT NULL COMMENT '创建时间',
  updated_at DATETIME NOT NULL COMMENT '更新时间',
  KEY idx_habits_user_id (user_id),
  KEY idx_habits_user_status (user_id, status)
) COMMENT='习惯表';

-- 习惯打卡表
CREATE TABLE IF NOT EXISTS habit_checkins (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '习惯打卡 ID',
  habit_id BIGINT NOT NULL COMMENT '习惯 ID（逻辑关联）',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  date DATE NOT NULL COMMENT '打卡日期',
  is_done TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否完成',
  created_at DATETIME NOT NULL COMMENT '创建时间',
  updated_at DATETIME NOT NULL COMMENT '更新时间',
  UNIQUE KEY uniq_habit_date (habit_id, date),
  KEY idx_habit_checkins_user_date (user_id, date),
  KEY idx_habit_checkins_habit_id (habit_id)
) COMMENT='习惯打卡表';
