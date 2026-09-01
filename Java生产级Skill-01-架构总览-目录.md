# Java 生产级 Skill · 01 架构选型

> **固定一套**：业务模块分包 + 模块内 MVC 三层（单体）——个人开发与生产同规。  
> 正文：`Java生产级Skill-01-架构.md`。  
> DDD / 六边形 / CQRS / 微服务 / Maven 多模块硬隔离：本期不进主路径。

---

## 1. 定论（调研后）

企业里常把两件事混成一句「我们用 MVC」：

| 问题 | 企业真实共识 |
|------|----------------|
| **调用链怎么走？** | 几乎都是 `Controller → Service → Mapper`（阿里手册的 Web/Service/DAO 也是在说这个） |
| **顶级包怎么切？** | 有争议；**生产级该选「先业务、后层」** |

**本 Skill 只保留一套：**

```text
module.{业务}/controller|service|dto  +  共用 config/security/common（± biz）
```

不保留「全项目顶级 controller/service/mapper」作为并列方案。

---

## 2. 依据（简表）

| 来源 | 实际在推什么 |
|------|----------------|
| [Spring Petclinic](https://github.com/spring-projects/spring-petclinic) | 早已按 **owner / vet / system** 等业务包组织，不是全局一层一包 |
| [Spring Modulith](https://docs.spring.io/spring-modulith/reference/fundamentals.html) + [JetBrains 迁移文](https://blog.jetbrains.com/idea/2026/02/migrating-to-modular-monolith-using-spring-modulith-and-intellij-idea/) | 明确：**避免 package-by-layer**；按 feature/module 切，否则易成泥球 |
| 业界常见结论（DEV/实践文） | 小 Demo 可按层；**多域、多人、要长期养 → 按业务** |
| [阿里巴巴 Java 开发手册 · 应用分层](https://alibaba.github.io/p3c/%E5%B7%A5%E7%A8%8B%E7%BB%93%E6%9E%84/%E5%BA%94%E7%94%A8%E5%88%86%E5%B1%82.html) | 规定的是**层职责**（Web/Service/Manager/DAO），**没有**规定顶级必须全局 `controller/` 一锅炖 |
| 若依等国内脚手架 | 常见「多 Maven 模块 + 生成器按层吐代码」→ **市面上很多**，不等于「企业级最优」；单域 CRUD 脚手架路径 |

**别把「常见」当成「该学的」：**  
国内大量中后台、代码生成器默认全局按层——好抄、好教；一旦多业务域，同类文件横摊、归属靠前缀，这是已知痛点。  
Spring 官方样例与 Modulith 路线站在**按业务分包**一侧。

---

## 3. Agent 口令

1. 新项目 / vibecoding：**直接按业务模块 + 模块内 MVC** 搭（见 `01-架构.md`）。  
2. 禁止主动改成「只有一套全局 controller/service/mapper」当规范。  
3. 用户仓库若已是全局按层：可维持并局部收敛；**新代码优先往业务包靠**，不整库为搬家而搬家。  
4. 未点名：不上 DDD / 六边形 / 微服务「先拆再说」。

---

## 4. 本期不进主路径

| 名字 | 说明 |
|------|------|
| 纯按层大包（全局 MVC 目录） | 仅作遗留/超小 Demo 现实，不写进推荐正文 |
| 模块化单体（多模块构建硬隔离） | 与「业务分包」不同；以后单开 |
| DDD / 六边形 / CQRS / 事件 / 微服务 | 非本阶段 |

---

## 附录 · 目录

1. 定论  
2. 依据  
3. Agent 口令  
4. 不进主路径  
