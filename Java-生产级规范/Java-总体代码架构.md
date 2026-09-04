# Java 总体代码架构

> 范围：只定 **有哪些层、类放哪一层、谁调用谁**。\
> 不管：各层内部怎么写。\
> 固定方案：**模块化单体 + 公共内核外置 + 模块内技术分层**（Spring Boot + MyBatis-Plus 最主流的落法）。个人与生产同一套。

***

## 1. 架构原则

1. **先有业务模块边界，层只存在于模块内部**：以业务主题切出模块（`order`、`user`…），一个类进哪个模块由**它服务哪块业务**决定；进了模块，它再按技术角色落 `controller / service / mapper / dto`。
2. **公共的放外面**：`config` / `security` / `common`（共享内核）/ `entity`（表映射）/ 单表 `mapper` 属**全局基础设施**，所有模块共用；**具体模块再内部细分**controller/service/mapper/dto。
3. **模块是复用的最小边界**：跨业务协作只经对方模块的 **Service 门面**，禁止穿透到对方模块内部；纯共享表数据可跨模块**只读**单表直查，不碰对方业务不变量。
4. **模块内调度单向递减**：`controller → service → (模块内 mapper 联表 | 全局单表 mapper) → DB`；`dto / entity` 为流转契约与模型。禁止反向、禁止跨层绕道。
5. **模块内默认平铺**：同层类按资源/能力命名直接放该层根包（`OrderController` 在 `order/controller/`）；**不要**在模块内再套第二层业务子包——模块本身已是业务边界。
6. **持久化按表分轨**：单表查询一律走**全局单表 mapper**（继承 MP `BaseMapper` + Lambda）；多表联查 / 复杂 SQL 放**发起查询的模块内 mapper**（配 XML）。
7. **少目录**：无第二使用方不抽公共层；空目录不留；不因"项目小"改回全局技术平铺。
8. 未点名：不上微服务、不上六边形/完整 DDD、"为规范而拆"的多模块构建。

**一句话判断**：新人在 `order/` 点一眼，能不能立刻找到"订单"相关的一切？能 → 业务边界清晰；不能 → 模块划分或命名有问题。

***

## 2. 目录结构

```text
com.xxx
├── XxxApplication.java          # 仅启动
│
├── config/                      # 框架/中间件全局装配（无业务规则）
├── security/                    # 认证鉴权、Filter、Token（无业务用例）
├── common/                      # 跨模块/全局真正共用的内核（极薄）
│   ├── result/                  # Result / PageResult
│   ├── exception/               # 全局异常处理器、业务异常、错误码
│   ├── constant/                # 全局枚举/常量
│   ├── event/                   # 领域事件（跨模块松耦合通知）
│   └── util/                    # 极少数无业务纯函数（慎用）
│
├── entity/                      # 表映射模型（全模块共享，放外面）
├── mapper/                      # 全局单表持久化接口：仅 extends BaseMapper<Entity>
│
├── order/                       # 业务模块（边界优先，内部按技术角色细分）
│   ├── controller/              # HTTP 入口
│   ├── service/                 # 用例编排/事务/跨模块门面
│   ├── mapper/                  # 模块内：多表联查/复杂 SQL（配 XML），单表不走这里
│   └── dto/                     # 模块内契约
│       ├── request/             # 写操作入参 + @Valid
│       ├── response/            # 接口出参 VO
│       └── query/               # 列表查询条件（可选）
├── user/                        # 业务模块
│   ├── controller/  service/  mapper/  dto/
│   └── ...
resources/
├── application.yml
├── application-{profile}.yml
└── mapper/**/*.xml              # 与各模块 mapper 包一一对应
```

**按需取用**：`order/…/query/`、`common/event/` 这类**可选子包**只在确有对应内容才建；空子目录不留。`entity`（表映射）与 `dto`（契约）分开放，二者不互串。

***

## 3. 分层职责与调用规则

整体是一条**单向、逐层下钻**的依赖链，模块之间通过 Service 门面协作。

