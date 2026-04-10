# 高并发性能压测与瓶颈分析方案 (GoalFlow)

本项目旨在通过科学的压测手段，探索后端系统的极限性能，并学习如何在高并发场景下定位并优化性能瓶颈。

## 1. 核心性能指标 (KPIs)

在进行任何压测前，必须明确以下三个核心指标：

| 指标 | 说明 | 关注点 |
| :--- | :--- | :--- |
| **TPS (Transactions Per Second)** | 系统每秒处理的事务/请求数 | 反映系统的吞吐能力上限 |
| **RT (Response Time)** | 响应时间 (重点关注 P95, P99) | 95% 或 99% 的请求耗时，反映用户感知的稳定性 |
| **Error Rate** | 错误率 (如 5xx, Timeout) | 系统在负载下的可靠性 |

## 2. 工具链选型

### 2.1 压力发起端: k6 (推荐)
*   **理由:** 基于 JavaScript 编写脚本，现代、轻量、支持高并发、易于集成。
*   **安装:** `brew install k6` (本地或压测机)。

### 2.2 性能监控与诊断: Arthas (阿里开源)
*   **理由:** Java 诊断利器，无需重启即可实时查看方法调用耗时、CPU 占用、内存状态。
*   **关键命令:**
    *   `dashboard`: 整体运行快照。
    *   `trace`: 追踪方法内部每一行的耗时。
    *   `profiler`: 生成 CPU 火焰图 (Flame Graph)。

### 2.3 基础设施监控
*   **docker stats:** 观察容器层面的 CPU/内存。
*   **MySQL Slow Query Log:** 识别慢 SQL。
*   **HikariPool Metrics:** 监控数据库连接池状态。

## 3. 压测场景设计

### 场景 A：高频读 (Read-Heavy)
*   **接口:** `GET /api/goals`
*   **目标:** 测试目标列表查询、计划项组装、Nginx 转发与应用层读吞吐能力。

### 场景 B：并发写 (Write-Heavy)
*   **接口:** `POST /api/goals/{id}/checkin`
*   **目标:** 测试任务打卡时的读写组合、并发更新、数据库锁竞争、连接池回收速度。

## 3.1 当前项目接口压测优先级

不是所有接口都值得优先压测。应先压高频核心链路和高成本链路，再补低频管理接口。

### P0：第一批必须压测

#### 1. `GET /api/goals`
*   **为什么重要:** 登录后和页面初始化时会直接拉取目标列表。
*   **后端成本:** 先查 `goals`，再批量查 `goal_plan_items`，最后在内存中组装 `taskPlan`。
*   **适合测试什么:** 基础读吞吐、P95/P99 响应时间、MySQL 查询效率。

#### 2. `GET /api/goals/{id}/timeline`
*   **为什么重要:** 这是进度详情页和任务视图的核心接口，复杂度明显高于普通列表。
*   **后端成本:** 会读取目标、计划项、`day_records`、`task_records`，并做 deferred 任务合并、排序和 DTO 组装。
*   **适合测试什么:** 聚合查询性能、对象组装开销、慢 SQL 风险。

#### 3. `POST /api/goals/{id}/checkin`
*   **为什么重要:** 这是典型的高频写接口。
*   **后端成本:** 查目标、查或创建 `day_record`、查或创建 `task_record`，最后重新统计目标完成状态。
*   **适合测试什么:** 并发写稳定性、事务冲突、数据库热点更新、应用层幂等性。

#### 4. `POST /api/goals/{id}/defer`
*   **为什么重要:** 和打卡同类，同样会修改任务状态和目标衍生状态。
*   **后端成本:** 与 `checkin` 接近，也会触发多次读写。
*   **适合测试什么:** 并发写、状态切换正确性、异常回滚。

#### 5. `PUT /api/habits/{id}/checkins/{date}`
*   **为什么重要:** 习惯打卡属于日常高频操作。
*   **后端成本:** 查习惯、查当日打卡记录，随后进行插入、更新或删除，再更新习惯 `updated_at`。
*   **适合测试什么:** 轻量事务写入性能、唯一键冲突、热点行更新。

### P1：第二批建议压测

