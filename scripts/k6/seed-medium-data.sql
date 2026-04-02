SET NAMES utf8mb4;

SET @seed_password = '$2a$10$ICqHVF2giC78lHFi4MRJHOlas2VLkINonvhAAeSnkRDEoZiHeeXuy';

INSERT INTO users (email, password, nickname, created_at) VALUES
  ('test@qq.com', @seed_password, '压测重度用户', DATE_SUB(NOW(), INTERVAL 360 DAY)),
  ('seed_medium_01@goalflow.local', @seed_password, '中度用户01', DATE_SUB(NOW(), INTERVAL 280 DAY)),
  ('seed_medium_02@goalflow.local', @seed_password, '中度用户02', DATE_SUB(NOW(), INTERVAL 279 DAY)),
  ('seed_medium_03@goalflow.local', @seed_password, '中度用户03', DATE_SUB(NOW(), INTERVAL 278 DAY)),
  ('seed_medium_04@goalflow.local', @seed_password, '中度用户04', DATE_SUB(NOW(), INTERVAL 277 DAY)),
  ('seed_medium_05@goalflow.local', @seed_password, '中度用户05', DATE_SUB(NOW(), INTERVAL 276 DAY)),
  ('seed_medium_06@goalflow.local', @seed_password, '中度用户06', DATE_SUB(NOW(), INTERVAL 275 DAY)),
  ('seed_medium_07@goalflow.local', @seed_password, '中度用户07', DATE_SUB(NOW(), INTERVAL 274 DAY)),
  ('seed_medium_08@goalflow.local', @seed_password, '中度用户08', DATE_SUB(NOW(), INTERVAL 273 DAY)),
  ('seed_light_01@goalflow.local', @seed_password, '轻度用户01', DATE_SUB(NOW(), INTERVAL 180 DAY)),
  ('seed_light_02@goalflow.local', @seed_password, '轻度用户02', DATE_SUB(NOW(), INTERVAL 179 DAY)),
  ('seed_light_03@goalflow.local', @seed_password, '轻度用户03', DATE_SUB(NOW(), INTERVAL 178 DAY)),
  ('seed_light_04@goalflow.local', @seed_password, '轻度用户04', DATE_SUB(NOW(), INTERVAL 177 DAY)),
  ('seed_light_05@goalflow.local', @seed_password, '轻度用户05', DATE_SUB(NOW(), INTERVAL 176 DAY)),
  ('seed_light_06@goalflow.local', @seed_password, '轻度用户06', DATE_SUB(NOW(), INTERVAL 175 DAY)),
  ('seed_light_07@goalflow.local', @seed_password, '轻度用户07', DATE_SUB(NOW(), INTERVAL 174 DAY)),
  ('seed_light_08@goalflow.local', @seed_password, '轻度用户08', DATE_SUB(NOW(), INTERVAL 173 DAY)),
  ('seed_light_09@goalflow.local', @seed_password, '轻度用户09', DATE_SUB(NOW(), INTERVAL 172 DAY)),
  ('seed_light_10@goalflow.local', @seed_password, '轻度用户10', DATE_SUB(NOW(), INTERVAL 171 DAY)),
  ('seed_light_11@goalflow.local', @seed_password, '轻度用户11', DATE_SUB(NOW(), INTERVAL 170 DAY)),
  ('seed_light_12@goalflow.local', @seed_password, '轻度用户12', DATE_SUB(NOW(), INTERVAL 169 DAY))
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  nickname = VALUES(nickname);

DROP TEMPORARY TABLE IF EXISTS seed_user_ids;
CREATE TEMPORARY TABLE seed_user_ids AS
SELECT id, email
FROM users
WHERE email = 'test@qq.com'
   OR email LIKE 'seed_medium_%@goalflow.local'
   OR email LIKE 'seed_light_%@goalflow.local';

DELETE dri
FROM daily_review_items dri
JOIN daily_reviews dr ON dr.id = dri.review_id
JOIN seed_user_ids su ON su.id = dr.user_id;

DELETE hc
FROM habit_checkins hc
JOIN seed_user_ids su ON su.id = hc.user_id;

DELETE dr
FROM daily_reviews dr
JOIN seed_user_ids su ON su.id = dr.user_id;

DELETE tr
FROM task_records tr
JOIN day_records d ON d.id = tr.day_record_id
JOIN seed_user_ids su ON su.id = d.user_id;

