# Java 分层代码规范

> 本篇：**各层代码怎么写** + Java 通用写法（命名/抽象/模式/Stream/并发/金额/时间等）。  
> **不管**：业务该怎么规划；业务若强制要求，按要求实现，但仍须符合本篇写法。

---

## 0. 通例

### 0.1 命名

**类**

- 类名必须带**具体能力/业务前缀**，后缀可用 `Service` / `Controller` / `Mapper` / `Manager` / `Helper` / `Common` 等。
- **允许**：`OrderInventoryManager`、`TokenRefreshHelper`、`PageQueryCommon`
- **禁止**：光秃的 `Manager`、`Helper`、`Common`、`Util`、`Handler`、`Processor`；以及无前缀的 `CommonUtils` 等垃圾桶。
- **Mapper 命名**：全局单表 Mapper 用 `{Entity}Mapper`（如 `OrderMapper`），模块内联表 Mapper 用 `{Entity}{业务语义}Mapper`（如 `OrderDetailMapper` 或 `OrderJoinMapper`），避免与全局单表重名冲突。

**方法与变量**

- 方法名说意图：`calculateOrderTotal()`；禁 `doProcess()` / `handle()` / `data` / `temp` / `obj`。
- 布尔方法/变量用 `is` / `can` / `has` / `should` 开头：`canCancel()`、`isExpired()`。
- 查询方法前缀有语义：`get`（取单个）/ `list`（取列表）/ `count`（取数量）/ `exists`（判断存在），不要用 `query` / `find` 一把梭。
- 变量名表意，禁止单字母（循环变量 `i`/`j` 除外）与拼音缩写。

**常量与枚举**

- 常量：`UPPER_SNAKE_CASE`，按用途归类到具体类的常量或枚举，**禁止**散落魔法值。
- 枚举类名不带 `Enum` 后缀；枚举值 `UPPER_SNAKE_CASE`；每个值写清业务含义注释。
- 状态、类型、渠道这类**封闭取值**优先用枚举，不要用 `int`/`String` 常量假装。

### 0.2 一类一事与抽象

一个类一种角色：入口 / 用例 / 持久化（单表 / 联表）/ 装配 / 安全 / 契约。

- **默认**：一个实现 → 具体类注入即可，不为「企业范」先抽接口。
- **允许先有接口的例外**：框架要求、稳定跨模块边界、可测隔离外部依赖——且能说清**当前**理由。
- **禁止**：为未提出的多实现需求堆 `Factory` / `Strategy` / `Registry` / 空 `Service`+`Impl`。

**什么时候该拆类**（满足其一即拆，其余情况不拆）：

1. 两段逻辑的**变更原因不同**（业务规则 vs 数据访问）。
2. 一部分需要被**另一个模块复用**。
3. 一部分需要**单独测试**，而当前形态无法测。

**不要仅因文件长就拆**：30 行清楚的方法好过 5 个抽象糟糕的 6 行方法。

### 0.3 失败与契约底线

- 业务失败 → 业务异常 + 错误码；禁吞异常；禁用 `null`/魔法布尔冒充失败。
- 对外禁止 `Map` / `JSONObject`；禁止 Entity 直接当 API 出入参。
- 查询无结果：明确返回空（空列表 / `Optional` / 空 VO），**禁止返回 `null`** 让调用方自己判空。
- 替换契约时清掉双轨与死代码（代码整洁，不是替业务决定能否改契约）。

### 0.4 通用编码红线

| 禁止 | 正确做法 |
|------|----------|
| 先糊再重构；TODO/空实现冒充完成 | 按规范一次写到可维护 |
| Service/VO 拼 HTML 或 UI 展示串 | 返回原子字段；展示交前端或专门渲染层 |
| 单表大查再内存过滤；循环/Stream 里按条查库；**多次单表再内存关联** | 单表用全局单表 MP+Lambda；联表用模块内 mapper XML 一次 SQL；计数用 COUNT |
| 未用到的缓存/MQ/异步/多余抽象先堆上 | 当前用到再加 |
| 假数据冒充真实业务结果 | 按契约返回空/明确无 |
| 列表灌详情；`list.size()` 冒充计数 | 列表与详情分离；计数用 COUNT |
| 页面刷新瀑布式 N 个串行接口 | 合并查询；详情懒加载；角标/KPI 单独优化 |
| 开发期兼容旧接口/双轨分支 | 改契约/表/脚本；删死代码 |
| 魔法字符串/数字散落各处 | 枚举或常量，就近定义并命名 |
| 一笔逻辑散布在多个类里才拼得完整 | 收拢到负责该用例的模块 Service |

