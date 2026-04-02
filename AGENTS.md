# AGENTS.md

请使用第一性原理思考。你不能总是假设我非常清楚自己想要什么和该怎么得到。请保持审慎，从原始需求和问题出发，如果动机和目标不清晰，停下来和我讨论。如果目标清晰但是路径不是最短，告诉我，并且建议更好的办法。

## 技术栈

- 用户端：Flutter / Dart
- 管理台前端：Vue 3、Vue Router 4、Axios、Vite 5
- 后端：Java 17、Spring Boot、Spring Security、MyBatis-Plus、MySQL、JWT、Maven

## 项目结构

```text
goalflow/
├── AGENTS.md
├── docker-compose.yml
├── nginx.conf
├── admin_console/            # 管理台前端
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

- 使用 `ssh <your-server>` 连接远程服务器。
- 默认部署目录：`~/goalflow`
- 服务器通过 Cloudflare 对外暴露，Cloudflare 转发到服务器 `80` 端口。防火墙开放了8080端口
- 部署使用 Docker Compose。
- 当前静态前端目录：`~/goalflow/www`
- 当前后端 jar 路径：`~/goalflow/app/app.jar`

常用命令：

```bash
cd ./admin_console && npm run build
cd ./backend/goalflow-api && mvn package -DskipTests
tar -C ./admin_console/dist -cf - . | ssh <your-server> 'tar -C ~/goalflow/www -xf -'
ssh <your-server> 'cat > ~/goalflow/app/app.jar' < ./backend/goalflow-api/target/goalflow-api-1.0.0.jar # 直接上传 jar 包
ssh <your-server> 'docker restart backend' # 仅仅启动后端
ssh <your-server> 'cd ~/goalflow && docker-compose down && docker-compose up -d' # 重启整个服务
```

部署后至少验证：

- 前端是否引用了最新静态资源
- 是否残留旧静态资源
- 后端容器是否成功重启
- 关键接口是否正常
- 数据库缺列问题是否已真正修复
- 相关文档是否更新