DELETE d
FROM day_records d
JOIN seed_user_ids su ON su.id = d.user_id;

DELETE gpi
FROM goal_plan_items gpi
JOIN goals g ON g.id = gpi.goal_id
JOIN seed_user_ids su ON su.id = g.user_id;

DELETE h
FROM habits h
JOIN seed_user_ids su ON su.id = h.user_id;

DELETE g
FROM goals g
JOIN seed_user_ids su ON su.id = g.user_id;

DROP PROCEDURE IF EXISTS seed_user_dataset;

DELIMITER $$
CREATE PROCEDURE seed_user_dataset(
  IN p_email VARCHAR(255),
  IN p_nickname VARCHAR(255),
  IN p_goal_count INT,
  IN p_goal_days INT,
  IN p_tasks_per_day INT,
  IN p_habit_count INT,
  IN p_habit_days INT,
  IN p_review_days INT,
  IN p_user_offset INT
)
BEGIN
  DECLARE v_user_id BIGINT;
  DECLARE v_goal_id BIGINT;
  DECLARE v_day_record_id BIGINT;
  DECLARE v_habit_id BIGINT;
  DECLARE v_review_id BIGINT;
  DECLARE v_goal_created DATETIME;
  DECLARE v_goal_date DATE;
  DECLARE v_habit_date DATE;
  DECLARE v_review_date DATE;
  DECLARE v_habit_created DATETIME;
  DECLARE v_now DATETIME;
  DECLARE v_done_at DATETIME;
  DECLARE v_status VARCHAR(32);
  DECLARE v_category VARCHAR(32);
  DECLARE v_dimension_status_1 VARCHAR(16);
  DECLARE v_dimension_status_2 VARCHAR(16);
  DECLARE v_dimension_status_3 VARCHAR(16);
  DECLARE v_dimension_status_4 VARCHAR(16);
  DECLARE v_done TINYINT;
  DECLARE v_deferred TINYINT;
  DECLARE v_makeup TINYINT;
  DECLARE v_deferred_to VARCHAR(32);
  DECLARE goal_i INT DEFAULT 0;
  DECLARE day_i INT DEFAULT 0;
  DECLARE task_i INT DEFAULT 0;
  DECLARE habit_i INT DEFAULT 0;
  DECLARE review_i INT DEFAULT 0;

  UPDATE users
  SET nickname = p_nickname,
      password = @seed_password
  WHERE email = p_email;

  SELECT id INTO v_user_id
  FROM users
  WHERE email = p_email
  LIMIT 1;

  SET goal_i = 0;
  WHILE goal_i < p_goal_count DO
    SET v_goal_created = DATE_SUB(NOW(), INTERVAL (p_goal_days + goal_i * 3 + p_user_offset) DAY);
    SET v_status = IF(MOD(goal_i + p_user_offset, 9) = 0, 'COMPLETED', 'ACTIVE');

    INSERT INTO goals (user_id, name, emoji, description, total_days, status, created_at)
    VALUES (
      v_user_id,
      CONCAT(p_nickname, '目标', LPAD(goal_i + 1, 2, '0')),
      ELT(MOD(goal_i, 6) + 1, '🎯', '📚', '🏃', '💼', '🧠', '🛠️'),
      CONCAT('用于压测的目标数据，用户=', p_nickname, '，目标序号=', goal_i + 1),
      p_goal_days,
      v_status,
      v_goal_created
    );
    SET v_goal_id = LAST_INSERT_ID();

    SET day_i = 0;
    WHILE day_i < p_goal_days DO
      SET task_i = 0;
      WHILE task_i < p_tasks_per_day DO
        INSERT INTO goal_plan_items (goal_id, day_number, task_text)
        VALUES (
          v_goal_id,
          day_i,
          CONCAT('第', day_i + 1, '天任务', task_i + 1, ' - ', p_nickname, ' - G', goal_i + 1)
        );
        SET task_i = task_i + 1;
      END WHILE;

      SET v_goal_date = DATE(DATE_ADD(v_goal_created, INTERVAL day_i DAY));
      IF v_status = 'COMPLETED' OR day_i < FLOOR(p_goal_days * 0.72) THEN
        INSERT INTO day_records (user_id, goal_id, date, day_number)
        VALUES (v_user_id, v_goal_id, v_goal_date, day_i);
        SET v_day_record_id = LAST_INSERT_ID();

        SET task_i = 0;
        WHILE task_i < p_tasks_per_day DO
          IF v_status = 'COMPLETED' OR MOD(goal_i + day_i + task_i + p_user_offset, 4) <> 0 THEN
            SET v_done = 1;
            SET v_deferred = 0;
            SET v_makeup = IF(MOD(goal_i + day_i + task_i + p_user_offset, 11) = 0, 1, 0);
            SET v_deferred_to = NULL;
            SET v_done_at = DATE_ADD(TIMESTAMP(v_goal_date, '20:00:00'), INTERVAL task_i HOUR);
          ELSE
            SET v_done = 0;
            SET v_makeup = 0;
            IF MOD(goal_i + day_i + task_i + p_user_offset, 6) = 0 AND day_i < p_goal_days - 1 THEN
              SET v_deferred = 1;
              SET v_deferred_to = DATE_FORMAT(DATE_ADD(v_goal_date, INTERVAL 1 DAY), '%Y-%m-%d');
            ELSE
              SET v_deferred = 0;
              SET v_deferred_to = NULL;
            END IF;
            SET v_done_at = NULL;
          END IF;

          INSERT INTO task_records (
            day_record_id, task_index, task_text, is_done, is_deferred, is_makeup, done_at, deferred_to
          ) VALUES (
            v_day_record_id,
            task_i,
            CONCAT('第', day_i + 1, '天任务', task_i + 1, ' - ', p_nickname, ' - G', goal_i + 1),
            v_done,
            v_deferred,
            v_makeup,
            v_done_at,
            v_deferred_to
          );
          SET task_i = task_i + 1;
        END WHILE;
      END IF;
      SET day_i = day_i + 1;
    END WHILE;
    SET goal_i = goal_i + 1;
  END WHILE;

  SET habit_i = 0;
  WHILE habit_i < p_habit_count DO
    SET v_habit_created = DATE_SUB(NOW(), INTERVAL (p_habit_days + habit_i + p_user_offset) DAY);
    SET v_now = DATE_SUB(NOW(), INTERVAL MOD(habit_i * 3 + p_user_offset, 5) DAY);
    SET v_category = ELT(MOD(habit_i + p_user_offset, 4) + 1, 'health', 'learning', 'career', 'mindset');

    INSERT INTO habits (user_id, name, category, status, created_at, updated_at)
    VALUES (
      v_user_id,
      CONCAT(p_nickname, '习惯', LPAD(habit_i + 1, 2, '0')),
      v_category,
      'ACTIVE',
      v_habit_created,
      v_now
    );
    SET v_habit_id = LAST_INSERT_ID();

    SET day_i = 0;
    WHILE day_i < p_habit_days DO
      SET v_habit_date = DATE_SUB(CURDATE(), INTERVAL day_i DAY);
      IF MOD(habit_i + day_i + p_user_offset, 3) <> 0 THEN
        INSERT INTO habit_checkins (habit_id, user_id, date, is_done, created_at, updated_at)
        VALUES (
          v_habit_id,
          v_user_id,
          v_habit_date,
          1,
          TIMESTAMP(v_habit_date, '08:00:00'),
          TIMESTAMP(v_habit_date, '21:00:00')
        );
      END IF;
      SET day_i = day_i + 1;
    END WHILE;
    SET habit_i = habit_i + 1;
  END WHILE;

  SET review_i = 0;
  WHILE review_i < p_review_days DO
    IF MOD(review_i + p_user_offset, 5) <> 0 THEN
      SET v_review_date = DATE_SUB(CURDATE(), INTERVAL review_i DAY);
      SET v_now = TIMESTAMP(v_review_date, '22:00:00');

      INSERT INTO daily_reviews (
        user_id, date, tomorrow_top_priority, created_at, updated_at
      ) VALUES (
        v_user_id,
        v_review_date,
        CONCAT('压测次日优先事项 - ', p_nickname, ' - D', review_i + 1),
        v_now,
        v_now
      );
      SET v_review_id = LAST_INSERT_ID();

      SET v_dimension_status_1 = ELT(MOD(review_i + p_user_offset, 3) + 1, 'GOOD', 'NORMAL', 'BAD');
      SET v_dimension_status_2 = ELT(MOD(review_i + p_user_offset + 1, 3) + 1, 'GOOD', 'NORMAL', 'BAD');
      SET v_dimension_status_3 = ELT(MOD(review_i + p_user_offset + 2, 3) + 1, 'GOOD', 'NORMAL', 'BAD');
      SET v_dimension_status_4 = ELT(MOD(review_i + p_user_offset + 3, 3) + 1, 'GOOD', 'NORMAL', 'BAD');

      INSERT INTO daily_review_items (review_id, dimension, status, comment) VALUES
        (v_review_id, 'WORK_STUDY', v_dimension_status_1, CONCAT('工作学习复盘 - ', p_nickname, ' - ', review_i + 1)),
        (v_review_id, 'HEALTH', v_dimension_status_2, CONCAT('健康复盘 - ', p_nickname, ' - ', review_i + 1)),
        (v_review_id, 'RELATIONSHIP', v_dimension_status_3, CONCAT('关系复盘 - ', p_nickname, ' - ', review_i + 1)),
        (v_review_id, 'HOBBY', v_dimension_status_4, CONCAT('兴趣复盘 - ', p_nickname, ' - ', review_i + 1));
    END IF;
    SET review_i = review_i + 1;
  END WHILE;