```text
controller → service → (模块内 mapper 联表 | 全局单表 mapper) → DB
     │           │                          │
     │        entity                        │
     └──────── dto ─────────────────────────┘   （dto / entity 是各层流转的数据）
```

### 3.1 controller —— HTTP 入口层（模块内）

- 只做**接与转**：解析 HTTP（PathVariable/RequestParam/RequestBody）、触发参数校验、取认证上下文、调本模块用例 Service、原样返回 Service 组装好的 VO。

- **不做**字段级装配（组装在模块 Service 完成，见《Java-分层代码规范》§3.2）；**不得**写业务规则、开事务、写 SQL、直调 mapper。

- 一个类对应一个资源集合（`order/controller/OrderController` 管订单接口），一个方法 ≈ 一个用例。

### 3.2 service —— 业务用例层（模块内，含跨模块门面职责）

- 放**用例编排与业务流程**：校验业务规则、协调 entity / mapper、事务边界、外部 IO、组装 dto。

- 是**本模块对外的门面**：跨模块协作一律走这里暴露的用例方法，不放穿透式直查。

- 被 controller 调用；只可调**本模块 mapper（联表）**、**全局单表 mapper**、其它模块的 **service 门面**（非其内部）。

- 一个 service 围绕一个业务主体聚合用例（`order/service/OrderService`），**禁止**上帝 Service 一把抓。

### 3.3 全局单表 mapper —— 持久化基础层（外面）

- 与 `entity` 一一对应，仅 `extends BaseMapper<Entity>`，**只做单表查询**（含单表条件增删改、COUNT）。

- **不写联表、不写业务编排、不调 service**。

- 所有模块共用它做单表操作；复杂 SQL 一律下沉到发起模块的模块内 mapper。

### 3.4 模块内 mapper —— 联表/复杂 SQL（模块内）

- 专门承载**多表联查、聚合、复杂单表、分页 SQL**（配 XML），由该业务模块发起并拥有。

- 不允许 `extends BaseMapper` 但要能定位 statement；简单单表不走这里（见 §3.3）。

- 接口与 XML 路径要保持一致。

### 3.5 entity —— 表映射模型（外面，全局共享）

- 与表一一映射；**不依赖 Spring / HTTP**；**不做 API 出入参**。

- 全模块共用同一套 entity；跨模块**只读**共享表就是引这套 entity 做单表查询。

- 与 `dto` 分开放：表结构变化不影响契约，接口字段变化不污染实体。

### 3.6 dto —— 契约与流转模型（模块内）

- `dto/request`：写操作入参 + 校验注解；`dto/response`（VO）：接口出参；`dto/query`：列表查询条件。

- **禁止**用 `Map`、`JSONObject` 或 `entity` 直接当出入参。

- Request/VO 分开，**禁止**一个类既当入参又当出参。

### 3.7 依赖总纲

```text
controller → service → (模块 mapper 联表 | 全局单表 mapper) → DB   √ 单向递减
entity                                                      依赖 DB 的库；被各模块 service/mapper 使用
业务模块 → common / config / security / entity / 全局单表 mapper  √
业务模块 → 其它业务模块：只经对方 service 门面；共享表只读单表直查    √
模块间穿透（A 直接用 B 的 controller/内部类）                  ×
模块内再套业务子包（order/order-item/…）                      ×
common / config / security → 业务模块                         ×（基础设施不反向依赖业务）
```

***

## 4. 东西放哪（速查表）

