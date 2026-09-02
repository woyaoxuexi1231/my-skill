# Java 模块代码规范

> 前提：包与调用方向见 `Java-代码架构.md`。  
> 本篇：**各层怎么写** + Java 通用写法（模式/Stream/并发/内存等）。  
> 分册：`Java-日志与注释规范.md` · `Java-外部调用规范.md` · `Java-Spring规范.md` · `Java-配置与工程规范.md` · `Java-SpringSecurity规范.md`。  
> 表结构 / 索引 / SQL：见 `../MySQL-生产级规范/MySQL-数据库规范.md`。  
> **不管**：业务该怎么规划；业务若强制要求，按要求实现，但仍须符合本篇写法。

---

## 0. 通例

### 0.1 命名

- 类名必须带**具体能力/业务前缀**，后缀可用 `Service` / `Controller` / `Mapper` / `Manager` / `Helper` / `Common` 等。
- **允许**：`OrderInventoryManager`、`TokenRefreshHelper`、`PageQueryCommon`
- **禁止**：光秃的 `Manager`、`Helper`、`Common`、`Util`、`Handler`、`Processor`；以及无前缀的 `CommonUtils` 等垃圾桶。
- 方法名说意图：`calculateOrderTotal()`；禁 `doProcess()` / `handle()` / `data` / `temp` / `obj`。
- 命名不以 `_` / `$` 起止；禁止拼音英文混用、禁止中文标识符（国际通用拼音名如 `alibaba` 可视同英文）。
- 类名 `UpperCamelCase`（`DO` / `DTO` / `VO` / `BO` / `AO` 例外）；方法/参数/成员/局部变量 `lowerCamelCase`。
- 常量全大写 + 下划线，语义写全：`MAX_STOCK_COUNT`（禁含糊的 `MAX_COUNT`）。
- 抽象类 `Abstract`/`Base` 开头；异常 `Exception` 结尾；测试类以被测类名开头、`Test` 结尾。
- 数组类型：`String[] args`（禁 `String args[]`）。
- POJO 布尔属性**不要**加 `is` 前缀（如用 `deleted`，勿 `isDeleted`），避免部分框架序列化踩坑；库表 `is_xxx` 见 MySQL 规范，ORM 做字段映射。
- 包名全小写，点分隔；见名知意，禁随意缩写（`AbstractClass` 勿写成 `AbsClass`）。
- Service/Mapper 方法前缀约定：`get` 单个、`list` 多个、`count` 统计、`save`/`insert` 插入、`remove`/`delete` 删除、`update` 修改。
- 领域对象后缀：表模型 `XxxDO`（或项目统一的 Entity 名）、传输 `XxxDTO`、展示 `XxxVO`；禁笼统 `XxxPOJO`。

### 0.2 一类一事与抽象

一个类一种角色：入口 / 用例 / 持久化 / 装配 / 安全 / 契约。

- **默认**：一个实现 → 具体类注入即可，不为「企业范」先抽接口。
- **允许先有接口的例外**：框架要求、稳定跨模块边界、可测隔离外部依赖——且能说清**当前**理由。
- **禁止**：为未提出的多实现需求堆 `Factory` / `Strategy` / `Registry` / 空 `Service`+`Impl`。

### 0.3 失败与契约底线

- 业务失败 → 业务异常 + 错误码；禁吞异常；禁用 `null`/魔法布尔冒充失败。
- 对外禁止 `Map` / `JSONObject`；禁止 Entity 直接当 API 出入参。
- 替换契约时清掉双轨与死代码（代码整洁，不是替业务决定能否改契约）。

### 0.4 通用编码红线

| 禁止 | 正确做法 |
|------|----------|
| 先糊再重构；TODO/空实现冒充完成 | 按规范一次写到可维护 |
| Service/VO 拼 HTML 或 UI 展示串 | 返回原子字段；展示交前端或专门渲染层 |
| 单表大查再内存过滤；循环/Stream 里按条查库；**多次单表再内存关联** | 单表 MP+Lambda；联表 XML 一次 SQL；计数用 COUNT |
| 未用到的缓存/MQ/异步/多余抽象先堆上 | 当前用到再加 |
| 假数据冒充真实业务结果 | 按契约返回空/明确无 |
| 列表灌详情；`list.size()` 冒充计数 | 列表与详情分离；计数用 COUNT |
| 魔法值散落代码 | 提取有意义常量/枚举 |
| `long` 字面量用小写 `l` | 用大写 `L`（`2L`，防看成 `21`） |