#### 6. `GET /api/habits`
*   **为什么重要:** 首页会读取习惯列表。
*   **后端成本:** 先查 active habits，再查所有已完成 checkins 并按 habit 聚合。
*   **适合测试什么:** 中等规模用户数据下的列表读取性能。

#### 7. `GET /api/habits/checkins?month=yyyy-MM`
*   **为什么重要:** 月历视图会频繁请求。
*   **后端成本:** 按月份扫描 `habit_checkins`，再回表加载 habits。
*   **适合测试什么:** 范围查询、月度聚合查询性能。

#### 8. `PUT /api/daily-reviews/{date}`
*   **为什么重要:** 每日复盘属于事务型写操作。
*   **后端成本:** 已存在记录时会 `update` 主表、`delete` 子表、再 `insert` 4 条维度项。
*   **适合测试什么:** 小事务写入、删除再插入模式的稳定性。

#### 9. `GET /api/daily-reviews/calendar?month=yyyy-MM`
*   **为什么重要:** 复盘月历是中频读接口。
*   **后端成本:** 按月读取复盘主记录，返回已复盘日期列表。
*   **适合测试什么:** 轻量范围查询性能。

### P2：单独隔离测试，不混入主压测

#### 10. `POST /api/goals/decompose`
*   **为什么重要:** 这是明显的外部依赖型接口。
*   **后端成本:** 调用第三方 AI 服务，瓶颈主要不在 JVM 和 MySQL，而在外部 API RT、限流、网络稳定性。
*   **适合测试什么:** 超时策略、熔断、降级、外部依赖失败时系统行为。
*   **注意:** 不要把它和普通 CRUD 接口混在一起做吞吐测试，否则数据没有解释价值。

### P3：低优先级或专项测试

#### 11. `POST /api/auth/login`
*   **用途:** 登录风暴、认证链路基准。
*   **说明:** 需要测，但不应作为第一批核心业务压测接口。

#### 12. `GET /api/auth/me`
*   **用途:** 校验登录态场景下的基础鉴权开销。
*   **说明:** 成本低，适合作为对照组。

#### 13. `POST /api/goals` / `PATCH /api/goals/{id}`
*   **用途:** 创建与编辑目标的普通业务写操作。
*   **说明:** 中低频，不优先。

#### 14. `DELETE /api/goals/{id}`
*   **用途:** 删除链路专项测试。
*   **说明:** 因为存在业务级联删除，可单独做大数据量删除测试。

#### 15. `GET /api/account/export`
*   **用途:** 大响应体导出专项测试。
*   **说明:** 会把 goals、dayRecords、taskRecords 一起导出，适合测大对象序列化和带宽占用，但不是常规高频流量。

#### 16. `DELETE /api/account/history`
*   **用途:** 历史清理专项测试。
*   **说明:** 低频但重操作，可用于测级联删除、长事务和峰值风险。

#### 17. `/api/admin/*`
*   **用途:** 管理台专项测试。
*   **说明:** 开发阶段通常不是主流量入口，不建议优先压。

## 3.2 压测入口选择

默认应压 Nginx 入口，而不是直接压 Spring Boot 端口。

### 推荐顺序
1. `http://127.0.0.1:8080/api`
   *   **用途:** 绕过 Cloudflare，直接压源站 Nginx。
   *   **价值:** 更适合学习应用和 Nginx 自身瓶颈。
2. `https://goalflow.kelin.qzz.io/api`
   *   **用途:** 模拟真实线上访问路径。
   *   **价值:** 可观察 Cloudflare、TLS、公网链路带来的影响。
3. `http://<server>:8081/api`
   *   **用途:** 仅用于排查时压 Spring Boot 本体。
   *   **价值:** 判断瓶颈在 Nginx/网络层还是后端应用/数据库层。

### 结论
*   **主压测:** 压 Nginx 入口。
*   **辅助定位:** 压 8081。

## 3.3 分阶段压测路线

### 第一阶段：基线读性能
*   `GET /api/goals`
*   目标：得到单接口基础 RT、TPS、错误率。

### 第二阶段：复杂聚合读
*   `GET /api/goals/{id}/timeline`
*   `GET /api/habits/checkins?month=yyyy-MM`
*   目标：识别查询聚合和 DTO 组装瓶颈。

