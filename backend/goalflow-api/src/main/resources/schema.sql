-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户 ID',
  email VARCHAR(255) NOT NULL UNIQUE COMMENT '邮箱',
  password VARCHAR(255) NOT NULL COMMENT '密码',
  nickname VARCHAR(255) COMMENT '昵称',
  avatar VARCHAR(255) COMMENT '头像 URL',
  created_at DATETIME COMMENT '创建时间'
) COMMENT='用户表';

-- 目标表（user_id 逻辑关联 users.id，代码层校验）
CREATE TABLE IF NOT EXISTS goals (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '目标 ID',
  user_id BIGINT NOT NULL COMMENT '所属用户 ID（逻辑关联）',
  name VARCHAR(255) NOT NULL COMMENT '目标名称',
  emoji VARCHAR(32) COMMENT '目标图标 emoji',
  description TEXT COMMENT '目标描述',
  total_days INT NOT NULL COMMENT '计划总天数',
  template_id BIGINT COMMENT '来源模板 ID（逻辑关联）',
  join_ranking TINYINT(1) DEFAULT 0 COMMENT '是否加入模板排行榜',
  status VARCHAR(32) COMMENT '状态：ACTIVE, COMPLETED 等',
  created_at DATETIME COMMENT '创建时间'
) COMMENT='目标表';

-- 目标计划项表（goal_id 逻辑关联 goals.id，代码层校验）
CREATE TABLE IF NOT EXISTS goal_plan_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '计划项 ID',
  goal_id BIGINT NOT NULL COMMENT '所属目标 ID（逻辑关联）',
  day_number INT COMMENT '第几天（从 0 开始）',
  task_text TEXT COMMENT '任务内容'
) COMMENT='目标计划项表';

-- 模板表（owner_id 逻辑关联 users.id，代码层校验）
CREATE TABLE IF NOT EXISTS templates (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '模板 ID',
  owner_id BIGINT NOT NULL COMMENT '模板所有者 ID（逻辑关联）',
  name VARCHAR(255) NOT NULL COMMENT '模板名称',
  description TEXT COMMENT '模板描述',
  total_days INT NOT NULL COMMENT '模板总天数',
  visibility VARCHAR(32) COMMENT '可见性：PRIVATE, PUBLIC',
  tags VARCHAR(255) COMMENT '标签（逗号分隔）',
  status VARCHAR(32) DEFAULT 'DRAFT' COMMENT '模板状态：DRAFT(私有草稿), PENDING(待审核), APPROVED(已通过), REJECTED(已拒绝)',
  reviewed_at DATETIME COMMENT '审核时间',
  reviewed_by BIGINT COMMENT '审核人 ID',
  reject_reason VARCHAR(500) COMMENT '拒绝原因',
  created_at DATETIME COMMENT '创建时间'
) COMMENT='模板表';

-- 模板计划项表（template_id 逻辑关联 templates.id，代码层校验）
CREATE TABLE IF NOT EXISTS template_plan_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '模板计划项 ID',
  template_id BIGINT NOT NULL COMMENT '所属模板 ID（逻辑关联）',
  day_number INT COMMENT '第几天',
  task_text TEXT COMMENT '任务内容'
) COMMENT='模板计划项表';

-- 勋章表（user_id、goal_id 逻辑关联，代码层校验）
CREATE TABLE IF NOT EXISTS medals (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '勋章 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  goal_id BIGINT NOT NULL COMMENT '目标 ID（逻辑关联）',
  title VARCHAR(255) COMMENT '勋章名称',
  awarded_at DATETIME COMMENT '授予时间'
) COMMENT='勋章表';

-- 排行榜表（template_id、user_id 逻辑关联，代码层校验）
CREATE TABLE IF NOT EXISTS rankings (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '排行榜 ID',
  template_id BIGINT NOT NULL COMMENT '模板 ID（逻辑关联）',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  progress_percent INT COMMENT '进度百分比',
  previous_rank INT DEFAULT 0 COMMENT '上次排名',
  updated_at DATETIME COMMENT '更新时间'
) COMMENT='排行榜表';

-- 每日记录表（user_id、goal_id 逻辑关联，代码层校验）
CREATE TABLE IF NOT EXISTS day_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '记录 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID（逻辑关联）',
  goal_id BIGINT NOT NULL COMMENT '目标 ID（逻辑关联）',
  date DATE NOT NULL COMMENT '实际日期',
  day_number INT COMMENT '计划中的第几天'
) COMMENT='每日记录表';

-- 任务记录表（day_record_id 逻辑关联 day_records.id，代码层校验）
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

-- 每日复盘主表（user_id 逻辑关联 users.id，代码层校验）
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