---

## 1. Controller（`controller`）与 API 契约

**职责**：HTTP——解析请求、触发校验、取认证上下文、调对应模块 Service、映射响应。

### 1.1 统一响应与分页

- 统一包装：如 `{ "code", "message", "data" }`（字段名以项目为准，全项目一致）。
- 业务失败：明确 `code` + 可读 `message`；校验失败必须能被调用方感知，禁止「HTTP 200 + 空成功」掩盖业务失败（若项目约定失败也走 200+业务码，则业务码与 message 必须非成功态）。
- 分页统一：如 `PageResult<T>{ records, total, pageNum, pageSize }`；列表接口禁止无界全量当默认。
- 空结果返回**空列表 + total=0**，不返回 `null`，也不抛「没有数据」异常。

### 1.2 出入参必须是类型

```text
✅ Result<OrderDetailVO>
✅ @Valid @RequestBody CreateOrderRequest
❌ Result<Map<String, Object>>
❌ @RequestBody Map<String, ?>
❌ 同一资源有的接口有 Request、有的用 Map
```

- 入参：对应 `dto/request` + `@Valid`（或统一校验）。
- 出参：`Result` / `PageResult` + 模块 `dto/response` VO。
- Entity 不做出入参；禁止临时改成 `Map` 凑合。

### 1.3 路径与 HTTP 方法

- 路径用**资源复数**、小写、中划线分隔：`/api/orders`、`/api/order-items`。
- 动作类接口（非纯 CRUD）用动词短语放在资源后：`/api/orders/{id}/cancel`。
- 方法语义对应：查询 `GET`、创建 `POST`、全量更新 `PUT`、局部更新 `PATCH`、删除 `DELETE`。
- 参数来源注解明确：`@PathVariable` 路径参数、`@RequestParam` 查询参数、`@RequestBody` 请求体，不要混用凑数。
- **一个方法 ≈ 一个用例**；列表 VO 轻量，大块子资源走详情或其他接口。

### 1.4 参数校验

- 入参校验用 Bean Validation（`@Valid` / `@Validated`），校验注解写在 **模块 dto/request 类字段**上，不要在 Controller 方法体里手写 `if` 判断。
- 常用注解：`@NotNull` / `@NotBlank`（字符串）/ `@NotEmpty`（集合）/ `@Size` / `@Min` / `@Max` / `@Pattern` / `@Valid`（嵌套对象）。
- 校验失败由全局异常处理统一转错误响应，**禁止**每个 Controller 自己 `BindingResult` 手搓返回。
- Service 侧只校验**业务规则**（如「订单已发货不可取消」），不重复校验格式。

```java
public class CreateOrderRequest {
    @NotNull(message = "skuId 不能为空")
    private Long skuId;

    @NotNull @Min(1)
    private Integer quantity;

    @Valid                      // 嵌套对象必须加 @Valid 才会级联校验
    private AddressRequest address;
}
```

### 1.5 认证上下文

- 当前登录用户从**统一上下文**（如 `SecurityContext` / 项目封装的 `CurrentUser`）获取，Controller 不解析 Token、不查用户表。
- 权限校验交给统一机制（注解或拦截器），**禁止**在每个接口方法里手写 `if (!user.isAdmin())`。
- 用户 id 从上下文取，不信任前端传入的用户标识。

### 1.6 注释要求

- 类注释：用富文本 Javadoc 写清这组接口的归属资源与约束。
- 方法注释：写用途、关键入参含义、失败时返回什么错误码；**禁止**把方法名翻译成中文的一行流注释。
- 方法体内有分支或多步处理时，必须有编号步骤注释。

### 1.7 禁止

- 方法里堆业务规则、复杂查询、展示文案拼接。
- 注入其它模块 Controller / Mapper；Controller 不降级直调其它模块 Controller 或 Mapper。
- 在 Controller 里开事务、写 SQL、调 Mapper。
- 无调用方的死接口继续留在代码里。

### 1.8 命名

`{资源}Controller`，放在对应模块 `controller/` 包。方法名与路径语义一致。

---

## 2. Service（`service`）