### 第三阶段：高频写
*   `POST /api/goals/{id}/checkin`
*   `POST /api/goals/{id}/defer`
*   `PUT /api/habits/{id}/checkins/{date}`
*   `PUT /api/daily-reviews/{date}`
*   目标：识别事务冲突、连接池排队、慢 SQL、行锁竞争。

### 第四阶段：重接口专项测试
*   `POST /api/goals/decompose`
*   `GET /api/account/export`
*   `DELETE /api/account/history`
*   目标：识别外部依赖、超大响应体、长事务与删除风暴。

## 3.4 建议的压测组合

### 组合 A：真实用户日常流量
*   60% `GET /api/goals`
*   20% `GET /api/goals/{id}/timeline`
*   10% `POST /api/goals/{id}/checkin`
*   10% `PUT /api/habits/{id}/checkins/{date}`

### 组合 B：任务操作高峰
*   40% `POST /api/goals/{id}/checkin`
*   30% `POST /api/goals/{id}/defer`
*   30% `PUT /api/habits/{id}/checkins/{date}`

### 组合 C：月度视图切换
*   50% `GET /api/habits/checkins`
*   50% `GET /api/daily-reviews/calendar`

### 组合 D：隔离型重接口
*   100% `POST /api/goals/decompose`
*   或 100% `GET /api/account/export`
*   或 100% `DELETE /api/account/history`

## 3.5 压测时的观测点

压测时至少同时观察以下数据：

*   `k6`：TPS、P95、P99、错误率
*   `docker stats`：`nginx`、`backend`、`mysql` 的 CPU/内存
*   后端日志：接口 RT、异常、超时
*   MySQL：慢查询、连接数、锁等待
*   Nginx 日志：499、502、504、连接中断

## 3.6 执行原则

*   先单接口，再混合场景，不要一开始就混压。
*   先压源站 Nginx，再压真实域名，不要把 Cloudflare 干扰和应用瓶颈混在一起。
*   外部 AI 接口单独压，不要把第三方 RT 混入系统主链路结论。
*   先建立基线，再做优化，再复测，不要只看一次压测结果。

## 3.7 k6 环境变量

项目已提供默认环境文件：

*   `scripts/k6/.env`

包含以下变量：

*   `BASE_URL`
*   `LOGIN_EMAIL`
*   `LOGIN_PASSWORD`
*   `REQUEST_TIMEOUT`
*   `AI_TIMEOUT`

推荐执行方式：

```bash
cd goalflow
set -a
source scripts/k6/.env
set +a
k6 run scripts/k6/01-goals-list.js
```

其他脚本同理：

```bash
k6 run scripts/k6/02-goal-timeline.js
k6 run scripts/k6/03-task-actions.js
k6 run scripts/k6/04-habit-checkins.js
k6 run scripts/k6/05-daily-review.js
k6 run scripts/k6/06-goal-decompose.js
k6 run scripts/k6/07-account-export.js
```

## 4. 分析流程 (Methodology)

1.  **基准测试 (Baseline):** 1 个并发用户，运行 1 分钟，获取最理想状态下的 RT。
2.  **梯度加压 (Step Load):**
    *   10 -> 50 -> 100 -> 200 -> 500 并发。
    *   观察 TPS 是否随并发数线性增长。
3.  **寻找拐点:**
    *   当 TPS 不再增长，或 RT 开始指数级上升，即达到性能拐点。
4.  **瓶颈定位:**
    *   **CPU 100%:** 检查死循环、频繁 GC、线程竞争。
    *   **RT 变长但 CPU 低:** 检查 I/O 等待 (磁盘/网络)、数据库锁等待、连接池排队。
    *   **内存持续上升:** 检查内存泄漏 (Memory Leak)。

## 5. 常见优化方向

*   **JVM 层:** 调整堆大小 (`-Xms`, `-Xmx`)，优化垃圾回收器 (G1/ZGC)。
*   **应用层:** 引入缓存 (Redis)、异步处理 (消息队列)、线程池参数调优。
*   **数据库层:** 增加索引、SQL 优化、读写分离、分库分表。
*   **架构层:** Nginx 负载均衡、限流熔断 (Sentinel)。
