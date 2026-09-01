# Java 模块代码规范

> 前提：包与调用方向见 `Java-代码架构.md`。  
> 本篇只答：**写出的代码是否规范**（职责、命名、分层写法、数据访问等）。  
> 日志与注释见 `Java-日志与注释规范.md`。  
> **不管**：业务该怎么规划、流程/状态机该怎么定、Token 里该放什么——那是需求与产品问题；业务若强制要求，按要求实现，但仍须符合本篇写法规范。

---

## 0. 通例

### 0.1 命名

- 类名必须带**具体能力/业务前缀**，后缀可用 `Service` / `Controller` / `Mapper` / `Manager` / `Helper` / `Common` 等。
- **允许**：`OrderInventoryManager`、`TokenRefreshHelper`、`PageQueryCommon`
- **禁止**：光秃的 `Manager`、`Helper`、`Common`、`Util`、`Handler`、`Processor`；以及无前缀的 `CommonUtils` 等垃圾桶。
- 方法名说意图：`calculateOrderTotal()`；禁 `doProcess()` / `handle()` / `data` / `temp` / `obj`。

### 0.2 一类一事

一个类一种角色：入口 / 用例 / 持久化 / 装配 / 安全 / 契约。  
没有第二实现，不要先抽接口；不要为未提出的需求堆 `Factory` / `Strategy` / `Registry`。

### 0.3 失败与契约写法

- 业务失败 → 业务异常 + 错误码；禁吞异常；禁用 `null`/魔法布尔冒充失败原因。
- 对外 API 禁止 `Map` / `JSONObject`；禁止 Entity 直接当出入参。
- 替换契约时：不要长期保留双轨分支与死代码；该删的旧路径删干净（这是代码整洁，不是替业务决定能不能改契约）。

### 0.4 通用编码红线

| 禁止                               | 正确做法                       |
| -------------------------------- | -------------------------- |
| 先糊再重构；用 TODO/空实现冒充已完成            | 按规范一次写到可维护                 |
| Service/VO 拼 HTML 或面向 UI 的展示串    | 返回原子字段；展示由前端（或专门渲染层）处理     |
| 单表大查再内存过滤；循环/Stream 里按条查库（N+1）   | 过滤/关联/聚合/分页/计数放 SQL        |
| 未用到的缓存/MQ/异步/多余抽象先堆上             | 当前实现用到再加                   |
| 用假数据冒充真实业务结果                     | 无数据就按契约返回空/明确无；不要假装有进度或有结果 |
| 列表接口塞满详情图省事；用 `list.size()` 冒充计数 | 列表与详情载荷分离；计数用 COUNT        |

---

## 1. Controller（`module.{x}.controller`）

**职责**：HTTP——解析请求、触发校验、取认证上下文、调**本模块** Service、映射响应。

### 必须

- `@RestController`；路径与方法语义清晰；一个方法 ≈ 一个用例入口。
- 入参：本模块 Request + `@Valid`（或项目统一校验）；出参：`Result` / `PageResult` + VO。
- 每个接口有简短说明（注释或文档注解），写明用途。
- 列表类接口：分页参数与分页结果结构明确，禁止无界全量当默认。
- 按既定契约返回字段；不在 Controller 里临时改成 `Map` 凑合。

### 禁止

- 在方法里堆业务规则、复杂查询、展示文案拼接。
- 注入其他模块 Controller / Mapper；Controller 直调外模块 Service。
- `Result<Map<…>>`；同模块接口契约类型风格混乱（有的 DTO、有的 Map）。
- 无调用方的死接口继续留在代码里。

### 命名

`{资源}Controller`。方法名与路径语义一致。

---

## 2. Service（`module.{x}.service`）

**职责**：用例编排、业务流程实现、**事务边界**、协调 Mapper / 他模块 Service / 外部 IO。

### 必须

- 一个对外方法 ≈ 一个用例；写操作明确事务边界；先校验再改持久化数据。
- 跨模块：`A.service → B.service`（或约定门面）；见架构文档。
- 需要把字段更新为 `null` 时，必须使用能真正写出 null 的更新方式（如显式 `UpdateWrapper`、或调整 MP 字段策略）；禁止「调用了 update 但 null 被框架跳过」却当成功。
- 返回给 Controller 的数据保持结构化、原子字段；禁止在 Service 里做 HTML/UI 展示拼接。

### 禁止

- 上帝 Service 跨所有业务域；把本该在此的规则拆散到 Controller / Mapper。
- 无充分理由把长时间 HTTP/RPC 塞进数据库事务。
- 假设同类内部自调用会生效 `@Transactional` / `@Async` / `@Cacheable`——需要时拆 Bean 或避免自调用。
- 把业务用例写进工具类 / 无边界 Helper 里藏起来。

### 命名

`{能力}Service`。可按子域拆多个 Service。  
使用 `Manager` 时必须有功能前缀，且不替代正常的 Service 入口职责。

### 事务与外部 IO

```text
连贯 DB 写操作 → 同一事务
外部 HTTP / MQ → 默认放事务外；明确失败、重试与幂等怎么处理
```

---

## 3. DTO（`module.{x}.dto`）

**职责**：本模块 API 契约的代码形态。

### 必须