**职责**：用例编排、业务流程实现、**事务边界**、协调 Mapper / 其它模块 Service / 外部 IO。同时是本模块对外的**门面**。

### 2.1 必须

- 一个对外方法 ≈ 一个用例；写操作明确事务；先校验再改数。
- 模块内协作：`A.service → B.service`，单向，不经过 Controller。
- **跨模块协作**：只经对方模块 Service 门面；纯共享表数据可跨模块**只读单表直查**（用全局单表 mapper），不触碰对方业务不变量。
- **依赖用构造器注入**（或 `@RequiredArgsConstructor` + `final` 字段）；**事务标注在本层 public 方法上**。
- 需要把字段更新为 `null` 时，使用能真正写出 null 的方式（如 `UpdateWrapper` / 字段策略）；禁止 update 被框架跳过 null 却当成功。
- 返回结构化原子字段；禁止 HTML/UI 展示拼接。
- 调用外部 Redis/HTTP/MQ 时：必须设置超时、明确失败处理与重试上限，并默认放在事务外执行。

### 2.2 用例方法的结构

一个用例方法按固定顺序组织，每段落用编号步骤注释标出：

```text
1️⃣ 校验：参数合法性 + 业务规则（状态是否允许、是否存在冲突）
2️⃣ 读取：取需要的领域对象（对应 Mapper 或其它模块 Service）
3️⃣ 变更：落库写操作（同一事务内）
4️⃣ 副作用：发消息 / 清缓存 / 通知（默认事务外）
5️⃣ 返回：组装 VO 或结果
```

- 校验与读取放在事务之前，**缩短事务持有时间**。
- 副作用（消息、通知、缓存失效）默认放到事务提交之后，失败不应回滚已完成的业务写。

### 2.3 事务要点

```text
连贯 DB 写 → 同一事务
外部 HTTP / MQ → 默认事务外，避免长事务长期占用数据库连接
```

- 事务边界在 Service 方法上；同类自调用不会触发事务（需经外部 Bean 调用）。
- 抛出的异常要能让事务感知：受检异常需显式声明回滚，禁止 `catch` 后吞掉还指望回滚。

### 2.4 方法组织

- 方法目的单一，避免混杂 HTTP + DB + 业务 + 格式化。
- 一个方法承担过多步骤（步骤注释超过 7 步）时，先考虑拆出私有方法或独立组件，而不是继续加注释。
- 私有方法放在它**第一次被使用**的位置附近，不要全堆到类底部。

### 2.5 幂等

- 写操作若可能被重复触发（重试、消息重投、用户连点），必须有幂等保障：业务唯一键、状态机判断或幂等表。
- 重复调用的结果应与首次一致，**禁止**重复扣减、重复下单、重复发通知。

### 2.6 模块间协作与分层调用

**模块内调度单向递减**：`controller → service → (模块内 mapper 联表 | 全局单表 mapper) → DB`。

**跨模块协作（按优先级）：**

1. `A.service → B.service`（default，经对方门面调用业务用例）
2. 纯共享表数据可跨模块**只读**单表直查（用全局单表 mapper + entity），不涉及对方业务不变量
3. 任一层 → `common` / `config` / `security`（枚举 / 错误码 / 纯技术能力；禁止塞业务规则）

**禁止：**

- `controller → controller`、`controller → 其它模块 mapper`
- `service → 其它模块 controller`（反向调用，破坏单向递减）
- 穿透其它模块内部类（如 `A.service` 直接用 `B` 模块的内部 mapper）
- 跨模块无边界复用他人 Request / VO（需要复用 → 经对应模块 Service 暴露）
- `common` / `config` / `security` 反向依赖业务模块
- 模块间成环依赖（成环则把共享部分下沉到 `common`，或改由更高层编排）

```text
依赖总纲

controller → service → (模块 mapper 联表 | 全局单表 mapper) → DB   √ 单向递减
业务模块 → common / config / security / entity / 全局单表 mapper   √
业务模块 → 其它业务模块：只经对方 service 门面；共享表只读单表直查    √
模块间穿透（A 直接用 B 的内部 mapper/类）                          ×
service → 其它模块 controller                                    ×
common / config / security → 业务模块                             ×
```

**选型口诀：**

1. 要 B 的业务规则或受保护数据 → **B.service**
2. 纯共享表、单表只读、无规则 → **全局单表 mapper 直读**（仅当不触碰 B 的业务不变量）
3. 其它歪路 → 不用

