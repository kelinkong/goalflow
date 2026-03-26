# GoalFlow

GoalFlow 是一个围绕个人成长设计的记录系统。

它只回答三个核心问题：

1. `目标`
你想做成什么事？

2. `习惯`
你想成为哪一种人？

3. `复盘`
你如何理解自己的生活？

产品目标不是记录更多内容，而是用尽量低的记录成本，帮助用户持续推进结果、塑造长期身份、理解自己的生活轨迹。

## 当前产品方向

GoalFlow 当前围绕三条主线收敛：

1. `目标`
结果导向的事项，可以拆解为任务并按日推进。

2. `习惯`
长期重复、塑造身份的行为，按天记录完成情况。

3. `复盘`
对当天状态、行动和意义的理解，不重复承担行为打卡职责。

历史回看统一通过“轨迹”按日期聚合展示：

1. 当天完成了哪些目标任务
2. 当天完成了哪些习惯
3. 当天写了什么复盘

## 技术栈

### 用户端

1. Flutter
2. Dart
3. Provider
4. HTTP

### 管理台

1. Vue 3
2. Vue Router 4
3. Axios
4. Vite 5

### 后端

1. Java 17
2. Spring Boot
3. Spring Security
4. MyBatis-Plus
5. MySQL
6. JWT
7. Maven

## 当前能力

### 目标

1. 创建目标
2. AI 拆解目标任务
3. 查看目标时间线
4. 每日打卡
5. 补卡
6. 顺延任务

### 模板与排行

1. 模板创建与使用
2. 模板榜单
3. 后台模板审核

### 账号体系

1. 注册
2. 登录
3. 用户态数据拉取

### 复盘

1. 每日复盘记录
2. 四个固定维度
3. 明日最重要的事
4. 轨迹页按日期查看复盘摘要

习惯模块已经进入正式产品方案，但尚未完整实现。

## 文档

产品与技术的最新方案文档在 [docs/growth-system-requirements.md](./docs/growth-system-requirements.md) 和 [docs/growth-system-tech.md](./docs/growth-system-tech.md)。

如果文档与旧代码、旧截图、旧描述存在冲突，以这两份文档为准。

## 快速开始

### 1. 配置客户端环境变量

项目根目录 `.env`：

```env
API_BASE_URL=http://127.0.0.1:8081
```

如果需要连接远程环境，可替换为实际线上地址。

### 2. 启动后端

```bash
cd ./backend
mvn -pl goalflow-api spring-boot:run -DskipTests
```

默认端口：

```text
http://127.0.0.1:8081
```

### 3. 启动 Flutter

```bash
cd .
flutter pub get
flutter run
```

如果本机没有移动端模拟器，可以先用 Web：

```bash
flutter run -d web-server --web-port 3001 --dart-define=API_BASE_URL=http://127.0.0.1:8081
```

## 目录结构

```text
goalflow/
├── README.md
├── docs/
│   ├── growth-system-requirements.md
│   └── growth-system-tech.md
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── admin_console/
└── backend/
    ├── pom.xml
    └── goalflow-api/
```

## 当前设计原则

1. 一个行为只记录一次
2. 目标、习惯、复盘三层边界清楚
3. 首页只聚焦今天
4. 轨迹页统一承担历史回看
5. 避免冗余模块和平行概念

## 部署

常用后端部署命令：

```bash
cd ./backend && mvn -pl goalflow-api package -DskipTests
ssh <your-server> 'cat > ~/goalflow/app/app.jar' < ./backend/goalflow-api/target/goalflow-api-1.0.0.jar
ssh <your-server> 'cd ~/goalflow && docker compose restart backend'
```

部署后至少验证：

1. 后端容器是否正常启动
2. 关键接口是否正常
3. 数据库 schema 是否已同步

