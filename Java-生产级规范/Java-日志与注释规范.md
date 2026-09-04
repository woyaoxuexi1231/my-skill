# Java 日志与注释规范

> 范围：**两大章——第一章 日志、第二章 注释**。\
> 注释与日志是交付物的一部分，不是收尾可选项。\
> **编号约定**：第二章（注释）的步骤编号用 **emoji 键帽数字**（`1️⃣ 2️⃣ 3️⃣…`）；第一章（日志）**不用数字编号**，只以标记类 emoji（`✅ ❌ ⚠️ 🌐 ⚡`）做扫读标记，克制使用。

***

# 第一章 日志（Logging）

> 本篇只管**日志怎么打**：级别、上下文、泄密红线、形态、emoji 编号。

## 1.1 三条硬底线

| # | 底线           | 说明                                                         |
| - | ------------ | ---------------------------------------------------------- |
| 1 | **级别用对**     | `ERROR` 需人工处理的失败；`WARN` 可恢复/降级；`INFO` 关键业务节点；`DEBUG` 细节排查。 |
| 2 | **带足业务上下文**  | 失败日志必须含关键业务 id、操作、失败原因；空手 `log.error("error", e)` 等于没打。    |
| 3 | **不泄密、不吞异常** | 不记录密码/Token/密钥/多余敏感信息；打了日志不等于处理完，仍要上抛或映射。                  |

## 1.2 级别与场景

| 级别      | 什么时候用                      | 反例           |
| ------- | -------------------------- | ------------ |
| `ERROR` | 需处理/告警的失败：调用失败、数据不一致、状态机非法 | 用来打普通业务拒绝    |
| `WARN`  | 可恢复、有降级、边界可达：缓存穿透、限流、重试后成功 | 用来打正常流程      |
| `INFO`  | 关键业务节点：下单成功、订单流转、任务开始/结束   | 每个方法进出都打（刷屏） |
| `DEBUG` | 细节排查，进表/出参                 | 生产常开 DEBUG   |

**日志文案风格全项目统一**：带业务前缀 + 动作 + 结果/原因，例：

```text
好：创建订单失败 orderId=1024 userId=88 reason=库存不足
差：error
```

## 1.3 推荐形态

```java
// ✅ 带业务键 + 动作 + 结果/原因
log.warn("创建订单失败 orderId={} userId={} reason={}", orderId, userId, e.toString(), e);

// ❌ 无上下文
log.error("error", e);
log.info("start"); log.info("end");
```

## 1.4 上下文与失败可观测

- 失败日志带：**业务 id + 操作 + 失败原因** ；需要时带异常对象（保留 stack）。

- 与步骤注释配合（见第二章）：**方法体内先有步骤注释说明意图，关键失败点再打日志**——注释给读者，日志给线上：

```java
// 调支付网关：超时按未决处理，不重复发起扣款
try {
    PayResult result = payClient.charge(request);
} catch (TimeoutException e) {
    // ⚠️ 未决订单留给对账任务兜底，此处只告警
    log.error("❌ 支付网关超时 orderId={} amount={}", orderId, amount, e);
    throw new BizException(ErrorCode.PAY_PENDING);
}
```

## 1.5 禁止

- 记录：密码、Access Token、Authorization 头、密钥/私钥、不必要的敏感个人信息。

- 默认给每个方法打进入/退出日志。

- `catch (Exception e) { log.error("error", e); }` 当万能处理且不再上抛/映射。

- 用日志代替返回值或控制流（「打了日志就算处理完」）。

## 1.6 日志不做数字编号（关键补充）

- 日志**不做** `1️⃣ 2️⃣ 3️⃣` 之类的数字/序号编号——日志是顺序流，靠级别与时间定位，不需要人为排序。

- 需要强调的关键/失败日志，用**标记 emoji**（`✅ ❌ ⚠️`）在前缀扫读即可（见 §1.7）。

- 若某条日志对应代码里的多个步骤之一，在日志文案里写这个步骤的业务含义（如 `orderId=`），**不要写步骤序号**。

## 1.7 Emoji 用法（允许、克制）

- **适当、少量、有辨识度**——不是装饰义务。

- 日志只用**标记类 emoji**，不用数字编号（见 §1.6）。

- 标记类 emoji 固定同一 meaning，形成扫读习惯：

| 场景       | 符号   | 说明                |
| -------- | ---- | ----------------- |
| 成功 /完成   | `✅`  | 关键业务节点            |
| 失败 /告警日志 | `❌`  | 让 ERROR/WARN 便于扫到 |
| 警告 /坑    | `⚠️` | 并发陷阱、不可删的变通       |
| 外部依赖 /IO | `🌐` | 跨服务调用（可选）         |
| 性能相关     | `⚡`  | 有优化或性能约束（可选）      |