### 2.7 禁止

- 上帝 Service；规则拆散到 Controller / Mapper。
- 无充分理由把长时间 HTTP/RPC 塞进 DB 事务。
- 假设 `this.xxx()` 会生效 `@Transactional` / `@Async` / `@Cacheable`。
- 业务用例藏进无边界 Helper。
- 在 Service 里感知 HTTP 层（不碰 `HttpServletRequest` / 响应包装细节）。
- 跨层穿透与成环（见 §2.6）。

### 2.8 命名

`{能力}Service`，放在对应模块 `service/` 包。`Manager` 必须有功能前缀，且不替代 Service 入口职责。

---

## 3. DTO（`dto`）

**职责**：各层流转的类型形态（与 §1 配套）。按用途分放 `dto.request` / `dto.query` / `dto.response`。DTO 按所属模块划分，模块间契约复用经对方 Service 门面暴露。

### 3.1 分类与命名

| 类型 | 用途 | 命名 | 放哪 |
|------|------|------|------|
| Request | 写操作入参 | `CreateOrderRequest` / `CancelOrderRequest` | 模块 `dto.request` |
| Query | 列表查询条件 | `OrderQuery` | 模块 `dto.query` |
| VO | 接口出参 | `OrderDetailVO` / `OrderListItemVO` | 模块 `dto.response` |
| Row | 联表查询投影 | `OrderWithUserRow` | 发起模块的 `dto` |

### 3.2 必须

- Request / VO 分开，**禁止**一个类既当入参又当出参。
- 校验注解放 Request（见 §1.4）；VO 不带校验注解。
- 组装转换在模块 Service（或明确的组装点），**禁止**在 Controller 里逐个字段 `set`。
- 字段与**已约定契约**一致，不擅自增删字段。

### 3.3 禁止

- Entity / `Map` 当契约。
- 巨型 DTO 打天下（一个 VO 塞进所有场景的字段）。
- 跨模块无边界复用他人 Request / VO（应经对应模块 Service 暴露契约，不直接搬运）。
- 无意义硬拆凑类（一个字段也要建个 DTO）。

### 3.4 字段类型选择

| 语义 | 类型 | 禁止 |
|------|------|------|
| 金额 | `BigDecimal` | `double` / `float` |
| 时间 | `LocalDateTime` / `LocalDate` | `Date` / `String` 手工拼 |
| 状态/类型 | 枚举 | `int` / `String` 魔法值 |
| 主键 | `Long` | 用 `String` 存数字 id |
| 是否 | `Integer`(0/1) 或 `Boolean`，全项目统一 | 同一项目两种混用 |

### 3.5 序列化约定

- 日期时间统一序列化格式（如 `yyyy-MM-dd HH:mm:ss`），全项目一致，不要有的接口时间戳有的字符串。
- 前端不需要的字段不要返回（特别是敏感字段：密码、内部状态、成本价）。
- 数值字段按需保留小数位，不要直接把 `BigDecimal` 原样吐出导致精度不一。

---

## 4. Entity / Mapper

**默认持久化栈：MyBatis-Plus（MP）`BaseMapper` + Lambda（简单单表）+ Mapper XML（仅联表/复杂 SQL）。**

**持久化分轨原则**：单表查询走**全局单表 mapper**（继承 MP `BaseMapper` + Lambda）；多表联查 / 复杂 SQL 走**发起模块的模块内 mapper**（配 XML）。

### 4.1 Entity（全局，放外面）

- 与表映射；通常继承项目约定的 MP 基类（若有）；不依赖 Spring/HTTP；**不做 API 出入参**。
- 全模块共用同一套 entity；跨模块只读共享表就是引这套 entity + 全局单表 mapper 做单表查询。
- 字段与列对应；用 MP 元数据/Lambda 可引用的属性名，避免魔法列名散落。
- 写入值与列类型/格式一致（如 JSON 列不要写入非法空串）。
- 命名与领域一致；禁无意义叠词。
- 字段类型遵循 §3.4（金额 `BigDecimal`、时间 `LocalDateTime`、状态用枚举并配枚举处理器）。
- 逻辑删除字段由 MP 统一配置，**禁止**在每个查询里手写 `eq("is_deleted", 0)`。

### 4.2 Mapper 分轨：全局单表 vs 模块内联表

