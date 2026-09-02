# Java 生产级 Vibecoding · 规范索引

> 目录：`Java-生产级规范/`（本套规范均在此文件夹）。  
> 尚未打包成 Cursor `SKILL.md` 时，以本篇为总入口。  
> 用法：先看「何时读哪篇」，再打开对应 md；不要一次塞进所有长文。

---

## 何时读哪篇

| 时机 | 读哪篇 | 解决什么 |
|------|--------|----------|
| 新建项目 / 定包结构 / 类放哪 / 模块怎么调 | [`Java-代码架构.md`](Java-代码架构.md) | 目录、依赖方向、跨模块调用 |
| 写各层代码；API 契约；Stream/并发/模式等 | [`Java-模块代码规范.md`](Java-模块代码规范.md) | 分层写法 + Java 通用红线（含 Controller 契约） |
| 打日志、写注释（含 emoji） | [`Java-日志与注释规范.md`](Java-日志与注释规范.md) | 日志与注释 |
| 调用 Redis / HTTP / MQ / 第三方 | [`Java-外部调用规范.md`](Java-外部调用规范.md) | 超时、重试、幂等、缓存与消息写法 |
| Spring 注入、代理事务、Web/Bean 习惯 | [`Java-Spring规范.md`](Java-Spring规范.md) | 框架用法 |
| yml、profile、密钥、构建诚实性 | [`Java-配置与工程规范.md`](Java-配置与工程规范.md) | 配置与工程 |
| Spring Security | [`Java-SpringSecurity规范.md`](Java-SpringSecurity规范.md) | **占位**；暂无强制条文 |
| 旧大手册 / 项目踩坑原稿 | 仓库根目录素材（若有） | **非日常入口** |

---

## 推荐阅读顺序（新项目）

```text
1. 本索引
2. Java-代码架构.md
3. Java-模块代码规范.md      ← 含 API 契约（Controller）
4. Java-日志与注释规范.md
5. 按需：Spring / 配置与工程 / 外部调用
6. Spring Security：暂不读（占位）
```

---

## Agent / 人使用约定

1. **先索引、再按需打开**，禁止无差别加载全部 md。  
2. 冲突时：以更具体、更新近的篇章为准，并回头改索引。  
3. 管**代码怎么写**，不替代产品/业务决策。  
4. 将来收成 Cursor Skill 时：本索引职责通常由 **`SKILL.md`** 承担。

---

## 文档地图

```text
Java-生产级规范/
├── Java-规范索引.md              ← 你在这里
├── Java-代码架构.md
├── Java-模块代码规范.md
├── Java-日志与注释规范.md
├── Java-外部调用规范.md
├── Java-Spring规范.md
├── Java-配置与工程规范.md
└── Java-SpringSecurity规范.md  ← 占位
```