- **禁止**：每条日志/注释都加、一串表情刷屏、用 emoji 代替 `orderId=` 等文字上下文。

## 1.8 外部 IO 日志

Redis/HTTP/RPC/MQ/OSS 等进程外调用失败：记清**对端标识 + 超时/状态码 + 失败原因**，仍不记密钥与完整敏感载荷。

## 1.9 日志核对清单

- [ ] 失败日志有业务上下文（业务 id + 操作 + 原因）且级别正确

- [ ] 无密码 / Token / 密钥 / 多余敏感信息

- [ ] 无方法进出刷屏；无「只打日志不处理」

- [ ] 日志不做数字编号；emoji（若有）只出现在关键 / 失败等合理点，未滥用

***

# 第二章 注释（Comments）

> 本篇分两块：**注释的三层通用结构** 与 **按类类型的注释密度**（哪个类注释写多深）。\
> 核心思路：**注释详略按类类型分级，把功夫花在最难懂的地方**（配置、Service 逻辑），最薄的地方一句话即可（Controller 入口）。

## 2.0 三条硬底线（承接第一章「编号」约定）

| # | 底线                | 说明                                                          |
| - | ----------------- | ----------------------------------------------------------- |
| 1 | **禁止一行流 Javadoc** | `/** 按 token 恢复会话。 */` 只是翻译方法名，等于没写。                        |
| 2 | **方法体必须有步骤注释**    | 方法注释只说「做什么」，方法体要说「分几步、每步为什么」；步骤编号用 `1️⃣ 2️⃣ 3️⃣`。           |
| 3 | **按类类型定密度**       | 配置/Service 逻辑最重的地方详写，Controller 入口/Entity 字段该简要就简要（见 §2.3）。 |

## 2.1 注释的三层结构

| 层级   | 位置     | 回答什么             | 详略随类类型变化 |
| ---- | ------ | ---------------- | -------- |
| 类注释  | 类声明上方  | 这个类干什么、边界约束      | 见 §2.3   |
| 方法注释 | 方法声明上方 | 做什么、入参/返回/异常/副作用 | 见 §2.3   |
| 行间注释 | 方法体内   | 分几步、每步为什么        | 见 §2.3   |

读者视角：

```text
类注释   → 我要不要改这个类？它管什么、不管什么
方法注释 → 我要不要调这个方法？传什么、返回什么、会抛什么
行间注释 → 我要改这段逻辑，它分几步、哪一步有坑
```

## 2.2 富文本写法

- 类/方法注释用 **富文本 Javadoc**：`<p>` / `<ul>` / `<ol>` / `<dl>` / `<pre>` 分段，不嵌 `<h1>~<h6>`。

- 行内代码 / 字面量用 `{@code ...}`（自动转义）；引用类/方法/字段用 `{@link Type}` / `{@link Type#method}`。

- 分支/多口径用 `<ul>/<ol>` 逐条；键值/术语用 `<dl><dt><dd>`。

- `@param` 写单位/格式/取值范围；`@return` 写语义与是否可能 null；`@throws` 写「什么条件下 + 抛哪个错误码」。

- 判断标准：**把方法名和签名遮住，只看注释，能否知道该不该调、怎么调、会出什么事。**

## 2.3 各类的注释密度（核心）

**注释详略不做一律处理**，按类类型区分——详略分配的核心是「哪里读起来最容易迷路，就在哪里下功夫」：

| 类类型                | 类注释                  | 方法注释                   | 行间注释              |
| ------------------ | -------------------- | ---------------------- | ----------------- |
| **config / 装配类**   | **简要**：一句话说清解决什么装配问题 | **非常详细**：每步参数/序列化/开关含义 | **非常详细**：每行为什么这样配 |
| **service**        | 清楚：职责边界 + 事务边界       | **非常强**：调用条件/失败行为/副作用  | **非常强**：步骤 + 为什么  |
| **controller**     | **简要**：这组接口归属资源      | **简要**：一句话用途           | **极少**：方法体很薄（接与转） |
| 模块内联表 mapper       | 简要：查询归属与语义           | 清楚：查询语义 + 返回形态         | XML 内写 SQL「为什么」   |
| 全局单表 mapper        | 基本无（继承 MP）           | 基本无（继承 MP）             | 无                 |
| entity / 枚举        | 简要                   | 字段不自明才注释               | 枚举每值写业务含义         |
| dto（契约）            | 简要                   | 不自明字段注释                | 无                 |
| 异常 / 错误码           | 简要                   | 每条含义唯一并注释              | 无                 |
| 纯工具类 `common.util` | 简要：功能前缀 + 用途         | 参数/返回边界                | 视复杂度              |