| 角色 | 位置 | 职责 | 写法 |
|------|------|------|------|
| **全局单表 mapper** | 根包 `mapper/` | 单表 CRUD、条件查询、COUNT、存在判定 | `extends BaseMapper<Entity>`，Service 内 Lambda 调用 |
| **模块内 mapper** | 模块 `order/mapper/` | 多表联查、复杂单表、聚合、子查询、分页 SQL | 配 XML，不继承 BaseMapper（但能定位 statement） |

**全局单表 mapper（强制规则）：**

- **每一个** `@Mapper` 接口 `extends BaseMapper<对应 Entity>`。
- **只做单表查询**：单表 CRUD、条件查询、单表 COUNT、存在判定、单表条件更新/删除。
- **禁止**写联表 SQL、禁止写无 JOIN 的简单单表查询（后者直接用 Lambda 即可）。
- 命名：`{Entity}Mapper`（如 `OrderMapper`、`UserMapper`）。

```java
// ✅ 全局单表 mapper：仅单表
@Mapper
public interface OrderMapper extends BaseMapper<Order> {
    // 没有自定义方法 —— 单表直接用 BaseMapper + Lambda
}
```

**模块内 mapper（联表/复杂 SQL）：**

- 专门承载**多表 JOIN、聚合、子查询、复杂分页**等一次性或业务相关的持久化操作。
- 放在发起查询的模块 `mapper/` 包下，接口名含业务语义（如 `order/mapper/OrderDetailMapper`）。
- 不继承 `BaseMapper`（XML 中 `namespace` 指向该接口即可），但方法返回明确类型（Entity 子集、`XxxRow`），**禁 `List<Map>` 对外**。
- 简单单表走全局单表 mapper，**不要**为省事塞进模块内 mapper。

```java
// ✅ 模块内 mapper：联表/复杂 SQL
@Mapper
public interface OrderDetailMapper {
    List<OrderDetailRow> listDetailByUserId(@Param("userId") Long userId);
}
```

```xml
<!-- 配 XML，namespace 指向模块内 mapper -->
<mapper namespace="com.xxx.order.mapper.OrderDetailMapper">
    <select id="listDetailByUserId" resultType="com.xxx.order.dto.OrderDetailRow">
        SELECT o.id, o.status, oi.sku_name, oi.quantity
        FROM orders o
        LEFT JOIN order_item oi ON oi.order_id = o.id
        WHERE o.user_id = #{userId}
        ORDER BY o.created_at DESC
    </select>
</mapper>
```

### 4.3 查询怎么写（强制分轨）

| 场景 | 写法 | 说明 |
|------|------|------|
| **简单单表**（`eq`/`in`/可空条件、单表 COUNT、单表条件 UPDATE/DELETE、单列列表） | **模块 Service 内** 全局单表 mapper + `LambdaQueryWrapper` / `LambdaUpdateWrapper` | **禁止**为此在模块内 mapper 加方法、**禁止**写 XML |
| **联表 / 多表** | **默认模块内 mapper + XML** | JOIN、多表过滤、聚合、复杂排序/分页在 SQL 一次完成 |
| **复杂单表**（重聚合、子查询、`INSERT…SELECT`、多表 UPDATE JOIN 等） | 优先模块内 mapper + XML | 不要为了「全用 Lambda」把 SQL 拧成不可读 |

```text
✅ 单表：orderMapper.selectList(new LambdaQueryWrapper<Order>().eq(Order::getStatus, status))
✅ 单表 COUNT：orderMapper.selectCount(lambda…)；禁 XML 再包一层
✅ 联表：OrderDetailMapper.xml 里 JOIN + WHERE + 分页；返回 OrderDetailRow / 明确类型
✅ 跨模块只读共享表：用全局单表 mapper + entity 做单表条件查询（不涉及对方业务不变量）
❌ 无 JOIN 的简单 SELECT/COUNT/UPDATE 写进模块内 mapper XML
❌ 全局单表 mapper 写联表方法（违反分轨）
❌ 先 selectList 表 A，再按 id 循环 select 表 B（N+1）
❌ 两次（或多次）单表查出 List，再在 Java 里 for/stream 做关联、拼装「假 JOIN」
❌ 用 selectMaps / List<Map> 当对外或跨模块契约
❌ Mapper XML 使用 `<sql>` / `<include refid>` 抽公共片段
```

