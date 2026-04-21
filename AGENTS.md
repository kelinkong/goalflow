# AGENTS.md

文档先行 (Docs First)：在进行任何代码改动前，必须优先检查 docs/ 或相关文档是否需要更新。先提交文档修改建议，再执行代码开发。

拒绝假设：如果你不确定 goalflow 的业务动机，停下来询问。

手术刀原则：只修改与任务相关的行。严禁大规模重构、修改无关格式或删除非你产生的代码。

极简主义：如果 50 行代码能解决问题，不要写 200 行。拒绝过度设计和不必要的配置化。

路径最短：如果我给出的路径不是最优的，请推翻我并建议更好的办法

## 技术栈

- 用户端：Flutter / Dart
- 后端：Java 17、Spring Boot、Spring Security、MyBatis-Plus、MySQL、JWT、Maven

## 项目结构

```text
goalflow/
├── AGENTS.md
├── docker-compose.yml
├── nginx.conf
├── backend/
│   ├── pom.xml               # 后端父工程
│   └── goalflow-api/         # 后端 API
├── lib/                      # Flutter 业务代码
├── assets/
├── docs/
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
└── web/
```

## 项目规范

- 优先做小而完整的修复，不要只修表面现象。
- 涉及登录、权限、审核、后台统计时，必须同时检查前端、后端、数据库 schema、线上部署是否一致。
- 数据库表多为逻辑关联，不要假设会自动级联删除。删除用户、模板、目标前先查关联数据, 数据库不要做外键关联，使用业务代码保证数据同步。
- 如果新增实体字段或审核字段，必须同步检查 Java 实体、查询逻辑、`schema.sql` 和线上数据库是否已补列。
- 管理台 API 走 `/api`，由 Nginx 反向代理到后端。
- 当前还属于开发阶段，不需要考虑兼容性

## 部署方式

- 使用 `ssh tencent` 连接远程服务器。
- 默认部署目录：`~/goalflow`
- 服务器通过 Cloudflare 对外暴露，Cloudflare 转发到服务器 `80` 端口。防火墙开放了8080端口
- 部署使用 Docker Compose。
- 当前静态前端目录：`~/goalflow/www`
- 当前后端 jar 路径：`~/goalflow/app/app.jar`

常用命令：
- 使用 `ssh tencent` 连接远程服务器。
...

ssh tencent 'cat > ~/goalflow/app/app.jar' < backend/goalflow-api/target/goalflow-api-1.0.0.jar # 直接上传 jar 包
ssh tencent 'docker restart backend' # 仅仅启动后端
ssh tencent 'cd ~/goalflow && docker-compose down && docker-compose up -d' # 重启整个服务

```

部署后至少验证：

- 前端是否引用了最新静态资源
- 是否残留旧静态资源
- 后端容器是否成功重启
- 关键接口是否正常
- 数据库缺列问题是否已真正修复
- 相关文档是否更新