### 0.5 OOP 要点

- 覆写必须 `@Override`；过时 API 不用，对外过时接口加 `@Deprecated` 并写清替代。
- `equals`：用常量/`Objects.equals` 调，防 NPE（`"test".equals(obj)` / `Objects.equals(a, b)`）。
- 包装类型之间比**值**一律 `equals`，禁用 `==`（缓存区间外必踩坑）。
- POJO / RPC 出入参属性用**包装类型**；局部变量可用基本类型。POJO **不要**给属性设业务默认值（易在「部分更新」时脏写创建时间等）。
- 构造器禁止塞业务逻辑；需要初始化 → 明确 `init`/工厂，不在构造里查库推流程。
- 浮点金额/精确小数：用 `BigDecimal`（字符构造或 `valueOf`）；禁 `new BigDecimal(0.1)` 这种二进制误差；禁用 `float`/`double` 做金额。
- 静态成员用**类名**访问，不用实例引用访问。

### 0.6 控制语句

- `if` / `for` / `while` / `switch` / `do` **即使一行也加大括号**。
- `switch`：每个 `case` 终结（`break`/`return`）或注明 fall-through；必须有 `default`（即使空）。
- 异常分支少用层层 `if-else`；卫语句早退；逻辑判断超过约 3 层考虑拆方法/策略，勿堆金字塔。
- 条件尽量赋给有意义布尔变量再判断，提升可读性。
- 循环内不做重复的重对象创建、反复取连接、把本可提出循环的 `try-catch` 套在整圈上（除非刻意按条容错）。
- **参数校验**：对外 API / RPC / 权限入口必须校验；高频私有/底层 DAO 同应用内可省略重复校验（调用方已保证时）。

---

## 1. Controller（`module.{x}.controller`）与 API 契约

**职责**：HTTP——解析请求、触发校验、取认证上下文、调**本模块** Service、映射响应。

### 1.1 统一响应与分页

- 统一包装：如 `{ "code", "message", "data" }`（字段名以项目为准，全项目一致）。
- 业务失败：明确 `code` + 可读 `message`；校验失败必须能被调用方感知，禁止「HTTP 200 + 空成功」掩盖业务失败（若项目约定失败也走 200+业务码，则业务码与 message 必须非成功态）。
- 分页统一：如 `PageResult<T>{ records, total, pageNum, pageSize }`；列表接口禁止无界全量当默认。

### 1.2 出入参必须是类型

```text
✅ Result<OrderDetailVO>
✅ @Valid @RequestBody CreateOrderRequest
❌ Result<Map<String, Object>>
❌ @RequestBody Map<String, ?>
❌ 同模块有的接口有 Request、有的用 Map
```

- 入参：本模块 Request + `@Valid`（或统一校验）。
- 出参：`Result` / `PageResult` + VO；字段与**已约定契约**一致（多了少了都算实现偏差）。
- Entity 不做出入参；禁止临时改成 `Map` 凑合。

### 1.3 接口形态

- `@RestController`；路径与方法语义清晰；**一个方法 ≈ 一个用例**。
- 每个接口有简短说明（注释/文档注解）写明用途。
- 列表 VO 轻量；大块子资源走详情或其他接口。
- 设计接口时先想清：谁调用、成功/失败什么样、是否列表/分页、字段从哪来——再动手。
- 简单业务保持简单接口；不要为了「看起来细」拆成一堆半截补丁接口（除非契约明确需要）。

### 1.4 禁止

- 方法里堆业务规则、复杂查询、展示文案拼接。
- 注入其他模块 Controller / Mapper；Controller 直调外模块 Service。
- 无调用方的死接口继续留在代码里。

### 1.5 命名

`{资源}Controller`。方法名与路径语义一致。

---

## 2. Service（`module.{x}.service`）

**职责**：用例编排、业务流程实现、**事务边界**、协调 Mapper / 他模块 Service / 外部 IO。