**决策口诀（写 Mapper 前先问）：**

1. 只有一张表、且条件/更新可用 Lambda 表达？→ **模块 Service 内调全局单表 mapper + Lambda**，不要碰 XML。
2. 需要第二张表的列、JOIN、EXISTS、聚合跨表？→ **模块内 mapper + XML**。
3. 「联表必须 XML」**不等于**「本模块所有查询都进模块内 mapper」；简单单表兄弟查询仍归全局单表 mapper + Lambda。

**绝对禁止：两个（或多个）单表查询，再在内存里关联数据。**  
关联、聚合、按关联条件过滤/排序/分页 → 必须在 SQL（XML）完成。

### 4.4 Mapper 职责与其它红线

- **全局单表 mapper**：只做单表持久化；**不写业务编排、不调 Service**。
- **模块内 mapper**：只做持久化查询；**不写业务编排、不调 Service、不调其它模块 mapper**。
- 方法名表意：`selectById`、`countByStatus`、`listDetailByOrderId`；禁 `query1`。自定义方法仅用于 XML 联表/复杂 SQL。
- 联表/投影结果：优先明确类型（Entity 子集、`XxxRow`）；禁 `List<Map>` 对外。
- 只要数量 → 单表用全局单表 mapper `selectCount(lambda)`；跨表用模块内 XML `COUNT`；禁 `selectList` 再 `.size()`。
- 需要更新为 `null`：用能写出 null 的更新方式（`LambdaUpdateWrapper` set 等 / 字段策略），禁止「调用了 update 但 null 被跳过」。
- XML 文件路径与 Java mapper 包结构保持一致；复杂 SQL 需注释说明「为什么这样写」（JOIN 组织、条件位置、分页策略）。
- **禁止** MyBatis `<sql>` 片段与 `<include refid="…"/>`。每条语句写完整 SQL；列清单重复可接受，换可读与可搜，不要跨语句抽公共片段。

### 4.5 Service 侧使用约定

- 单表 CRUD/条件查询/条件更新：模块 Service 内用全局单表 mapper + Lambda 调对应 Entity 的 Mapper；**不要**为此在模块内 mapper 声明空壳方法再转 XML。
- 一涉及第二张表的数据拼装：先写/调 **模块内 mapper + XML 联表（或一次 SQL）**，不要在 Service 里二次查询再 merge。
- 分页：单表可用全局单表 mapper + MP 分页；联表分页在模块内 XML 用数据库分页，避免先全量再内存 page。
- 批量写用批量方法（如 MP `saveBatch` 并在 JDBC 参数开启批量），**禁止**循环里逐条 `insert`。

---

## 5. config / security / common

| 包 | 放什么 | 职责边界 | 红线 |
|----|--------|----------|------|
| `config/` | 框架与中间件的全局装配类、开关 | 只装配与开关，**不写业务用例**（不查业务表、不推流程）；一类中间件一个配置类，名如 `RedisConfig` / `MybatisPlusConfig`；密钥、地址、超时全部走外部配置，不写死在代码里 | 禁 `AllConfig` 大杂烩；禁在配置类里调 Service |
| `security/` | 认证鉴权基础设施、Filter、Token 处理 | 只做身份识别与权限判定，**不写业务用例**；日志不打 Token 与凭据 | 禁在业务 Service 里手搓鉴权；禁把业务规则塞进 Filter |
| `common/` | 跨模块/全局真正共用的内核：统一响应 `Result`、分页 `PageResult`、业务异常、错误码、全局枚举/常量、领域事件、极少数无业务纯函数 | **跨模块/全局真正共用才上收**（响应体、异常体系这类每层都依赖的通用件必上收）；保持极薄 | 禁 `CommonUtils` 之类无前缀垃圾桶；禁塞入某个业务模块专有的规则 |

**判断口诀**：一个东西只有一处用 → 留在原地（模块内私有方法 / 局部）；确实多处复用且无业务语义 → `common`；带业务规则 → 归对应模块 Service，不是工具类。

---

## 6. 异常与空值

### 6.1 异常体系

- 业务失败抛**业务异常**（携带错误码），由全局异常处理器统一转响应；**禁止**每个 Controller 自己 try-catch 拼错误返回。
- 异常链保留 `cause`，不要 `throw new BizException(e.getMessage())` 丢掉原始堆栈。
- 错误码按业务域分段，同一错误码含义唯一；**禁止**复用错误码表示不同问题。
- 对外只暴露错误码与可读 message，**禁止**把堆栈、SQL、内部类名吐给前端。

