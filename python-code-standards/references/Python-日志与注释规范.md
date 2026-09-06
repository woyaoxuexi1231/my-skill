# Python 日志与注释规范

> 范围：只定 **日志怎么打、注释/文档字符串怎么写**。  
> 目录与分层见 [`Python-代码架构.md`](Python-代码架构.md)、[`Python-模块代码规范.md`](Python-模块代码规范.md)。  
> 日志与注释是交付物的一部分，不是收尾可选项。

---

## 1. 总原则

| | 日志 | 注释 |
|--|------|------|
| 目的 | 线上能排障、能对账 | 后人懂**为什么**这样写 |
| 优先 | 稳定业务 id + 结果/原因 | 决策、规则、权衡、边界 |
| 避免 | 刷屏、泄密、用 log 代替处理 | 复述语法「做了什么」 |

目标：另一位开发者能定位故障，并理解关键业务决策。

---

## 2. 日志

### 2.1 硬底线

1. **级别用对**：`error` 需处理；`warning` 可恢复/拒绝/降级；`info` 关键业务节点；`debug` 细节。
2. **带足上下文**：失败必须含业务 id、操作、原因；空手 `logger.error("failed")` 等于没打。
3. **不泄密**：密码、Token、Authorization、密钥、超出规范的 PII、私密载荷（如手牌）一律不进日志。
4. **用项目 logger**：`logging` / structlog / loguru；生产服务代码禁止散落 `print()`。
5. **不引入新日志框架**除非明确要求。

### 2.2 哪里必须有日志

| 区域 | 最低期望 |
|------|----------|
| 鉴权 / 安全决策 | allow/deny + reason code + subject id |
| 资金 / 积分 / 结算 | 前后余额或 delta + 业务 id |
| 事务写路径 | 成功 / 与回滚相关的失败 |
| 外部 HTTP / WS / 邮件 / MQ | 意图 + 结果；超时/重试 |
| WebSocket 连接 / 订阅 / 广播 | session/room + 扇出范围 |
| Celery / 后台任务 | task id + 业务 id + 重试/失败 |
| 锁 / 调度 | 抢锁成败 + job 身份 |
| 状态机 / 阶段变更 | from → to + entity id |
| 吞掉或转译的异常 | 合适级别 + 上下文 / `exc_info` |

### 2.3 写法

```python
# 好
logger.info(
    "order.created order_id=%s user_id=%s item_count=%s",
    order.id, user_id, len(items),
)
logger.exception(
    "payment.capture_failed order_id=%s provider=%s",
    order.id, provider,
)

# 差
logger.info("user=%s", user)           # 可能泄密 / 过大
logger.debug("password=%s", password)  # 禁止
logger.error("failed")                 # 无上下文
logger.info("enter create_order")      # 噪音
print("here")
```

- 优先惰性格式化（`%s` / `{}` 按 logger 风格）；热路径避免总是拼巨大 f-string。
- 对齐项目既有 message 模式 / contextvars / extras。
- 默认不给每个函数打进入/退出。

### 2.4 日志不做步骤编号

日志是时间序流，**不用** `1️⃣2️⃣3️⃣` 编号。需要扫读时可用少量标记（如项目已有约定），但以级别 + 业务键为主。

---

## 3. 注释

### 3.1 语言

> **行间注释、分步标记、决策说明必须使用中文。**

除非用户明确要求其它语言。Docstring 跟项目既有语言；无既有约定时，本仓库面向开发者的说明优先中文，或与既有混合风格一致，避免新代码里出现「英文注释孤岛」。

### 3.2 注释解释什么

解释代码本身说不清的：

- 为什么存在 / 为什么选这方案  
- 满足什么约束 / 做什么权衡  
- 什么条件下可删掉 workaround  

### 3.3 多步函数：1️⃣ 2️⃣ 3️⃣ 阶段标记（强制）

函数超过一个有意义阶段（校验 → 加载 → 决策 → 持久化 → 通知）时，用键帽数字标阶段：

```python
def create_order(...) -> Order:
    # 1️⃣ 校验调用方与明细（空单/非法数量早拒）
    validate_create_request(user_id, items)

    # 2️⃣ 按目录现价计价（忽略客户端传来的价格）
    priced = pricing_service.price(items)

    # 3️⃣ 原子持久化订单与明细
    order = order_repository.save(db, to_order(user_id, priced))

    # 4️⃣ 仅在提交成功后发领域事件
    db.commit()
    after_commit(lambda: order_events.created(order.id))
    return order
```

规则：

1. 按**逻辑阶段**标，不按每一行标。  
2. 一阶段一句短标题（领域语言）；更深 WHY 可另起一行。  
3. 编排函数标步骤；嵌套 helper 仅在自身多阶段时再标。  
4. 已有清晰分段注释时，归一成 1️⃣2️⃣3️⃣，不要重复两套。

**一步函数 / 纯映射 / 一眼能懂的 getter**：不强制阶段标记。

### 3.4 决策注释写 WHY

```python
# 差
# 获取用户
user = repository.get_user(user_id)

# 好
# 只取本接口需要的字段；用户资料里有大 JSON 列，这里用不到。
user = repository.get_user(user_id)

# 差
# 判断用户是否存在
if user is not None:

# 好
# 缺用户按鉴权失败处理，避免用本接口枚举合法 user_id。
if user is not None:
```

常见值得写的类别：业务规则、性能决策、查库形状、异步选型、安全决策、兼容分支。

### 3.5 禁止废话注释

```python
# 计数器加一
counter += 1
# 返回用户
return user
# 创建列表
users = []
```

### 3.6 Docstring

公开 API、可复用库、复杂逻辑写 docstring。说明用途、契约、副作用、事务归属、异常——不要复述函数名。

```python
def calculate_available_stock(total: int, reserved: int) -> int:
    """返回仍可售卖的库存。

    已预留库存不计入可售，因其已承诺给其它订单。
    """
```

风格跟项目（Google / NumPy / Sphinx）；无约定时后端服务优先 Google 风格。

### 3.7 注释与代码同步

改代码 → 复核相关注释 → 删掉过期说明。禁止留下描述已不存在行为的注释。

好命名减少注释需求：`calculate_available_stock` 优于 `calc()`。

---

## 4. 推荐组合形态（服务函数）

```text
Docstring（目的 / 契约 / 副作用 / 事务）
  → 1️⃣ 阶段标题
      → 非显然处补 WHY
  → 2️⃣ 阶段标题
  → 关键结果 logger.info / 失败 logger.exception
```

---

## 5. 核对清单

```text
[ ] 关键路径有带业务 id 的日志（鉴权、资金、写库、外部 IO、worker、失败）
[ ] 无密钥 / Token / 私密载荷入日志
[ ] 未用 print 充当生产可观测性
[ ] 多步函数有中文 1️⃣2️⃣3️⃣ 阶段标题
[ ] 决策注释写 WHY，无逐行复述
[ ] 行间注释为中文；docstring 语言与项目一致
[ ] 无过期注释
```
