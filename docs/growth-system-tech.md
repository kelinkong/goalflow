# GoalFlow 成长系统技术设计文档

**项目名称**：GoalFlow  
**技术范围**：目标 / 习惯 / 复盘 三层模型  
**文档日期**：2026-03-26

## 一、设计目标

本次技术重构目标不是增加更多模块，而是让现有产品围绕三层模型稳定收敛：

1. 目标：结果导向
2. 习惯：长期行为导向
3. 复盘：理解导向

技术设计必须保证：

1. 数据边界清楚
2. 同一行为不被重复记录
3. 历史展示按日期聚合
4. 首页只聚焦今天

## 二、核心建模原则

## 2.1 三类核心实体

系统只维护三类核心业务对象：

1. `Goal`
2. `Habit`
3. `DailyReview`

“轨迹”不是核心实体，而是一个按日期聚合的展示视图。

## 2.2 一个行为只保留一个主归属

1. 目标任务完成，归属 `Goal`
2. 习惯完成，归属 `Habit`
3. 复盘只引用当天上下文，不重复创建行为记录

## 2.3 日期聚合是展示层，不是重复存储层

目标、习惯、复盘都按各自最自然的结构存储。
轨迹页按日期动态查询并组装，不强制引入新的“全量生活流水总表”。

## 三、现状与重构方向

## 3.1 当前已有

1. `Goal`
2. `GoalPlanItem`
3. `DayRecord`
4. `TaskRecord`
5. `DailyReview`
6. `DailyReviewItem`

## 3.2 本次新增

新增一套独立的习惯系统：

1. `Habit`
2. `HabitCheckin`

## 3.3 本次不动

1. 目标系统主流程
2. 模板、排行榜、勋章现有逻辑

这些能力可以继续存在，但不再作为产品主线扩展重点。

## 四、数据模型设计

## 4.1 Goal 体系

继续沿用现有结构：

1. `goals`
2. `goal_plan_items`
3. `day_records`
4. `task_records`

语义：

1. 目标是结果系统
2. 任务记录是目标推进过程

## 4.2 Habit 体系

建议新增两张表。

### 表一：`habits`

字段建议：

1. `id BIGINT PRIMARY KEY AUTO_INCREMENT`
2. `user_id BIGINT NOT NULL`
3. `name VARCHAR(100) NOT NULL`
4. `category VARCHAR(32) NULL`
5. `status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE'`
6. `created_at DATETIME NOT NULL`
7. `updated_at DATETIME NOT NULL`

说明：

1. 首版不做复杂频率设置
2. 首版默认为每日习惯

### 表二：`habit_checkins`

字段建议：

1. `id BIGINT PRIMARY KEY AUTO_INCREMENT`
2. `habit_id BIGINT NOT NULL`
3. `user_id BIGINT NOT NULL`
4. `date DATE NOT NULL`
5. `is_done TINYINT(1) NOT NULL DEFAULT 1`
6. `created_at DATETIME NOT NULL`
7. `updated_at DATETIME NOT NULL`

约束建议：

1. 唯一索引：`uniq_habit_date (habit_id, date)`
2. 普通索引：`idx_user_date (user_id, date)`

说明：

1. 首版采用“当日完成/未完成”二值结构
2. `is_done` 为将来保留修改空间，但首版默认只保存完成记录也可以

## 4.3 DailyReview 体系

继续使用已新增的数据结构：

1. `daily_reviews`
2. `daily_review_items`

语义：

1. 一天最多一条复盘
2. 四个固定维度
3. 三档状态
4. 备注必填

## 五、后端接口设计

## 5.1 Goal 接口

保持现有接口不变。

## 5.2 Habit 接口

建议新增控制器：

`/api/habits`

建议接口：

1. `GET /api/habits`
   - 获取习惯列表
2. `POST /api/habits`
   - 创建习惯
3. `PATCH /api/habits/{id}`
   - 编辑习惯
4. `DELETE /api/habits/{id}`
   - 删除或停用习惯
5. `PUT /api/habits/{id}/checkins/{date}`
   - 设置某天是否完成
6. `GET /api/habits/checkins?month=YYYY-MM`
   - 获取某月习惯打卡情况

## 5.3 DailyReview 接口

继续沿用当前接口：

