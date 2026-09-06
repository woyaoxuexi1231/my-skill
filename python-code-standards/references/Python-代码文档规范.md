# Python 代码文档规范

> 范围：给**已有 Python 后端 / 服务**补高质量文档与可观测缺口。  
> **默认只改注释、docstring、文档产物，以及符合规则的可观测日志**——不改行为、架构、API、实现。  
> 新写代码的日志注释标准见 [`Python-日志与注释规范.md`](Python-日志与注释规范.md)。

**适用**：`.py` 服务代码、FastAPI / Django / Flask、Pydantic / ORM、Alembic/迁移意图、鉴权、REST/WS、asyncio / Celery 等。  
**不适用**：前端、Java、纯脚本/CLI（除非明确属于同一后端服务的管理命令 / worker）。

---

## 1. 核心使命

> **先理解再文档；禁止对着单行瞎写注释。**

把难懂的实现变成能回答：这是什么、为何存在、怎么协作、假设与边界是什么、改之前必须知道什么。

---

## 2. 默认禁止改动

除非用户明确要求，否则禁止：

- 重构 / 重命名 / 改 API 契约 / 改业务逻辑 / 改 ORM SQL 语义  
- 改配置默认值、换 sync↔async、class↔函数互转  
- 引入新依赖或新抽象（可观测性所需的 `logger = logging.getLogger(__name__)` 除外，且须符合项目既有风格）  
- 「顺手」修无关 bug、做性能优化  

发现严重问题 → **写入 Important Findings**，不静默改行为。

---

## 3. 理解优先

文档前先摸清：

- 入口（`main` / ASGI / `manage.py`）、settings、路由/视图、service、repository/ORM  
- Depends / 中间件、鉴权边界、事务归属、外部系统、任务队列、既有日志风格  

跟真实模块边界走；**不要臆造 Java 式 ServiceImpl 层**。

典型流：

```text
Router/WS → Depends(auth, db) → Service → Repository/ORM → DB
```

---

## 4. 文档层次

```text
项目说明（仅缺失且必要时）
  → 包 / 模块 docstring
  → 类 / Protocol / 重要 Pydantic / settings
  → 公开或重要函数
  → 1️⃣2️⃣3️⃣ 阶段标记 + 非显然 WHY
  → 魔法值 / 特殊分支
```

优先 docstring 表契约；行间注释表阶段与决策。不要逐行注释。

Docstring 风格跟项目；无约定时后端优先 Google 风格。

---

## 5. 必须补的内容类型

| 类型 | 要点 |
|------|------|
| 业务规则 | 领域语言解释 if/else 为何如此 |
| 数据流 | Schema ↔ Domain ↔ Persistence 的有意义转换 |
| 外部调用 | 为何调、失败/超时/重试/幂等 |
| 错误处理 | 捕获/转译原因、HTTP/WS 映射、是否故意宽捕 |
| 安全 | 认证≠鉴权、所有权校验、密钥与 SSRF 等意图 |
| 并发 | 锁、多 worker、asyncio、全局可变是否安全 |
| 事务 | 谁 commit、原子边界、`FOR UPDATE` 意图 |
| 配置 | 为何存在、运维/安全含义（勿教框架用法） |
| 魔法值 | 协议/遗留含义；无授权不重构为枚举 |
| Workaround | 保留原因；不确定就写「原因在实现中不明确」 |
| Worker | 触发、幂等、重试、不可跑两次的点 |
| 测试 | 表达重要规则的测试用 docstring 说明意图 |

---

## 6. 阶段标记与日志（文档任务内）

### 6.1 1️⃣ 2️⃣ 3️⃣

多步函数补中文阶段标题（规则同日志注释规范）。一步函数不强制。

### 6.2 日志

文档任务同时处理可观测性：

1. **解释**已有日志（级别、id、故意省略什么）。  
2. **补缺口**：关键路径无日志、模块已有（或邻模块统一用）stdlib logger 时，可加**纯可观测**日志。  
3. 不确定会否泄密 → **不加**，记入 Findings。  
4. 不改控制流 / 返回值 / 异常类型；不引入新日志框架。

---

## 7. 置信度

| 级别 | 写法 |
|------|------|
| 已确认 | 由代码/配置/测试/既有文档支撑 |
| 强推断 | 可说明推断依据 |
| 不清楚 | 写「当前实现未明确原因」，禁止装权威 |

禁止把猜测写成事实。

---

## 8. 优先级（大项目）

```text
1 入口与包架构
2 安全 / 鉴权（含 deny/allow 日志）
3 核心业务服务（docstring + 1️⃣2️⃣3️⃣ + 结果日志）
4 资金 / 结算 / ledger
5 公开 REST / WebSocket
6 事务与并发关键路径
7 关键 worker
8 重要领域模型
9 复杂 ORM/SQL
10 外部集成
11 配置
12 utils
13 琐碎 schema / 一行 helper
```

生成代码 / 第三方 stub：标生成边界，勿海量手写注释。

---

## 9. 工作流

1. **发现**：布局、入口、settings、安全、核心流、日志风格——先别插注释。  
2. **建模**：入口 → 中间件/Depends → 路由 → 服务 → 持久化/外部。  
3. **按优先级文档化**。  
4. **一致性复核**：术语、与行为一致、无逐行噪音、无泄密日志。  
5. **行为核对**：除注释/docstring/合规日志外无语义变化。

---

## 10. 完成时输出

### Documentation Summary

- 覆盖区域 / 重要流 / 有意跳过

### Statistics（勿编造）

```text
Files analyzed / modified
Modules / Classes / Functions documented
Step markers added
WHY comments added
Logs documented / added
Observability gaps reported
```

### Important Findings

- 不清业务、可疑实现、潜在 bug、架构/安全问题、缺测、危险日志、async 中阻塞等——只报告，默认不修。

---

## 11. 最终原则

> 理解先于文档 · 文档意图而非语法 · 多步函数要 1️⃣2️⃣3️⃣  
> 步骤说阶段 WHAT，决策说 WHY · 安全/事务/资金/worker 要显式说明与日志  
> 不发明需求 · 不静默改行为 · 不制造注释污染 · 不把 Java 叙事硬套 Python  
> 目标是让后人能安全地改、能运维——不是注释行数更多。
