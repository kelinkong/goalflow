# GoalFlow

AI 驱动的目标管理 App，基于 Flutter + Hive 构建。

## 功能

- 🎯 多目标并行管理（暂停/恢复/终止）
- 📅 按日期查看任务（点击周历任意一天）
- ✅ 每日打卡 + 过去日期补打卡
- ⏩ 任务顺延（自动出现在次日）
- 🤖 AI 拆解每日任务（OpenAI 兼容接口）
- 📊 进度时间轴 + 打卡日历
- 💾 本地 Hive 存储，无需联网使用

---

## 快速开始

### 1. 配置环境变量

编辑项目根目录的 `.env` 文件：

```env
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o
```

> 如果使用其他兼容 OpenAI 格式的服务（如 Azure、Moonshot、DeepSeek 等），修改 `OPENAI_BASE_URL` 和 `OPENAI_MODEL` 即可。

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行

```bash
flutter run
```

---

## 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android / iOS / macOS / Web 均支持

---

## 项目结构

```
lib/
├── main.dart                 # 入口 + 底部导航
├── theme.dart                # 全局颜色/样式常量
├── models/
│   ├── goal.dart             # 目标模型（Hive）
│   ├── goal.g.dart           # Hive 适配器
│   ├── day_record.dart       # 每日记录模型（Hive）
│   └── day_record.g.dart     # Hive 适配器
├── services/
│   ├── hive_service.dart     # 本地数据库封装
│   ├── ai_service.dart       # AI 接口（OpenAI 格式）
│   └── app_state.dart        # 全局状态管理（Provider）
├── widgets/
│   └── common.dart           # 公共组件
└── screens/
    ├── home_screen.dart      # 首页（周历 + 任务列表）
    ├── goals_screen.dart     # 目标列表
    ├── goal_detail_screen.dart # 目标详情（今日/时间轴）
    ├── new_goal_screen.dart  # 新建目标（AI 拆解流程）
    ├── progress_screen.dart  # 进度统计
    ├── settings_screen.dart  # 设置
    └── login_screen.dart     # 登录/注册
```

---

## 数据说明

- 所有数据存储在设备本地（Hive），路径由系统分配
- `Goal`：目标基本信息 + 每日任务模板
- `DayRecord`：每天的任务完成状态，key 为 `{goalId}_{yyyy-MM-dd}`
- 顺延任务会在次日的 `DayRecord` 中自动出现

---

## AI 接口说明

`lib/services/ai_service.dart` 使用标准 OpenAI Chat Completions 格式：

```
POST {OPENAI_BASE_URL}/chat/completions
Authorization: Bearer {OPENAI_API_KEY}
```

返回格式要求（Prompt 已内置）：
```json
[{"text":"每日任务内容"},{"text":"..."}]
```

---

## 补打卡逻辑

1. 在首页点击周历中**过去的日期**
2. 查看该天任务列表，标题栏显示「可补卡」标识  
3. 直接点击任务前的复选框即可补打卡（自动标记 `isMakeup: true`）
4. 补打卡记录在目标详情时间轴中以「补卡」标签显示

## 顺延逻辑

1. 在今日任务右侧点击「顺延」按钮
2. 该任务标记为 `isDeferred: true`，`deferredTo` 设为次日
3. 次日打开首页，该任务自动出现在当天的任务列表中