### 6.2 禁止

- 万能 `catch (Exception e)` 后只打日志不再抛出/映射。
- 用异常做正常流程控制（如用 catch 判断「是否存在」）。
- 吞掉异常返回默认值，让调用方以为成功。

### 6.3 空值

- 查询无结果返回空集合 / `Optional` / 明确空 VO，**禁止返回 `null`**。
- 集合返回值永远非 null；项目内对「空集合 vs null」的约定保持一致。
- `Optional` 用于返回值表达「可能没有」；**禁止**用作方法参数、字段类型或 `ifPresent` 里写业务逻辑。
- 判空用 `Objects.equals` / `StringUtils.hasText` 等工具，避免手写 `x != null && !x.equals("")` 这类冗长判断。

### 6.4 失败可观测

- 失败日志需带关键业务上下文（业务 id、操作、失败原因）与正确级别，且不记录密码/Token/密钥等敏感信息。
- 重要决策（事务边界、非常规写法、变通方案）需有「为什么」的注释。

---

## 7. 设计模式与 SOLID（务实）

- 模式用于降低真实复杂度（多实现、稳定边界、可测隔离），**不为「看起来专业」或「企业级通常这样」而加**。
- SOLID 务实用：只有一个简单实现时，不要自动 `接口 → Impl → Factory → Strategy → Manager` 一条龙。
- 类有连贯职责；**不要仅因文件长就拆**；职责/生命周期真正受益时再拆（见 §0.2 拆类三条件）。
- 方法目的单一；避免混杂 HTTP+DB+业务+格式化；不要机械行数上限——30 行清楚的方法可以好过 5 个抽象糟糕的 6 行方法。

---

## 8. Java 通用写法

### 8.1 Stream

- 能提升可读性时再用；不要用 Stream 把简单逻辑伪装得很高级。
- **禁止**在 Stream 中藏：数据库查询、网络请求、复杂副作用、嵌套业务编排。
- 尤其禁止 `stream().map(id -> orderMapper.selectById(id))` 制造 N+1。
- 链式超过 3~4 个操作时，考虑拆成多行或改用普通循环，可读性优先于「函数式」。

### 8.2 集合

- 按语义选 List/Set/Map 等；考虑顺序、重复、查找与内存。
- 需要按 key 查找时用 `Map`，**禁止**对 List 反复遍历查找（数据量小且一次性除外）。
- 不要无理由反复转换集合；不要默认把大结果集整表装进 `List` 再处理。
- 返回集合时优先返回不可修改视图或新集合，避免暴露内部可变状态。

### 8.3 并发与线程池

- **默认不要**引入并发；上之前想清：是否独立、CPU 还是 IO、上限、失败与取消。
- 禁止随意使用无界/共享线程池；生产异步必须有：核心/最大线程、队列、拒绝策略、线程命名、关闭与监控意识。
- 禁止对阻塞 IO 随手 `CompletableFuture.supplyAsync(...)` 却不指定有界执行器。
- 共享可变状态需明确同步策略；**禁止**用局部变量以外的 `SimpleDateFormat` 等非线程安全对象做全局共享。

### 8.4 JVM 与内存意识

- 避免：加载超大数据集 → 多份拷贝 → 反复转换 → 一次性序列化巨物。
- 优先：SQL 分页、批量、流式/增量处理（按场景）。
- 性能先盯 DB/网络/IO/内存与算法；不要过早优化微操作。

### 8.5 金额与数值

- 金额一律 `BigDecimal`，**禁止** `double` / `float` 参与金额计算。
- `BigDecimal` 比较大小用 `compareTo`，**禁止**用 `equals`（`equals` 会比较精度，`1.0` 与 `1.00` 不相等）。
- 金额运算显式指定精度与舍入模式（如 `setScale(2, RoundingMode.HALF_UP)`），不要依赖默认行为。
- 除法必须指定精度与舍入模式，否则可能抛 `ArithmeticException`。

### 8.6 时间处理

- 一律用 `java.time` 包（`LocalDateTime` / `LocalDate` / `Instant`），**禁止** `Date` / `Calendar` / `SimpleDateFormat`。
- 计算时间用 `plusDays` / `between` 等方法，禁止手工毫秒数加减。
- 涉及跨时区或存储统一用 UTC/服务器时区二选一并全项目一致，不要混用。