> 一句话：**把注释预算花在 config 和 service 上；controller 和 entity 该薄就薄。**

***

### 2.3.1 config / 装配类（类简要，方法 + 行间最详细）

配置类一旦写错，是整个启动链最难定位的问题。要求：

- **类注释**：一句简要说明「这个配置干什么，解决什么问题」，不展开细节。

- **方法注释 + 行间注释**：**非常详细**——每步解释参数为什么这样取、序列化/开关/失效策略的含义、环境值从哪来。

```java
/**
 * Redis 配置。
 * <p>统一连接、序列化与连接池；不涉及任何业务键规则。</p>
 */
@Configuration
public class RedisConfig {

    /**
     * 生产可用的 RedisTemplate。
     * <p>value 走 JSON 序列化，避免默认 JDK 序列化的黑盒与跨语言不可读。</p>
     *
     * @param factory Spring 注入的连接工厂，按 application-{profile}.yml 的地址建连
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        // 1️⃣ key 用 String 序列化：命令面清晰，便于运维按前缀排查
        RedisTemplate<String, Object> t = new RedisTemplate<>();
        t.setConnectionFactory(factory);
        t.setKeySerializer(RedisSerializer.string());
        // 2️⃣ value 用 JSON：跨语言可读；⚠️ 泛型类反序列化需 GlobalNaming/内部类注意，勿存复杂嵌套泛型
        t.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        // 3️⃣ 显式完建，防止底层默认 JdkSerializer 兜底导致类型混乱
        t.afterPropertiesSet();
        return t;
    }
}
```

### 2.3.2 service（类清楚，方法 + 行间非常强）

业务逻辑最复杂的落点，注释必须能独立支撑「读得懂、改得对」。

- **类注释**：职责边界 + 事务边界（哪些用例同成同败、是否含远程调用）。

- **方法注释**：调用场景、失败行为、副作用、`@param/@return/@throws`。

- **行间注释**：`1️⃣ 2️⃣ 3️⃣` 步骤 + 每步「为什么」；含有并发/降级/变通处补 `⚠️`。

```java
/**
 * 订单创建与生命周期流转。
 * <p>职责：创建订单、取消订单、查询详情。支付与退款在 {@link PaymentService}。</p>
 * <p><b>事务边界：</b>创建用例在本类方法上，落订单与扣库存同成同败；方法内不做远程调用。</p>
 */
@Service
@RequiredArgsConstructor
public class OrderService {
    public void cancelOrder(Long orderId, String operator) {
        // 1️⃣ 加行锁查询：并发重复取消时，后到的请求在此等待前事务结束
        Order order = orderMapper.selectForUpdate(orderId);

        // 2️⃣ 幂等判断：已取消直接返回，避免重复退库存
        if (OrderStatus.CANCELED == order.getStatus()) {
            log.info("✅ 订单已取消，跳过 orderId={}", orderId);
            return;
        }

        // 3️⃣ 校验可取消状态：已发货必须走售后，不能直接取消
        if (!order.getStatus().canCancel()) {
            throw new BizException(ErrorCode.ORDER_CANNOT_CANCEL);
        }

        // 4️⃣ 同一事务更新状态并退库存：两步必须同成同败
        orderMapper.updateStatus(orderId, OrderStatus.CANCELED);
        inventoryService.release(order.getSkuId(), order.getQuantity());

        // ⚠️ 5️⃣ 通知放事务提交后：失败只影响通知，不回滚已完成的取消
        eventPublisher.publish(new OrderCanceledEvent(orderId, operator));
    }
}
```

### 2.3.3 controller（类 + 方法简要，行间极少）

Controller 是薄入口（接与转），注释不铺张：

- **类注释**：一句归属资源（相关接口边界）即可。

- **方法注释**：一句话用途 + 关键入参/失败态；不逐行复述。**但只要是方法注释，再简也必须用 Javadoc** **`/** … */`，不能写成** **`//`**（`//` 只用于行间/字段级说明）。

- **行间注释**：方法体很薄，一般不需要步骤注释；出现分支才补一句为什么。