- Request / VO 分开；命名如 `CreateTeacherRequest`、`TeacherDetailVO`。
- 校验注解放在 Request；字段与**已约定契约**一致（多了少了都算实现偏差）。
- 列表 VO 保持轻量；大块子资源走详情或其他接口，避免列表被详情拖垮（写法与性能问题，不是替产品定要不要详情）。

### 禁止

- Entity / `Map` 当出入参；一个无边界巨型 DTO 打所有接口。
- 其他模块 import 本模块 Request/VO「复用」。
- 无边界意义时硬拆 DTO 凑类数量。

组装转换放在 Service（或本模块明确组装点）；Controller 不做大段无关拷贝。

---

## 4. Entity / Mapper / biz

### 4.1 Entity

- 与表映射；不依赖 Spring/HTTP；不直接作为 API 出参。
- 命名与领域概念一致；避免无意义叠词。
- 写入值与列类型/约定格式一致（例如 JSON 列不要写入非法空串导致驱动/库报错）。

### 4.2 Mapper

**职责**：持久化与查询——数据库相关行为。

必须：

- 过滤、JOIN、聚合、排序、分页、COUNT、EXISTS → **优先在 SQL 完成**。
- 复杂 JOIN/聚合/子查询 → XML（或项目约定的显式 SQL）；禁止为躲 SQL 拆成多次 Java 查询却更慢更乱。
- 方法名表意：`selectById`、`countByStatus`；禁 `query1`。
- 多表只读投影可用 `XxxRow`；禁 `List<Map>` 充当对外结果类型。
- 只要数量 → `COUNT`；禁 `selectList` 再 `.size()`。

禁止：

```text
大结果集进内存再过滤 / 手写 JOIN / 排序 / 分页
for 或 stream 里按条调 Mapper（N+1）
在 Mapper 里写业务编排或调用 Service
```

### 4.3 biz

- 仅放跨端共享的表模型与 Mapper。
- 更新会触及某模块业务不变量时，经该模块 Service，不直捅私有持久化。

---

## 5. config（`config/`）

**职责**：框架与中间件装配、开关；环境相关值进配置文件。

| 必须 | 禁止 |
|------|------|
| 一关注点一类（如 `RedisConfig`） | 万能 `AllConfig`；在 config 写业务用例 |
| 密钥、地址、超时等走配置 | 密码、Token、私钥硬编码在源码 |
| 多环境 profile 配置完整可切换 | 依赖本机隐式环境才能运行 |

---

## 6. security（`security/`）

**职责**：认证、鉴权、Filter、Token 解析、安全上下文等**安全基础设施代码**。

| 必须 | 禁止 |
|------|------|
| 安全能力集中；业务侧统一获取当前用户 | 各 Service 复制一套 Token 解析 |
| 认证与授权在代码结构上可区分 | 在 Filter/安全组件里写具体业务用例 |
| 密钥与算法配置化 | 硬编码密钥；日志打印 Token/密码 |

> Token **载荷里放什么**由安全/产品方案决定；本篇只要求：解析与校验写法集中、可维护，且不把业务用例塞进 security 包。

---

## 7. common（`common/`）

**允许**：`Result` / `PageResult`、业务异常与错误码、跨模块枚举/常量、带功能前缀的共用能力。

**禁止**：具体业务用例；无前缀 `Common` / `CommonUtils`；无第二调用方就上收。

门槛：≥2 个模块真实共用再进 `common`。

---

## 8. support（可选，`module.{x}.support`）

同模块多 Service 共享、且不是独立对外用例时使用。

- 命名必须有具体能力前缀（如 `ScheduleWindowHelper`）；禁光秃 `Helper`。
- 不作为外模块 API；上升为用例则改为 Service。

---

## 9. 异常与空值

**异常**

- 保留 cause 与上下文；映射到统一错误模型；该回滚时回滚。
- 禁万能 `catch (Exception e)` 后仅打日志了事；禁把堆栈与内部细节直接暴露给外部调用方。
- 日志与注释写法：见 `Java-日志与注释规范.md`。

**空值**

- 显式处理；控制流保持浅而直。
- 对外集合类型约定一致（空集合 vs null），同一项目内不要混用两套习惯。

---

## 10. 编写前 / Review 核对

- [ ] 命名有具体前缀；无光秃 `Manager`/`Helper`/`Common`/`Util`  
- [ ] 包与调用方向符合 `Java-代码架构.md`  
- [ ] Controller 无业务堆砌；无 Map 契约；列表有分页形态  
- [ ] Service 无 HTML/展示拼接；事务与代理用法正确；null 更新真生效  
- [ ] 关联/聚合/分页/计数在 SQL；无 N+1、无内存假 JOIN  
- [ ] 无双轨死代码；无假数据冒充结果  
- [ ] 业务用例未写进 config/security/common  
- [ ] 日志与注释符合 `Java-日志与注释规范.md`  

**打回语**

- 「对外契约出现 Map，打回。」  
- 「展示拼接不应出现在 Service，返回原子字段。」  
- 「关联/计数请写 SQL，禁止内存筛 / list.size()。」  
- 「光秃 Helper/Manager，补功能前缀或改名。」  
- 「旧契约双轨代码清掉。」  

有一条做不到 → 先改写法，再提交。
