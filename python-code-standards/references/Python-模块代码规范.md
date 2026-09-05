# Python 模块代码规范

> 本篇：**各层怎么写** + 跨层强制项（类型、持久化、异步、外部调用、安全、异常、性能）。  
> 目录与谁调谁见 [`Python-代码架构.md`](Python-代码架构.md)。  
> 日志 / 注释见 [`Python-日志与注释规范.md`](Python-日志与注释规范.md)。

**技术基底**：Python 3 · 常见 FastAPI / Django / Flask · SQLAlchemy / Django ORM · Pydantic（按项目）。

---

## 0. 通例

### 0.1 命名

| 对象 | 规则 | 示例 |
|------|------|------|
| 模块 / 包 | 领域名词，短小 | `orders/`、`pricing.py` |
| 函数 | 动词 + 对象 | `create_order`、`calculate_available_stock` |
| 布尔 | `is` / `has` / `can` | `is_payment_expired` |
| 异常 | 业务含义 | `OrderCancellationNotAllowedError` |
| 常量 | 全大写下划线或 Enum | `PaymentStatus.PROCESSING` |

禁：`data`、`temp`、`obj`、`calc`、`check_flag`、光秃 `utils`。

### 0.2 显式优于巧妙

优先可读；不要为炫技用生僻写法。列表推导 / 生成器在**意图更清晰**时用，否则用普通循环。

### 0.3 类型提示

生产代码对**参数、返回值、公开接口、复杂集合**加类型；不要给每个无意义局部变量刷注解。

```python
def get_user(user_id: int) -> User | None: ...
def create_order(user_id: int, items: list[OrderItem]) -> Order: ...
```

禁止用 `dict` / `Any` 逃避已知结构。`Any` 仅真正必要时使用。

### 0.4 Dataclass / Pydantic

| 工具 | 用途 |
|------|------|
| `dataclass` | 领域值、内部结构、配置对象 |
| Pydantic | 请求校验、响应 schema、外部数据、配置（pydantic-settings） |

有边界时：**Pydantic schema ≠ DB Entity**，不要混成一团。

---

## 1. API / Router

```text
校验 → Router → Service → Repository → DB
```

- Router 只做接与转；多步业务进 service / 函数。
- 错误映射到合适 HTTP/WS 响应，不泄露内部实现细节。
- 公开 API 避免无界返回整表数据；分页是默认。

---

## 2. Service / 用例

何时需要 service（或等价用例模块）：

- 业务工作流、事务边界、外部集成、可复用业务操作

何时不需要：

- 单次无状态查询 / 简单转发——保持函数即可

---

## 3. 持久化与查询

### 3.1 红线

| 禁止 | 正确做法 |
|------|----------|
| 循环 / 推导里隐式查库（N+1） | 批量查、JOIN、eager load；访问必须可见 |
| `get_all()` 再 Python 切片分页 | DB 级分页；大数据考虑 keyset |
| 逐条 `insert` 可批量时 | bulk / 批处理（注意事务大小与锁） |
| 大结果集拉进 Python 再过滤/聚合/排序 | 过滤、JOIN、聚合、分页留给 SQL |
| 盲目巨型 JOIN 替代一切 | 按基数、结果膨胀、索引、分页评估 |

### 3.2 ORM 责任

ORM 不免除你对 SQL 的责任。关注：生成 SQL、查询次数、JOIN、懒加载、选列、结果基数。

### 3.3 SQL vs Python

| 偏 DB | 偏 Python |
|-------|-----------|
| 过滤、JOIN、聚合、GROUP BY、ORDER BY、EXISTS、分页 | 领域规则、编排、外部系统协作 |

### 3.4 事务

明确谁 commit / rollback；需要原子性的写路径放同一事务。文档化 `SELECT FOR UPDATE` 等锁意图。

---

## 4. 异步与并发

### 4.1 Async

- **不要**因 FastAPI 支持就全盘 `async`。
- `async def` 里禁止阻塞调用（如同步 `requests.get`）；用异步客户端或隔离到线程池。
- 适合：多路网络 IO、异步 DB、异步消息。不适合：指望 async 加速 CPU 密集。

