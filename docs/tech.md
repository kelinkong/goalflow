# 技术文档（现状 + 规划）

**技术栈**
1. 客户端：Flutter
1. 本地存储：Hive
1. AI 服务：OpenAI 兼容接口
1. 规划后端：Spring Boot

**一、当前架构（本地模式）**
1. 数据层
1. Hive 存储 Goal、DayRecord、TaskRecord
1. 本地生成逐日任务计划并写入记录
1. 业务层
1. AppState 负责目标列表、记录读取与更新
1. 进度口径：完成任务数 / 总任务数
1. UI 层
1. 首页、目标页、进度页共享统一进度计算

**二、核心数据模型（本地）**
1. Goal
1. id、name、emoji、desc、totalDays、status、createdAt
1. taskPlan：逐日任务列表
1. DayRecord
1. goalId、date、dayNumber、tasks
1. TaskRecord
1. taskText、isDone、isDeferred、doneAt

**三、后端引入后的总体架构**
1. 客户端
1. 登录与鉴权
1. 本地缓存 + 远端同步
1. 服务端（Spring Boot）
1. 用户与认证
1. 目标与任务计划管理
1. 打卡与补卡记录
1. 模板与排行榜
1. 勋章与分享图生成

**四、服务端数据模型（建议）**
1. User
1. id、nickname、avatar、email/phone、createdAt
1. Goal
1. id、userId、name、desc、status、totalDays、createdAt
1. GoalPlan
1. id、goalId、dayNumber、tasks
1. Checkin
1. id、userId、goalId、date、taskIndex、isMakeup、createdAt
1. Template
1. id、ownerId、name、desc、totalDays、visibility、tags
1. TemplatePlan
1. id、templateId、dayNumber、tasks
1. TemplateUsage
1. id、templateId、userId、goalId、joinRanking、createdAt
1. Ranking
1. id、templateId、userId、progressPercent、updatedAt
1. Medal
1. id、userId、goalId、title、awardedAt

**五、服务端接口（建议）**
1. 认证
1. POST /api/auth/login
1. POST /api/auth/logout
1. GET /api/auth/me
1. 目标
1. POST /api/goals
1. GET /api/goals
1. GET /api/goals/{id}
1. PATCH /api/goals/{id}
1. 打卡与补卡
1. POST /api/checkins
1. POST /api/checkins/makeup
1. GET /api/checkins?goalId&month
1. 模板
1. POST /api/templates
1. GET /api/templates
1. GET /api/templates/{id}
1. POST /api/templates/{id}/publish
1. 排行榜
1. GET /api/templates/{id}/ranking
1. 勋章
1. GET /api/medals
1. 分享
1. POST /api/share/goal/{id}

**六、进度计算口径（统一）**
1. totalTasks = 计划中所有任务总数
1. doneTasks = 打卡记录中完成的任务数
1. progress = doneTasks / totalTasks
1. progressPercent = round(progress * 100)
1. 三个页面统一使用该口径

**七、补卡限制**
1. 每月补卡次数上限 2
1. 服务端校验月度补卡次数
1. 超限返回明确错误码与提示

**八、分享图生成（建议实现）**
1. 服务端生成图片并返回 URL 或二进制
1. 图片内容：目标名称、进度、连续天数、日期区间
1. 客户端可保存到相册或系统分享

**九、同步策略（建议）**
1. 客户端本地写入后立即上报
1. 登录后拉取远端数据并合并
1. 冲突策略以服务端为准