### 必须

- 一个对外方法 ≈ 一个用例；写操作明确事务；先校验再改数。
- 跨模块：`A.service → B.service`（或约定门面）。
- 需要把字段更新为 `null` 时，使用能真正写出 null 的方式（如 `UpdateWrapper` / 字段策略）；禁止 update 被框架跳过 null 却当成功。
- 返回结构化原子字段；禁止 HTML/UI 展示拼接。
- 外部 Redis/HTTP/MQ：遵守 `Java-外部调用规范.md`；框架事务/注入：遵守 `Java-Spring规范.md`。

### 禁止

- 上帝 Service；规则拆散到 Controller / Mapper。
- 无充分理由把长时间 HTTP/RPC 塞进 DB 事务。
- 假设 `this.xxx()` 会生效 `@Transactional` / `@Async` / `@Cacheable`。
- 业务用例藏进无边界 Helper。

### 命名

`{能力}Service`。`Manager` 必须有功能前缀，且不替代 Service 入口职责。

### 事务要点

```text
连贯 DB 写 → 同一事务
外部 HTTP / MQ → 默认事务外（详见外部调用规范）
```

---

## 3. DTO（`module.{x}.dto`）

**职责**：本模块 API 契约的类型形态（与 §1 配套）。

- Request / VO 分开；命名如 `CreateOrderRequest`、`OrderDetailVO`。
- 校验注解放 Request；组装转换在 Service（或明确组装点）。
- 禁止：Entity/`Map` 当契约；巨型 DTO 打天下；外模块 import 本模块 Request/VO；无意义硬拆凑类。

---

## 4. Entity / Mapper / biz

**默认持久化栈：MyBatis-Plus（MP）+ Mapper XML（联表/复杂 SQL）。**

### 4.1 Entity

- 与表映射；通常继承项目约定的 MP 基类（若有）；不依赖 Spring/HTTP；**不做 API 出入参**。
- 字段与列对应；用 MP 元数据/Lambda 可引用的属性名，避免魔法列名散落。
- 写入值与列类型/格式一致（如 JSON 列不要写入非法空串）。
- 命名与领域一致；禁无意义叠词。

### 4.2 查询怎么写（强制分层）

| 场景 | 写法 | 说明 |
|------|------|------|
| **简单单表** | MP + `LambdaQueryWrapper` / `LambdaUpdateWrapper`（或等价 Lambda 链式） | 方便、列变更可编译期/重构感知；条件清晰 |
| **联表 / 多表** | **默认 Mapper XML 写 SQL** | JOIN、多表过滤、聚合、复杂排序/分页在 SQL 一次完成 |
| **复杂单表**（重聚合、子查询、精细分页统计等） | 优先 XML | 不要为了「全用 Lambda」把 SQL 拧成不可读 |

```text
✅ 单表：mapper.selectList(Wrappers.lambdaQuery(Entity.class).eq(Entity::getStatus, status))
✅ 联表：XxxMapper.xml 里 JOIN + WHERE + 分页；返回 Entity / XxxRow / 明确类型
❌ 先 selectList 表 A，再按 id 循环 select 表 B（N+1）
❌ 两次（或多次）单表查出 List，再在 Java 里 for/stream 做关联、拼装「假 JOIN」
❌ 用 selectMaps / List<Map> 当对外或跨层契约
```

**绝对禁止：两个（或多个）单表查询，再在内存里关联数据。**  
关联、聚合、按关联条件过滤/排序/分页 → 必须在 SQL（XML）完成。

### 4.3 Mapper 职责与其它红线

- Mapper 只做持久化与查询；**不写业务编排、不调 Service**。
- 方法名表意：`selectById`、`countByStatus`、`listDetailByOrderId`；禁 `query1`。
- 联表/投影结果：优先明确类型（Entity 子集、`XxxRow`）；禁 `List<Map>` / `HashMap` 当查询结果契约。
- 只要数量 → `COUNT`（XML 或 MP）；禁 `selectList` 再 `.size()`。
- 需要更新为 `null`：用能写出 null 的更新方式（`LambdaUpdateWrapper`  set 等 / 字段策略），禁止「调用了 update 但 null 被跳过」。
- XML：查询字段写清，禁 `SELECT *`；参数用 `#{}`，**禁 `${}` 拼接**（防 SQL 注入）。
- 更新只改需要的字段，禁无差别全字段大而全 update；有 `gmt_modified`/`update_time` 则一并更新。
- XML 路径与 `module.*.mapper` 包对应（见架构文档）；建表/索引/SQL 语句细则见 `../MySQL-生产级规范/MySQL-数据库规范.md`；复杂 SQL 按需加「为什么」注释（见日志与注释规范）。