| 类型             | 放哪                            | 不要放哪                         |
| -------------- | ----------------------------- | ---------------------------- |
| 启动类            | 根包                            | 业务逻辑                         |
| 业务模块的 HTTP 入口 | `order/controller`（`OrderController`） | 全局；一个 controller 塞多个资源集     |
| 用例编排/门面       | `order/service`（`OrderService`）   | controller；mapper；上帝 Service |
| 业务模块本身        | 根包下的 `order` / `user` 业务包       | 全局技术平铺后再套业务子包              |
| 单表持久化（基础）    | 全局 `mapper`（`extends BaseMapper`） | 写联表；模块内 mapper 塞单表          |
| 联表/复杂 SQL     | 发起模块的 `order/mapper`（配 XML）    | 全局单表 mapper；Service 里拼假 JOIN |
| 表映射模型         | 全局 `entity`                    | 放进模块 dto / controller       |
| 写操作入参         | 模块 `dto/request`                | `Map`；`entity` 当入参           |
| 接口出参 VO       | 模块 `dto/response`               | `Map`；`entity` 当出参           |
| 列表查询条件        | 模块 `dto/query`                 | Query 与 VO 混用                |
| 全局响应/分页体      | `common.result`                | 每模块各写一套                     |
| 全局异常/错误码      | `common.exception`             | 每个 controller 手搓 try-catch   |
| 全局枚举/常量       | `common.constant`              | 各模块复制一份                     |
| 跨模块事件         | `common.event`                 | 模块间直接 new 织死耦合             |
| 框架装配           | `config`                      | 与业务类混放                       |
| 安全             | `security`                    | 散落在各模块 controller/service   |
| 极少数纯工具函数      | `common.util`                 | 无前缀 `CommonUtils` 垃圾桶        |

***

## 5. 全局包职责

### 5.1 `config/`

- 只做**框架与中间件的全局装配与开关**：MyBatis、Redis、线程池、Jackson、CORS、MVC、`@ConfigurationProperties` 等。

- 一类关注点一个类，名如 `RedisConfig`、`MybatisPlusConfig`。

- 不写业务用例（不查业务表、不推流程）。

- 环境值进 yml；代码只留稳定逻辑。

### 5.2 `security/`

- 认证鉴权基础设施：Filter、Token 编解码、权限模型。

- 只做身份识别与权限判定，**不写业务用例**。

- controller/service 不应出现手搓的鉴权逻辑。

### 5.3 `common/`

- 放**跨模块 / 跨整个应用真正共用**的内核：统一响应 `Result`、分页 `PageResult`、全局异常处理器、业务异常与错误码、全局枚举/常量、领域事件、极少数无业务纯函数。

- **哪些算「真正共用」**：响应体、异常体系这类**每个模块都会依赖的通用件**必上收；某个单独用例用的纯函数则不上收。

- 禁止塞入某个业务模块专有的规则；禁止 `CommonUtils` 这类无前缀大杂烩。

### 5.4 工具类：默认不抽

| 情况           | 做法                                               |
| ------------ | ------------------------------------------------ |
| 一个 Service 用 | 私有方法 / 包内方法                                      |
| 确实多处、无业务语义   | 才进 `common.util`，名如 `TimeRanges`；禁 `CommonUtils` |
| 带业务规则        | 进对应模块 Service / 枚举；不是工具类                           |

禁：业务向 `StringUtils`、`DateUtils`、`BusinessUtils`、`Helper`、`Manager` 大杂烩。

***

## 6. 关于接口与实现（模块内 service）

- **默认**：一个实现 → 具体类注入即可，不为「企业范」先抽接口。

- **允许先有接口的例外**：框架要求、稳定跨模块边界、可测隔离外部依赖——且能说清**当前**理由。

- 跨模块门面若确需要独立契约，可为该模块 `service` 抽接口并只暴露用例方法，**禁止**为未提出的多实现需求空抽 `接口 → Impl → Factory` 一条龙。

***

## 7. 架构反模式

