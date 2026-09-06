---
name: python-code-standards
description: >-
  Python 生产级编码与工程规范：架构与模块划分、分层写法、持久化与异步、外部调用、
  日志与中文注释、构建与测试；以及为已有后端补文档。编写、审查、重构或文档化
  Python 后端（FastAPI/Django/Flask 等）时调用。
---

# Python 生产级编码与工程规范

按项目既定的一组 Python 规范编写、审查、重构或文档化代码。规范为**整包交付物**，不是临时建议。

## 使用方式

按任务类型从 `references/` 挑对应文档精读，再落地代码或审查：

| 你要做的事 | 精读文档 |
|------------|----------|
| 定架构 / 分包 / 谁调谁 / 复杂度匹配 | `Python-代码架构.md` |
| 写 Router/Service/Repository、类型、DB、异步、安全、外部调用 | `Python-模块代码规范.md` |
| 打日志、写中文注释 / 1️⃣2️⃣3️⃣ / docstring | `Python-日志与注释规范.md` |
| 配置密钥、依赖、格式化 Lint、测试、交付清单 | `Python-构建与工程规范.md` |
| 给**已有**后端补文档（默认不改行为） | `Python-代码文档规范.md` |

## 强制约定（任何任务都适用）

- **Python 不是 Java**：禁止机械搬 `Interface` / `ServiceImpl` / `BaseController`；函数优先，有理由再 class。
- **架构与复杂度成正比**：小项目不大拆；禁止 `utils.py` 万能抽屉。
- **调用单向**：`Router → Service/用例 → Repository → DB`；Router 不吞大段业务。
- **查库可见**：禁止循环/推导里隐式 N+1；分页在 DB；过滤聚合优先 SQL。
- **Async 有依据**：禁止 `async` 里跑阻塞 IO；无需求不上队列/缓存中间件。
- **注释中文**：多步函数用 1️⃣2️⃣3️⃣ 阶段标题；决策写 WHY；关键路径有带业务 id 的日志且不泄密。
- **密钥零硬编码**；认证 ≠ 鉴权。

涉及细节拿不准时，回到对应 `references/` 文档的核对清单对照。

## 输出约定

- 审查/返工时口径与对应文档一致（红线表、清单）。
- 注释语言：行间中文；docstring 跟项目既有语言。
- 文档化任务：行为保持不变；发现问题进 Important Findings，不夹带重构。