```java
/**
 * 订单查询与下单。仅接收 HTTP，业务全在 {@link OrderService}。
 */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    /**
     * 列出我的订单（分页）；orderStatus 为空时查全部。
     *
     * @param query 分页与过滤条件
     */
    @GetMapping
    public Result<PageResult<OrderListItemVO>> list(OrderQuery query) {
        return Result.ok(orderQueryService.list(query));
    }

    /**
     * 取消订单；状态非法抛 {@code ORDER_CANNOT_CANCEL}。
     *
     * @param id 订单 id
     */
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id) {
        orderService.cancelOrder(id, SecurityUtils.currentUserId());
        return Result.ok();
    }
}
```

### 2.3.4 模块内联表 mapper / 全局单表 mapper

- **全局单表 mapper**（`extends BaseMapper`）几乎无注释——方法继承自 MP，职责由 Entity 表义决定。

- **模块内联表 mapper**：方法注释写**查询语义 + 返回形态**（如「按用户取订单+明细联表，返回投影」）；XML 复杂语句写 **SQL「为什么」**（JOIN 组织、条件在 ON 还是 WHERE、分页策略）。见 §2.7。

```sql
-- 用 LEFT JOIN 保留无订单用户：统计口径要求分母是全部活跃用户
-- 状态条件放 ON 而非 WHERE，否则 LEFT JOIN 退化成 INNER JOIN
SELECT u.id, COUNT(o.id) AS order_count
FROM user u
LEFT JOIN orders o ON o.user_id = u.id AND o.status = 'PAID'
WHERE u.is_deleted = 0
GROUP BY u.id;
```

### 2.3.5 entity / dto / 枚举 / 异常

- **entity**：字段含义不自明才注释；不注释显而易见的列。

- **枚举**：**每个值写清业务含义**（用 `<dl>` 或 `// value 含义` 逐条）。

- **dto（契约）**：不自明字段注释；`@param` 有单位/范围时注明。

- **异常 / 错误码**：每条含义唯一，关键错误码注释「什么场景抛」。

```java
public enum OrderStatus {
    /** 已创建，待支付 */
    CREATED,
    /** 已支付，待发货 */
    PAID,
    /** 已发货，进行中 */
    SHIPPED,
    /** 已取消：仅 CREATED/PAID 可流转到此 */
    CANCELED,
    /** 已完成 */
    COMPLETED;
}
```

## 2.4 方法注释（富文本，密度按 §2.3 分级）

> **任何类类型的方法注释，都必须用 Javadoc** **`/** … */`**——即使只有一句（如 controller），也不能退化成 `//` 行注释。`//` 只用于**行间说明或字段级说明**；行间不是方法注释的合法替代。

| 要素                | 何时必写                   |
| ----------------- | ---------------------- |
| 一句目的              | **总是**                 |
| 补充段落（边界、失败行为、副作用） | 有非显而易见行为时**必须**写       |
| `@param`          | 参数含义不自明、有单位/格式/取值范围要求时 |
| `@return`         | 可能为空、是快照还是实时值          |
| `@throws`         | 写清什么条件下抛、抛哪个错误码        |
| 注意段               | 有性能、并发、兼容隐含约定时         |

**最重密度（service/config）示例：**

```java
/**
 * 结算并生成支付单。
 * <p>按结算规则聚合订单金额，生成支付单并返回支付入口。
 * 幂等：同一 {@code settlementId} 重复调用返回同一支付单，不重复生成。</p>
 *
 * <ul>
 *   <li>结算商品已下架 → 抛 {@link BizException}（{@code SKU_OFF_SHELF}）</li>
 *   <li>余额不足且未勾选组合支付 → 抛 {@code INSUFFICIENT_BALANCE}，不落单</li>
 * </ul>
 *
 * @param settlementId 结算单 ID，来自预结算，禁止为空
 * @param payChannel   取值见 {@link PayChannel}
 * @return 新建或已存在的支付单快照，永不返回 {@code null}
 * @throws BizException 任一失败行为触发时携带对应错误码
 * @see PaymentService#pay(String, String)
 */
public PayOrder settleAndCreate(String settlementId, String payChannel) { }
```

**最轻密度（controller）可只写一句目的**，不必凑字数——但「有内容可写却偷懒写一行」在 service/config 上按 §2.0 第 1 条打回。

## 2.5 行间注释（步骤，编号用 emoji 键帽）

- **硬性要求**：方法体 ≥10 行、或有 ≥3 个逻辑段落、或有分支/循环/异常做非显而易见的事 → 必须有**编号步骤注释**。

- **写法**：用 `1️⃣ 2️⃣ 3️⃣`（或 `0️⃣` 起）开头，每步先说干什么、必要时补为什么：