### 4.4 Service 侧使用约定

- 单表 CRUD/条件查询：Service 内用 MP + Lambda 调本域/`biz` Mapper 即可。
- 一涉及第二张表的数据拼装：先写/调 **XML 联表（或一次 SQL）**，不要在 Service 里二次查询再 merge。
- 分页：单表可用 MP 分页；联表分页在 XML 用数据库分页，避免先全量再内存 page。

### 4.5 biz

- 放跨端共享的 Entity / Mapper（及必要 Row）。
- 触及某业务模块不变量的更新 → 经该模块 Service，不直捅私有持久化绕过规则。

---

## 5. config / security / common / support

| 包 | 要点 | 细则 |
|----|------|------|
| `config/` | 只装配与开关；一类一配置类；密钥不进代码 | `Java-配置与工程规范.md` · `Java-Spring规范.md` |
| `security/` | 认证鉴权基础设施集中；不写业务用例；日志不打 Token | 载荷内容属方案，不属本篇 |
| `common/` | Result/异常/跨模块枚举等；≥2 模块共用才上收；禁无前缀 CommonUtils | — |
| `support/` | 同模块共享小能力；功能前缀命名；升用例则改 Service | — |

---

## 6. 异常与空值

- 保留 cause；映射统一错误模型；该回滚则回滚。
- 禁万能 `catch` 后只打日志；禁对外暴露堆栈与内部细节。
- 空值显式处理；浅控制流；集合空值约定项目内一致。
- 日志与注释：`Java-日志与注释规范.md`。

### 6.1 异常处理（强制习惯）

- 能预检查规避的运行时问题（空指针、越界）→ 先判断，不要靠 `catch` 当分支。
- **禁止**用异常做普通流程/条件控制。
- `try-catch` 包不稳定代码，区分异常类型处理；不要大段代码一锅端。
- 捕获是为了处理：要么恢复/映射业务异常，要么上抛；最外层转成用户可理解的错误。
- 事务内 `catch` 后若需回滚 → **显式回滚**（勿以为进了 catch 就自动回滚）。
- 资源关闭：优先 try-with-resources；`finally` 里**禁止** `return`。
- catch 类型与抛出匹配（同类或父类）；禁裸抛 `Exception` / `Throwable` / 无业务含义的 `new RuntimeException()`，用项目业务异常。
- 对外 HTTP/API：**错误码**；应用内可抛业务异常；跨应用 RPC 优先 `Result`（成功标志 + 码 + 短消息）。

### 6.2 NPE 防呆

留意：包装拆箱、DB 查询可能 null、集合非空但元素为 null、远程返回、Session 取值、`a.getB().getC()` 长链。防 NPE 是**调用方**责任；返回 null 时方法注释写清场景。

---

## 7. 设计模式与 SOLID（务实）

- 模式用于降低真实复杂度（多实现、稳定边界、可测隔离），**不为「看起来专业」或「企业级通常这样」而加**。
- SOLID 务实用：只有一个简单实现时，不要自动 `接口 → Impl → Factory → Strategy → Manager` 一条龙。
- 类有连贯职责；**不要仅因文件长就拆**；职责/生命周期真正受益时再拆。
- 方法目的单一；避免混杂 HTTP+DB+业务+格式化；不要机械行数上限——30 行清楚的方法可以好过 5 个抽象糟糕的 6 行方法。

---

## 8. Stream、集合、并发、内存

### 8.1 Stream

- 能提升可读性时再用；不要用 Stream 把简单逻辑伪装得很高级。
- **禁止**在 Stream 中藏：数据库查询、网络请求、复杂副作用、嵌套业务编排。
- 尤其禁止 `stream().map(id -> mapper.selectById(id))` 制造 N+1。