1. `GET /api/daily-reviews/{date}`
2. `PUT /api/daily-reviews/{date}`
3. `GET /api/daily-reviews/calendar?month=YYYY-MM`

## 5.4 轨迹聚合接口

MVP 阶段有两种方案。

### 方案 A：前端聚合

由前端分别请求：

1. 目标相关数据
2. 习惯相关数据
3. 复盘数据

再在页面侧按日期组装。

优点：

1. 后端改动少
2. 便于渐进迁移

缺点：

1. 请求数更多
2. 日期详情页需要聚合逻辑

### 方案 B：后端聚合

新增：

`GET /api/timeline/{date}`

返回：

1. 当天目标任务完成情况
2. 当天习惯完成情况
3. 当天复盘内容

建议：

MVP 首版优先采用 `方案 A`，因为当前目标和复盘已存在，新增习惯后前端可较快完成聚合展示。

## 六、后端分层建议

## 6.1 Habit 模块新增文件

建议新增：

1. `entity/Habit.java`
2. `entity/HabitCheckin.java`
3. `mapper/HabitMapper.java`
4. `mapper/HabitCheckinMapper.java`
5. `dto/HabitDTO.java`
6. `dto/HabitCheckinDTO.java`
7. `dto/HabitUpsertRequest.java`
8. `service/HabitService.java`
9. `controller/HabitController.java`

## 6.2 校验规则

### Habit

1. 名称不能为空
2. 同一用户的习惯名称可允许重复，但建议前端提示避免重复
3. 仅允许访问自己的习惯

### HabitCheckin

1. 同一习惯同一天只能有一条记录
2. 只能修改自己的习惯打卡

## 七、Flutter 端模型设计

## 7.1 保留现有模型

1. `Goal`
2. `DailyReview`

## 7.2 新增模型

建议新增：

1. `Habit`
2. `HabitCheckin`

字段建议：

### Habit

1. `id`
2. `name`
3. `category`
4. `status`
5. `createdAt`

### HabitCheckin

1. `habitId`
2. `date`
3. `isDone`

## 八、Flutter 状态流设计

## 8.1 AppState 结构建议

现有：

1. `_goals`
2. `_timelineByGoal`
3. `_dailyReviewsByDate`

新增：

1. `_habits`
2. `_habitCheckinsByDate`
3. `_habitCalendarByMonth`

## 8.2 首页所需状态

首页读取：

1. 今日目标任务
2. 今日习惯完成情况
3. 今日复盘状态

## 8.3 轨迹页所需状态

轨迹页读取：

1. 目标日历摘要
2. 习惯日历摘要
3. 复盘日历摘要

点击某天后：

1. 拉取或读取该日目标任务
2. 拉取或读取该日习惯打卡
3. 拉取或读取该日复盘

## 九、页面结构建议

## 9.1 首页

展示顺序建议：

1. 日期头部
2. 今日目标
3. 今日习惯
4. 今日复盘

首页只聚焦今天，减少切换成本。

## 9.2 目标页

保持现有结构，不做大改。

## 9.3 习惯页

建议新增独立页面：

1. 习惯列表
2. 今日勾选
3. 新建习惯入口

## 9.4 复盘页

复盘页只做一件事：

1. 编辑某一天的复盘

不再放日历，不再承担历史浏览入口。

## 9.5 轨迹页

轨迹页承担日期聚合职责：

1. 月历展示
2. 点击某天查看详情
3. 详情中统一呈现目标、习惯、复盘

## 十、实现顺序建议

建议按以下顺序推进。

### 第一步

整理文档和产品口径

### 第二步

新增 Habit 后端闭环：

1. `schema.sql`
2. entity / mapper / dto
3. service / controller

### 第三步

新增 Flutter Habit 模块：

1. model
2. ApiService
3. AppState
4. 习惯页

### 第四步

调整首页聚合：

1. 今日目标
2. 今日习惯
3. 今日复盘

### 第五步

升级轨迹页：

1. 点击日历查看当天聚合详情

## 十一、验收标准

1. 用户能在产品内明确区分目标、习惯、复盘
2. 目标、习惯、复盘三套数据边界清晰
3. 首页能完成今日记录
4. 轨迹页能回看某一天的完整生活信息
5. 复盘页不再重复承担打卡职责
6. 不会因为模块重复导致同一行为被要求多次记录