```java
// 2️⃣ 查会话：Redis 没有说明已过期或被踢，按未登录处理
```

- **步数**：**控制在 3\~7 步**。超过 7 步说明方法承担太多，先**拆方法**，不要写第 8 步。

- **编号连续**：删除步骤后重排，禁止 `1️⃣ 2️⃣ 5️⃣`。

- **反模式**：逐行复述代码（`// 获取用户`）、方法注释有了方法体裸奔、注释与代码矛盾、用注释解释烂命名（应先改名）。

**判断一句行间注释是否有价值：删掉它，读者是否会多花时间才能看懂？不会 → 删掉。**

## 2.6 注释内容：写「为什么」

优先回答：为什么这样设计？为什么这个事务边界？为什么这条 SQL 这么组织？为什么有这个变通、何时可删？这个分支防的是什么情况？

不写：获取用户 / 循环订单 / 调用某方法 / 设置名称（这是复述，不是理由）。

## 2.7 SQL 注释

复杂 SQL 注释「为何」：JOIN 组织、条件在 `ON` 还是 `WHERE`、看似多余的条件、分页策略、索引友好写法。不注释显而易见的语法本身。示例见 §2.3.4。

## 2.8 注释必须正确

- 代码已改 → 审查相关注释 → 更新或删除过时注释。**错误注释比没有注释更糟。**

- 不要用注释弥补烂命名：先改名（如 `calculateAvailableInventory()`），再补真正需要的「为什么」。

- 富文本细节：`{@code}` 标字面量最佳（自动转义 `<>&`）；引用用 `{@link}`；不要用 `<table>`/`<u>`/`<br>` 硬排。

## 2.9 行间 / 富文本速查

| 场景         | 推荐写法                                   |
| ---------- | -------------------------------------- |
| 行内代码 / 字面量 | `{@code ...}`                          |
| 引用类、方法     | `{@link Type}` / `{@link Type#method}` |
| 分支 / 多口径   | `<ul>/<ol>` 逐条                         |
| 键值 / 术语    | `<dl><dt><dd>`                         |
| 步骤编号       | `1️⃣ 2️⃣ 3️⃣`（emoji 键帽）                |
| 警告 / 坑     | `⚠️`                                   |
| 预格式化示例     | `<pre>{@code ...}</pre>`               |
| `@see`     | 指相关方法，避免重复描述                           |

## 2.10 注释核对清单

- [ ] 无一行流 Javadoc；类/方法注释用富文本（`<p>` / `<ul>` / `<dl>` / `@param` / `@return` / `@throws`）

- [ ] **方法注释一律 Javadoc** **`/** … */`，不退化用** **`//`**；`//` 仅用于行间/字段级说明

- [ ] **详略按类类型分级**：config/service 详、controller/entity 薄（§2.3）

- [ ] config / 装配类：类注释简要，方法 + 行间非常详细

- [ ] service：方法注释 + 行间注释非常强；事务边界在类注释写清

- [ ] controller：类 + 方法简要

- [ ] 方法体 ≥10 行或有多个逻辑段落的，有**编号步骤注释（emoji 键帽** **`1️⃣ 2️⃣ 3️⃣`）**

- [ ] 步骤 ≤7；编号连续不跳号；超过说明方法该拆

- [ ] 分支/循环/异常写了「为什么走这个分支」

- [ ] 全局单表 mapper 基本无注释；模块内联表 mapper 方法 + XML 写「为什么」

- [ ] 枚举每值有业务含义；错误码含义唯一

- [ ] 复杂 SQL 有「为什么」；无复述代码的废话注释；无与代码矛盾的注释

**打回语**

- 「这是把方法名翻译了一遍，重写：写清失败行为、副作用、异常条件。」

- 「方法注释用 `//` 写了，方法级一律 Javadoc `/** */`，再简也换成 Javadoc。」

- 「config 的方法/行间太薄，这配置每步为什么这样配要写清。」

- 「Service 逻辑没步骤注释，方法体 40 行零注释，补 `1️⃣ 2️⃣ 3️⃣`。」

- 「Controller 注释铺开了，这层一句话用途即可。」

- 「注释里裸写类名 / 错误码，改用 `{@link}` / `{@code}`。」

- 「步骤删了编号没重排，`1️⃣ 2️⃣ 5️⃣` 改回连续。」

- 「第 8 步了，先拆方法再补注释。」

- 「失败日志缺 orderId。」

- 「emoji 过密，只在步骤编号、关键日志和警告处保留。」

***