### 8.2 集合

- 按语义选 List/Set/Map 等；考虑顺序、重复、查找与内存。
- 不要无理由反复转换集合；不要默认把大结果集整表装进 `List` 再处理。
- `hashCode`/`equals` 成对覆写；作为 Set 元素或 Map key 的对象不可变关键字段，否则丢数据。
- `ArrayList` 的 `subList`：结果不可强转 `ArrayList`；改原列表结构会导致子列表遍历/增删异常。
- 集合转数组用 `toArray(new T[0])` 或正确尺寸；`Arrays.asList` 返回的列表**不可** `add`/`remove`/`clear`。
- 遍历中删除用 Iterator / 集合自带的 removeIf；foreach 里直接删易 `ConcurrentModificationException`。
- 遍历 Map 优先 `entrySet`；注意各 Map 对 null key/value 的允许差异（`ConcurrentHashMap`/`Hashtable` 等）。
- 集合初始化尽量指定容量，减少扩容；判空优先 `isEmpty()`。

### 8.3 并发与线程池

- **默认不要**引入并发；上之前想清：是否独立、CPU 还是 IO、上限、失败与取消。
- 线程资源必须来自**线程池**；禁止业务里随意 `new Thread`。
- **禁止** `Executors` 创建线程池（易隐藏无界队列/无线程上限 → OOM）；用 `ThreadPoolExecutor` 显式参数，并命名线程。
- 禁止对阻塞 IO 随手 `CompletableFuture.supplyAsync(...)` 却不指定有界执行器。
- `SimpleDateFormat` 线程不安全：勿当共享 static 裸用；JDK8+ 优先 `DateTimeFormatter` / `Instant` 等。
- 多资源加锁：全项目统一加锁顺序，防死锁。
- 并发改同一行数据：应用锁 / 缓存锁 / DB 乐观锁（`version`）三选一，防更新丢失。
- 定时任务：多 `TimerTask` 且无兜底时一个失败可拖垮 `Timer`；优先 `ScheduledExecutorService`。

### 8.4 JVM 与内存意识

- 避免：加载超大数据集 → 多份拷贝 → 反复转换 → 一次性序列化巨物。
- 优先：SQL 分页、批量、流式/增量处理（按场景）。
- 性能先盯 DB/网络/IO/内存与算法；不要过早优化微操作。
- 正则：预编译热点 `Pattern`，勿在方法内反复 `compile`；注意恶意输入导致的 ReDoS。
- 当前毫秒时间：`System.currentTimeMillis()`，勿 `new Date().getTime()`。

---

## 9. 编写前 / Review 核对

- [ ] 命名有前缀；驼峰/常量/方法前缀符合约定；抽象/模式有当前理由  
- [ ] 包与调用方向符合架构  
- [ ] API：统一 Result/分页；无 Map；校验失败可感知；列表有分页形态  
- [ ] Controller 无业务；Service 无展示拼接；null 更新真生效  
- [ ] equals/包装类型/`BigDecimal` 用法正确；控制语句有括号与 default  
- [ ] SQL：单表 MP+Lambda；联表 XML；`#{}` 禁 `*`/`${}`；**无二次单表内存关联**；无 N+1；Stream 无 IO  
- [ ] 集合：无 asList 乱改、无 foreach 里瞎删；线程池非 Executors  
- [ ] 异常：不吞、不当流程控制；事务 catch 需回滚则显式回滚  
- [ ] 外部调用 / Spring / 配置 / 安全符合对应分册  
- [ ] 无双轨死代码；无假数据；业务未进 config/security/common  
- [ ] 日志与注释符合分册  

**打回语**

- 「对外契约出现 Map，打回。」  
- 「展示拼接不应出现在 Service。」  
- 「联表必须 XML；禁止两次单表再在内存关联。」  
- 「关联/计数写 SQL；Stream/循环里不准查库。」  
- 「光秃 Helper/Manager，补功能前缀。」  
- 「不要为未出现的需求堆 Factory/Strategy。」  
- 「XML 禁止 `${}` 与 `SELECT *`。」  
- 「禁止 Executors 建池；SimpleDateFormat 勿共享裸用。」  

有一条做不到 → 先改写法，再提交。