-- 每日复盘维度项表（review_id 逻辑关联 daily_reviews.id，代码层校验）
CREATE TABLE IF NOT EXISTS daily_review_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '复盘维度项 ID',
  review_id BIGINT NOT NULL COMMENT '复盘主记录 ID（逻辑关联）',
  dimension VARCHAR(32) NOT NULL COMMENT '维度枚举',
  status VARCHAR(16) NOT NULL COMMENT '状态枚举',
  comment VARCHAR(500) NOT NULL COMMENT '维度备注',
  UNIQUE KEY uniq_review_dimension (review_id, dimension),
  KEY idx_daily_review_items_review_id (review_id)
) COMMENT='每日复盘维度项表';

SET @task_index_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'task_records'
    AND column_name = 'task_index'
);
SET @task_index_sql = IF(
  @task_index_exists = 0,
  'ALTER TABLE task_records ADD COLUMN task_index INT',
  'SELECT 1'
);
PREPARE stmt_task_index FROM @task_index_sql;
EXECUTE stmt_task_index;
DEALLOCATE PREPARE stmt_task_index;

SET @goal_template_id_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'goals'
    AND column_name = 'template_id'
);
SET @goal_template_id_sql = IF(
  @goal_template_id_exists = 0,
  'ALTER TABLE goals ADD COLUMN template_id BIGINT NULL AFTER total_days',
  'SELECT 1'
);
PREPARE stmt_goal_template_id FROM @goal_template_id_sql;
EXECUTE stmt_goal_template_id;
DEALLOCATE PREPARE stmt_goal_template_id;

SET @goal_join_ranking_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'goals'
    AND column_name = 'join_ranking'
);
SET @goal_join_ranking_sql = IF(
  @goal_join_ranking_exists = 0,
  'ALTER TABLE goals ADD COLUMN join_ranking TINYINT(1) DEFAULT 0 AFTER template_id',
  'SELECT 1'
);
PREPARE stmt_goal_join_ranking FROM @goal_join_ranking_sql;
EXECUTE stmt_goal_join_ranking;
DEALLOCATE PREPARE stmt_goal_join_ranking;

SET @ranking_previous_rank_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'rankings'
    AND column_name = 'previous_rank'
);
SET @ranking_previous_rank_sql = IF(
  @ranking_previous_rank_exists = 0,
  'ALTER TABLE rankings ADD COLUMN previous_rank INT DEFAULT 0 AFTER progress_percent',
  'SELECT 1'
);
PREPARE stmt_ranking_previous_rank FROM @ranking_previous_rank_sql;
EXECUTE stmt_ranking_previous_rank;
DEALLOCATE PREPARE stmt_ranking_previous_rank;

SET @template_status_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'templates'
    AND column_name = 'status'
);
SET @template_status_sql = IF(
  @template_status_exists = 0,
  'ALTER TABLE templates ADD COLUMN status VARCHAR(32) DEFAULT ''DRAFT'' COMMENT ''模板状态：DRAFT(私有草稿), PENDING(待审核), APPROVED(已通过), REJECTED(已拒绝)'' AFTER tags',
  'SELECT 1'
);
PREPARE stmt_template_status FROM @template_status_sql;
EXECUTE stmt_template_status;
DEALLOCATE PREPARE stmt_template_status;

SET @template_reviewed_at_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'templates'
    AND column_name = 'reviewed_at'
);
SET @template_reviewed_at_sql = IF(
  @template_reviewed_at_exists = 0,
  'ALTER TABLE templates ADD COLUMN reviewed_at DATETIME NULL COMMENT ''审核时间'' AFTER status',
  'SELECT 1'
);
PREPARE stmt_template_reviewed_at FROM @template_reviewed_at_sql;
EXECUTE stmt_template_reviewed_at;
DEALLOCATE PREPARE stmt_template_reviewed_at;

SET @template_reviewed_by_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'templates'
    AND column_name = 'reviewed_by'
);
SET @template_reviewed_by_sql = IF(
  @template_reviewed_by_exists = 0,
  'ALTER TABLE templates ADD COLUMN reviewed_by BIGINT NULL COMMENT ''审核人 ID'' AFTER reviewed_at',
  'SELECT 1'
);
PREPARE stmt_template_reviewed_by FROM @template_reviewed_by_sql;
EXECUTE stmt_template_reviewed_by;
DEALLOCATE PREPARE stmt_template_reviewed_by;

SET @template_reject_reason_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'templates'
    AND column_name = 'reject_reason'
);
SET @template_reject_reason_sql = IF(
  @template_reject_reason_exists = 0,
  'ALTER TABLE templates ADD COLUMN reject_reason VARCHAR(500) NULL COMMENT ''拒绝原因'' AFTER reviewed_by',
  'SELECT 1'
);
PREPARE stmt_template_reject_reason FROM @template_reject_reason_sql;
EXECUTE stmt_template_reject_reason;
DEALLOCATE PREPARE stmt_template_reject_reason;
