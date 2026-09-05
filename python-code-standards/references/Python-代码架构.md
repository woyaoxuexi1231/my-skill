# Python 代码架构

> 范围：只定 **目录怎么切、模块职责、谁调谁、复杂度与架构成正比**。  
> 不管：各层内部怎么写（见 [`Python-模块代码规范.md`](Python-模块代码规范.md)）。  
> **Python 不是 Java**：禁止机械搬 `Interface / AbstractClass / ServiceImpl / BaseController`。

**技术基底**：Python 3（以项目声明版本为准）· 常见后端 FastAPI / Django / Flask · `pyproject.toml`。

---

## 1. 原则

1. **先理解再实现；先设计再堆代码**——不为「生成快 / 行数少 / 装逼语法」牺牲可维护性。
2. **架构与复杂度成正比**——小项目不大拆；大系统不糊成一个脚本。
3. **函数是一等设计工具**——无状态就不硬上 class；有状态 / 生命周期 / 多相关行为再用 class。
4. **模块按领域切**——禁止 `utils.py` / `helpers.py` / `common.py` / `manager.py` 万能抽屉。
5. **显式优于巧妙**；不隐藏复杂度；不为假想未来过度抽象。
6. **未点名**：不上微服务、不上完整六边形/DDD、不引入无需求的 Celery/Redis/Kafka。

**一句话判断**：新人打开包目录，能不能一眼看出业务边界与调用方向？不能 → 切分或命名有问题。

---

## 2. 复杂度定架构

### 小项目（可扁平）

```text
app/
├── main.py
├── config.py
├── models.py
└── services.py
```

### 中型（按技术角色分包）

```text
app/
├── api/              # 路由 / 视图入口
├── services/         # 用例编排（有边界才建）
├── repositories/     # 持久化访问
├── models/           # 领域 / ORM
├── schemas/          # 请求响应契约（Pydantic 等）
├── config/
└── infrastructure/   # 外部客户端、队列适配（按需）
```

### 大型（有明确域边界时）

```text
app/
├── api/
├── application/      # 用例
├── domain/           # 领域规则
├── infrastructure/
├── repositories/
├── schemas/
├── security/
└── configuration/
```

**禁止**一上来就建最大架构。空目录不留；无第二使用方不抽公共层。

---

## 3. 分层与调用方向

典型 FastAPI 风格：

```text
Request → Schema 校验 → Router → Service / 用例 → Repository / ORM → DB
```

| 层 | 职责 | 禁止 |
|----|------|------|
| Router / View | 接参、鉴权依赖、调用例、返回契约 | 塞大段业务 / 直接拼复杂 SQL |
| Service / 用例 | 业务编排、事务边界、外部集成 | 为「像 Java」而空转一层 |
| Repository | 持久化意图与查询形状 | 藏 N+1、在循环里偷查库 |
| Schema | API 边界校验与序列化 | 与 DB Entity 无脑混用（有边界时分开） |
| Config | 环境相关配置 | 硬编码密钥、散落魔法常量 |

小函数可以仍是函数——**不要自动造 Service 类**。

跨模块协作：只经对方公开门面（模块级函数或明确的 service API），禁止穿透到对方私有实现细节。

---

## 4. 包与模块设计

### 推荐（领域内聚）

```text
users/
    service.py
    repository.py
    schemas.py
```

### 禁止

```text
utils.py          # 什么都往里扔
everything.py
common.py         # 无边界的公共池
manager.py        # 含义模糊的上帝对象
```

模块应回答：**它负责什么、不负责什么、与谁协作**。

---

## 5. 函数 vs 类

| 用函数 | 用类 |
|--------|------|
| 无状态、单次操作 | 需要持有依赖 / 状态 / 生命周期 |
| 行为简单、可组合 | 多个相关行为共享同一上下文 |
| class 只会包一层函数 | 领域建模明显受益于对象 |

禁止：

```python
class UserService:
    def get_user(...):
        ...
```

若类无状态、无边界、只转发一次调用——改回函数。

---

## 6. 依赖与全局状态

- **显式注入**：构造器参数、函数参数、FastAPI `Depends`；禁止隐式全局可变状态。
- **危险全局**：`CACHE = {}`、`CURRENT_USER = None`、模块级可变 `CLIENT`——除非生命周期与并发含义已明确。
- 长生命周期资源（连接池、HTTP client）挂在 **应用生命周期**，不在热路径反复创建。

---

## 7. 数据模型边界（按需）

有价值时区分：

```text
Request Schema / Response Schema / Domain Model / Persistence Model / Config Model
```

不要机械为每层造模型。边界存在是为了保护：**API 契约、领域不变量、持久化细节、安全字段**。

---

## 8. 开发流程

```text
需求 → 理解领域 → 选架构 → 定数据模型 → 定接口
  → 核心逻辑 → 基础设施 → 校验 → 测试 → 注释/日志复核 → 工具链校验
```

禁止在地基未验证前生成数千行。

---

## 9. 反模式速查

| 反模式 | 正确方向 |
|--------|----------|
| 巨型 `utils.py` / 全塞 `main.py` | 按领域拆模块 |
| 假 Service / 过度继承 | 函数优先；有理由再 class |
| 为假想多库造 Factory/Strategy | 做当前真实需要 |
| 把生产服务糊成单文件脚本 | 多域 / 鉴权 / 外部系统时建清晰边界 |
| 全局可变状态当默认 | 依赖注入 + 生命周期 |
| 架构一步到位「企业级」 | 与复杂度成正比 |

---

## 10. 核对清单

```text
[ ] 架构与项目规模匹配
[ ] 模块职责清晰，无万能抽屉
[ ] 调用方向单向，Router 不吞业务
[ ] 未机械搬 Java 分层名词
[ ] 无状态逻辑未强行 class
[ ] 无隐式全局可变依赖
[ ] 未为假想未来堆抽象
```