### 8.7 相等与比较

- 对象比较用 `Objects.equals(a, b)`，避免空指针。
- 枚举比较用 `==`，字符串比较用 `equals`（常量放前面或 `Objects.equals`）。
- 重写 `equals` 必须重写 `hashCode`；用于 `Set`/Map key 的类必须保证字段稳定。

---

## 9. 编写前 / Review 核对

**命名与结构**

- [ ] 类/方法/常量命名有前缀与语义；无光秃 Manager/Helper/Util  
- [ ] 抽象与模式有**当前**理由；无空 `Service`+`Impl`、无堆砌 Factory/Strategy  
- [ ] 持久化分轨：单表走全局单表 mapper（`extends BaseMapper` + Lambda）；联表/复杂 SQL 走发起模块的模块内 mapper + XML  
- [ ] 无全局单表 mapper 写联表、无模块内 mapper 写简单单表  
- [ ] 调度单向：controller → service → (模块 mapper 联表 | 全局单表 mapper)；跨模块只经 Service 门面；无反向、无穿透、无成环  

**Controller / API**

- [ ] 统一 Result/分页；无 `Map`；校验失败可感知；列表有分页形态  
- [ ] 路径与 HTTP 方法语义正确；入参用模块 Request + `@Valid`  
- [ ] Controller 无业务、无事务、无 SQL；当前用户从统一上下文取  

**Service**

- [ ] 用例结构清晰：校验 → 读取 → 变更 → 副作用 → 返回  
- [ ] 写操作事务边界正确；外部调用有超时与失败处理且默认在事务外  
- [ ] 构造器注入；`null` 更新真生效；可重复触发的写操作有幂等  
- [ ] 无展示拼接；未感知 HTTP 层  

**持久化**

- [ ] 全局单表 mapper 均 `extends BaseMapper`；无联表；无自定义方法改写简单单表  
- [ ] 模块内 mapper 配 XML；SQL：联表完整 JOIN；无 `<sql>`/`<include>`；**无二次单表内存关联**；无 N+1；Stream 无 IO  
- [ ] 计数用 COUNT；分页在数据库完成；批量写未退化为循环单条  

**通用**

- [ ] 金额用 `BigDecimal` 且 `compareTo` 比较；时间用 `java.time`  
- [ ] 无魔法值；状态用枚举；无双轨死代码；无假数据  
- [ ] 业务未进 config/security/common；工具类有功能前缀  
- [ ] 重要决策有「为什么」注释；失败日志有上下文且不泄密  

---

**打回语**

- 「对外契约出现 Map，打回。」  
- 「展示拼接不应出现在 Service。」  
- 「全局单表 Mapper 未继承 BaseMapper，打回。」  
- 「全局单表 Mapper 写了联表，打回；联表放发起模块的模块内 mapper。」  
- 「简单单表必须 Lambda；禁止无 JOIN 的 SQL 进模块内 XML。」  
- 「Mapper XML 禁用 `<sql>` / `<include>`，语句写完整。」  
- 「联表必须 XML；禁止两次单表再在内存关联。」  
- 「关联/计数写 SQL；Stream/循环里不准查库。」  
- 「金额用了 double，改 BigDecimal。」  
- 「BigDecimal 用 equals 比较，改 compareTo。」  
- 「Controller 里写了业务规则，下沉到模块 Service。」  
- 「校验写在方法体里，改用 `@Valid` + Request 注解。」  
- 「查询无结果返回了 null，改空集合/Optional。」  
- 「重复调用会重复扣减，补幂等。」  
- 「外部调用没有超时和失败处理。」  
- 「不要兼容旧版，直接改契约/表/脚本。」  
- 「接口延迟或调用次数不可接受，先改查询路径。」  
- 「光秃 Helper/Manager，补功能前缀。」  
- 「不要为未出现的需求堆 Factory/Strategy。」  
- 「注释只是复述方法名，改成富文本写清失败行为与副作用。」  
- 「方法体多步处理无步骤注释，补编号注释。」  
- 「跨模块穿透了，只经对方 Service 门面。」  
- 「单表查全局单表 mapper 就够了，不需要塞进模块内 mapper。」  

有一条做不到 → 先改写法，再提交。