END$$
DELIMITER ;

CALL seed_user_dataset('test@qq.com', '压测重度用户', 50, 30, 5, 20, 180, 120, 1);

CALL seed_user_dataset('seed_medium_01@goalflow.local', '中度用户01', 12, 21, 4, 8, 90, 45, 11);
CALL seed_user_dataset('seed_medium_02@goalflow.local', '中度用户02', 12, 21, 4, 8, 90, 45, 12);
CALL seed_user_dataset('seed_medium_03@goalflow.local', '中度用户03', 12, 21, 4, 8, 90, 45, 13);
CALL seed_user_dataset('seed_medium_04@goalflow.local', '中度用户04', 12, 21, 4, 8, 90, 45, 14);
CALL seed_user_dataset('seed_medium_05@goalflow.local', '中度用户05', 12, 21, 4, 8, 90, 45, 15);
CALL seed_user_dataset('seed_medium_06@goalflow.local', '中度用户06', 12, 21, 4, 8, 90, 45, 16);
CALL seed_user_dataset('seed_medium_07@goalflow.local', '中度用户07', 12, 21, 4, 8, 90, 45, 17);
CALL seed_user_dataset('seed_medium_08@goalflow.local', '中度用户08', 12, 21, 4, 8, 90, 45, 18);

CALL seed_user_dataset('seed_light_01@goalflow.local', '轻度用户01', 4, 10, 3, 4, 30, 15, 31);
CALL seed_user_dataset('seed_light_02@goalflow.local', '轻度用户02', 4, 10, 3, 4, 30, 15, 32);
CALL seed_user_dataset('seed_light_03@goalflow.local', '轻度用户03', 4, 10, 3, 4, 30, 15, 33);
CALL seed_user_dataset('seed_light_04@goalflow.local', '轻度用户04', 4, 10, 3, 4, 30, 15, 34);
CALL seed_user_dataset('seed_light_05@goalflow.local', '轻度用户05', 4, 10, 3, 4, 30, 15, 35);
CALL seed_user_dataset('seed_light_06@goalflow.local', '轻度用户06', 4, 10, 3, 4, 30, 15, 36);
CALL seed_user_dataset('seed_light_07@goalflow.local', '轻度用户07', 4, 10, 3, 4, 30, 15, 37);
CALL seed_user_dataset('seed_light_08@goalflow.local', '轻度用户08', 4, 10, 3, 4, 30, 15, 38);
CALL seed_user_dataset('seed_light_09@goalflow.local', '轻度用户09', 4, 10, 3, 4, 30, 15, 39);
CALL seed_user_dataset('seed_light_10@goalflow.local', '轻度用户10', 4, 10, 3, 4, 30, 15, 40);
CALL seed_user_dataset('seed_light_11@goalflow.local', '轻度用户11', 4, 10, 3, 4, 30, 15, 41);
CALL seed_user_dataset('seed_light_12@goalflow.local', '轻度用户12', 4, 10, 3, 4, 30, 15, 42);

DROP PROCEDURE IF EXISTS seed_user_dataset;
DROP TEMPORARY TABLE IF EXISTS seed_user_ids;