### 4.2 GIL / 线程 / 进程

- CPU 密集：线程通常不给真并行；考虑进程池、原生扩展、向量化、分布式——先有依据再上。
- 线程适合阻塞 IO、无 async 的库；管好共享状态、锁、生命周期、executor 上限。
- 进程注意序列化、启动成本、内存复制。

### 4.3 后台任务

需要持久化、保证投递、长任务、分布式重试时，才上队列 / worker。无需求不引入 Celery/RabbitMQ/Kafka。

---

## 5. 外部调用与可靠性

### 5.1 HTTP 客户端

必须有：**超时**、错误处理、合适时连接复用、有依据的重试、幂等意识。禁止默认无限超时。

### 5.2 重试

考虑：次数、退避、抖动、幂等、状态码、失败类型。永久失败不要无限重试。

### 5.3 缓存

不上 Redis「图好看」。先问：贵不贵、多热、多变、能多脏、如何失效、缓存挂了怎么办。

### 5.4 文件与资源

- 路径用 `pathlib`；注意编码、清理、大小、路径穿越、权限。
- 有生命周期的资源用 context manager；热路径勿反复新建昂贵 client。

### 5.5 内存

警惕：大 list/dict、重复集合、大 JSON、无界队列、缓存、长引用。大数据优先生成器 / 流式，但小集合物化更清晰时不要硬上 generator。

---

## 6. 异常与校验

### 6.1 异常

- 捕获具体异常；禁止裸 `except Exception` 当默认。
- 禁止静默吞掉；转换时用 `raise ... from exc` 保留上下文。
- 区分：校验错误、业务错误、外部失败、DB 失败、未知失败。

### 6.2 校验边界

```text
HTTP → Schema 校验 → Application → Domain 规则 → Persistence
```

不依赖前端校验；同规则不必每层重复粘贴。

---

## 7. 安全

| 面 | 要点 |
|----|------|
| 输入 | 校验、注入、路径穿越、恶意载荷 |
| HTTP | 认证 ≠ 授权；CORS/CSRF/安全头按场景 |
| 文件 | 类型与大小限制、路径安全 |
| 序列化 | 不信任 pickle / 不安全反序列化 |
| 密钥 | 环境变量 / 密钥管理；源码零真实密钥 |
| 出站 | SSRF、URL 校验、重定向行为 |

授权必须落到**具体资源 / 操作**，不能只验证「已登录」。

---

## 8. 性能优化顺序

```text
1 去掉无用工作 → 2 去掉无用 IO → 3 减少查库
→ 4 减少传输 → 5 索引/查询形状 → 6 算法复杂度
→ 7 有依据缓存 → 8 合适并发 → 9 内存 → 10 微优化（最后）
```

注意明显 `O(N×M)`（双重循环匹配）；可用字典 / 集合 / JOIN / 批量，但以真实数据量为准。

多查询时问：能否合并/批量/下推 SQL/缓存？**不是**永远「一条巨型 SQL」优于「两条高效小查询」。

---

## 9. 反模式速查

| 反模式 | 正确方向 |
|--------|----------|
| `Any` / `dict[str, Any]` 当模型 | 有意义的类型 / schema |
| 隐藏 DB / 网络调用 | 调用可见、可推理 |
| Async 滥用 / 阻塞进事件循环 | 按 IO 模型选用 |
| 全局可变状态 | 注入 + 生命周期 |
| 万能 `except` / `print` 当日志 | 具体异常 + 项目 logger |
| 无界全表加载 | DB 分页 / 流式 |
| 无需求上缓存/队列/框架 | 有问题再选型 |

---

## 10. 加代码前五问

1. 这段逻辑属于 Router / Service / Repository / Schema / Config 哪一层？  
2. 查库与外部 IO 是否可见？有无 N+1 / 无界加载？  
3. 异步路径里有没有阻塞？超时与重试是否安全？  
4. 认证之后有没有鉴权到具体资源？  
5. 类型能否表达契约？有没有用 `Any` 偷懒？  

答不清 → 先写进当前任务的假设，再动手。