| 反模式                                 | 问题                         | 正解                                           |
| ----------------------------------- | -------------------------- | -------------------------------------------- |
| 全局技术平铺后再套业务子包（`controller/` 下建 `order/`） | 业务边界不存在，跨域复用与横切难以收拢，新人难定位 | 模块化单体，业务模块优先（本篇 §2）                         |
| 模块内再套第二层业务子包（`order/order-item/…`）     | 模块内边界过度切分，分层职责分散         | 模块内按技术角色平铺（controller/service/mapper/dto） 各守其位 |
| 跨模块直接用对方案模块内部类 / controller         | 破坏模块边界，内部结构外泄            | 只经对方 Service 门面                             |
| controller 里写业务 / 开事务 / 写 SQL       | 入口层负重，无法复用与测试              | 下沉模块内 service（§3.2）                        |
| 全局单表 mapper 写联表                    | 单表基础层被多表逻辑污染，归属混乱          | 联表/复杂 SQL 放发起模块的 mapper（§3.4）               |
| 简单单表查询硬塞进模块内 mapper / 写 XML        | 无谓 xml，违反分轨               | 用全局单表 mapper + Lambda（§3.3）                 |
| Service 里两次单表查询再内存「假 JOIN」         | N+1、性能差                   | 联表一次 SQL 下沉模块 mapper（§3.4）                  |
| service 直调其它模块 controller            | 打乱单向调用，HTTP 层被当服务          | 模块间经 Service 门面协作                          |
| 上帝 Service 一把抓所有用例                  | 任何改动都影响全局                  | 按业务主体拆 service（`OrderService`/`UserService`） |
| 用 `Map` / `entity` 当出入参             | 无契约、表结构泄漏                  | 用模块 `dto/request` / `dto/response`          |
| 跨模块把业务规则塞进 `common` / `config`     | 基础设施被某个模块业务污染            | 规则归对应模块，公共内核保持极薄                        |
| 为了「复用」提前抽象出公共子包                  | 只有一处使用方，白付复杂度              | 用到第二处再抽                                      |
| 照搬 DDD 四层 / 六边形目录                    | 团队与业务不需要，徒增目录              | 用本篇固定方案（模块化单体 + 领域分层务实版）                   |

***

## 8. 加类前三问

1. 它服务哪块**业务**？→ 进对应模块（`order` / `user`…），还是全局共享（`common` / `entity` / 全局单表 `mapper` 之一）？
2. 在模块内它是哪个**技术角色**：入口 / 用例 / 联表 / 契约？→ 落 `controller / service / mapper / dto`？
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否不抽，或改成功能前缀的具体名？

答不清 → 先放进对应模块当前 Service，别急建新类 / 新包 / 新模块。

***

## 9. 核对清单

- [ ] 按业务模块分包（`order`/`user`…），模块内按技术角色平铺；无全局技术层再套业务子包

- [ ] `entity` / 单表 `mapper` 放外面且全模块共用；全局单表 mapper 仅单表、无联表

- [ ] 联表 / 复杂 SQL 在发起模块的 mapper（XML）完成，无内存「假 JOIN」、无 N+1

- [ ] 调度单向：controller → service → (模块 mapper | 全局单表 mapper)；跨模块只经 Service 门面，无反向、无穿透

- [ ] controller 无业务/事务/SQL；service 无 HTTP 感知

- [ ] 出入参是模块 `dto`；无 `Map` / `entity` 当契约；Request/VO 分离

- [ ] `entity` 与 `dto` 分开；`common` 只放真正共用件且极薄；`config` / `security` 无业务用例

- [ ] 无 `util` 万能抽屉；无光秃 `Helper` / `Manager` / `CommonUtils`

- [ ] 无为空目录与为「以后可能用」预留的包 / 模块

**打回语**

- 「按模块分包、公共的放外面：entity 和单表 mapper 提到全局，业务模块再细分 controller/service/mapper/dto。」

- 「单表查询必须走全局 BaseMapper + Lambda；别把无 JOIN 的 SQL 塞进模块 mapper。」

- 「这是多表联查，放发起模块的 mapper + XML，不要在 Service 里两次查再内存关联。」

- 「controller 里写了业务规则，下沉到模块内 service。」

- 「跨模块别直接用对方内部类，走对方 Service 门面。」

- 「出参用了 Map，改成模块 dto/response 的类型。」

- 「调度要单向递减，禁止 service 反调 controller / 穿透其它模块。」

- 「模块内不要再套业务子包，技术角色平铺即可。」

- 「只有一处使用方，不要提前抽公共子包 / 空 Impl。」

- 「光秃 Helper/Manager，补功能前缀并说明归属模块。」