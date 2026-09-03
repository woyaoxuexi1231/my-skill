# Java 总体代码架构

> 范围：只定 **有哪些层、类放哪一层**。\
> 不管：各层内部怎么写，也不管谁调用谁。\
> 固定方案：**横向分层分包 + 全局基础包 + 单体**（SpringMVC/Spring Boot 最主流的落法）。个人与生产同一套。

***

## 1. 架构原则

1. **按技术角色分层，类按业务命名放对应层**：`controller / service / mapper / entity / dto / config / common / security`。一个类进哪层由**它是谁**决定，不由它属于哪块业务决定。
2. **调度单向递减**：`controller → service → mapper → 数据库`；`dto / entity` 为各层流转的契约与模型。禁止反向、禁止跨层绕道。
3. **每层内默认平铺**：同层类按资源/能力命名直接放在该层根包（如 `OrderController`、`UserController` 都在 `controller/`），**不要**在大层之下再套一层业务子包——那样会回到「先业务后技术」的老路。
4. **能共享的上收全局**：只有跨层 / 跨整个应用真正共用的响应体、异常、枚举、工具，才进 `common`；否则就近放在该数据/类所属层内。
5. **少目录**：没有第二处使用方，不抽公共层 / 预览子包。空目录不留。
6. 未点名：不上微服务、不上「为规范而拆」的多模块构建、不上 DDD/六边形。

**一句话判断**：新人在 `controller/` 点一眼，能不能立刻找到「订单」相关入口？不能 → 分层或命名有问题。

***

## 2. 目录结构

```text
com.xxx
├── XxxApplication.java          # 仅启动
├── config/                      # 框架/中间件装配（无业务规则）
├── security/                    # 认证鉴权、Filter、Token（无业务用例）
├── common/                      # 跨层/全局真正共用的内核（极薄）
│   ├── result/                  # Result / PageResult
│   ├── exception/               # 全局异常处理器、业务异常、错误码
│   ├── constant/                # 全局枚举/常量
│   └── util/                    # 极少数无业务纯函数（慎用）
├── controller/                  # HTTP 入口层
├── service/                     # 业务用例层
│   └── impl/                    # 可选：仅当确有抽象接口需求时
├── mapper/                      # 持久化接口（dao/）
├── entity/                      # 表映射模型（domain/ model/）
└── dto/                         # 各层流转的类型（出入参/查询投影）
    ├── request/                 # 写操作入参 + @Valid
    ├── response/                # 接口出参 VO
    └── query/                   # 列表查询条件（可选）
resources/
├── application.yml
├── application-{profile}.yml
└── mapper/**/*.xml              # 与 Java mapper 包一一对应
```

**按需取用**：`impl/`、`query/` 这类**可选子包**只在确有对应内容才建；空子目录不留。`entity` 与 `dto` 分开：`entity` 映射表，`dto` 做契约，二者不互串。

不因「项目小」改回业务模块分包。

***

## 3. 分层职责与调用规则

整体是一条**单向、逐层下钻**的依赖链，谁也别绕路。

```text
controller → service → mapper → DB
     │           │         │
     │        entity       │
     └──────── dto ────────┘   （dto / entity 是各层流转的数据)
```

### 3.1 controller —— HTTP 入口层

- 只做**接与转**：解析 HTTP（PathVariable/RequestParam/RequestBody）、触发参数校验、取认证上下文、调本用例 Service、把结果映射成响应。

- **不得**写业务规则、开事务、写 SQL、直调 mapper。

- 一个类对应一个资源集合（`OrderController` 管订单相关接口），一个方法 ≈ 一个用例。

### 3.2 service —— 业务用例层

- 放**用例编排与业务流程**：校验业务规则、协调 entity/mapper、事务边界、外部 IO、组装 dto。

- 被 controller 调用；只可调 `mapper` 与其它 service（非 controller）。

- 一个 service 围绕一个业务主体聚合用例（`OrderService`），**禁止**上帝 Service 一把抓。

### 3.3 mapper —— 持久化接口层

- 负责数据库读写；**不写业务编排、不调 service**。

- 与 `entity` 一一对应（MP `BaseMapper<Entity>`）；复杂 SQL 在 `resources/mapper/` 的 XML 中。

- 接口与 XML 路径要保持一致。

### 3.4 entity —— 表映射模型

- 与表一一映射；**不依赖 Spring / HTTP**；**不做 API 出入参**。

- 与 `dto` 分开放：表结构变化不影响契约，接口字段变化不污染实体。

### 3.5 dto —— 契约与流转模型

- `dto/request`：写操作入参 + 校验注解；`dto/response`（VO）：接口出参；`dto/query`：列表查询条件。

- **禁止**用 `Map`、`JSONObject` 或 `entity` 直接当出入参。

- Request/VO 分开，**禁止**一个类既当入参又当出参。

### 3.6 依赖总纲

```text
controller → service → mapper → DB          √ 单向递减
entity                                 依赖 DB 的库；被 service/mapper 使用
dto                                    被 controller / service 间流转使用
layers / service / mapper / entity / dto → common / config / security   √
层间反向调用（service → controller，mapper → service）              ×
同类重复包「先业务后技术」的子包（controller/order/...）            ×
common / config / security → 业务层                               ×（基础设施不反向依赖业务）
```

***

## 4. 东西放哪（速查表）

| 类型             | 放哪                            | 不要放哪                         |
| -------------- | ----------------------------- | ---------------------------- |
| 启动类            | 根包                            | 业务逻辑                         |
| HTTP 入口        | `controller`（`XxxController`） | service；一个 Controller 塞多个资源集 |
| 用例编排           | `service`（`XxxService`）       | controller；mapper；上帝 Service |
| Service 实现（可选） | `service.impl`                | 无接口需求时硬拆空 `Impl`             |
| 持久化接口          | `mapper`                      | 业务规则混入 mapper                |
| 表映射模型          | `entity`                      | 放进 dto / controller          |
| 写操作入参          | `dto.request`                 | `Map`；`entity` 当入参           |
| 接口出参 VO        | `dto.response`                | `Map`；`entity` 当出参           |
| 列表查询条件         | `dto.query`                   | Query 与 VO 混用                |
| 查询投影 Row       | `dto`（或接口所在层）                 | 与 VO 混用                      |
| 全局响应/分页体       | `common.result`               | 每层各写一套                       |
| 全局异常/错误码       | `common.exception`            | 每个 controller 手搓 try-catch   |
| 全局枚举/常量        | `common.constant`             | 各层复制一份                       |
| 框架装配           | `config`                      | 与业务类混放                       |
| 安全             | `security`                    | 散落在各 controller/service      |
| 极少数纯工具函数       | `common.util`                 | 无前缀 `CommonUtils` 垃圾桶        |

***

## 5. 全局包职责

### 5.1 `config/`

- 只做**框架与中间件的装配与开关**：MyBatis、Redis、线程池、Jackson、CORS、MVC、`@ConfigurationProperties` 等。

- 一类关注点一个类，名如 `RedisConfig`、`MybatisPlusConfig`。

- 不写业务用例（不查业务表、不推流程）。

- 环境值进 yml；代码只留稳定逻辑。

### 5.2 `security/`

- 认证鉴权基础设施：Filter、Token 编解码、权限模型。

- 只做身份识别与权限判定，**不写业务用例**。

- controller/service 不应出现手搓的鉴权逻辑。

### 5.3 `common/`

- 放**跨层 / 跨整个应用真正共用**的内核：统一响应 `Result`、分页 `PageResult`、全局异常处理器、业务异常与错误码、全局枚举/常量、极少数无业务纯函数。

- **哪些算「真正共用」**：响应体、异常体系这类**每个分层都会依赖的通用件**必上收；某个单独用例用的纯函数则不上收。

- 禁止塞入某个业务专有的规则；禁止 `CommonUtils` 这类无前缀大杂烩。

### 5.4 工具类：默认不抽

| 情况           | 做法                                               |
| ------------ | ------------------------------------------------ |
| 一个 Service 用 | 私有方法 / 包内方法                                      |
| 确实多处、无业务语义   | 才进 `common.util`，名如 `TimeRanges`；禁 `CommonUtils` |
| 带业务规则        | 进对应 Service / 枚举；不是工具类                           |

禁：业务向 `StringUtils`、`DateUtils`、`BusinessUtils`、`Helper`、`Manager` 大杂烩。

***

## 6. 关于接口与实现（`service.impl`）

- **默认**：一个实现 → 具体类注入即可，不为「企业范」先抽接口。

- **允许先有接口的例外**：框架要求、稳定跨模块边界、可测隔离外部依赖——且能说清**当前**理由。

- 真有接口时才用 `service.impl` 放实现类；**禁止**为未提出的多实现需求空抽 `接口 → Impl → Factory` 一条龙。

***

## 7. 架构反模式

| 反模式                                 | 问题                         | 正解                                           |
| ----------------------------------- | -------------------------- | -------------------------------------------- |
| 先按业务分包、层内再包业务子包（`user/controller/`） | 各层职责分散，跨业务的复用与横切难以收拢，新人难定位 | 横向分层分包（本篇 §2）                                |
| controller 里写业务 / 开事务 / 写 SQL       | 入口层负重，无法复用与测试              | 下沉 service（§3.1）                             |
| service 直调其它 controller             | 打乱单向调用，HTTP 层被当服务          | 经 service 协作                                 |
| 上帝 Service 一把抓所有用例                  | 任何改动都影响全局                  | 按业务主体拆 service（`OrderService`/`UserService`） |
| 一个 Controller 塞多个资源集                | 集合越滚越大                     | 一个资源一个 Controller                            |
| 用 `Map` / `entity` 当出入参             | 无契约、表结构泄漏                  | 用 `dto.request` / `dto.response`             |
| 业务规则散落 `config` / `security`        | 基础设施被业务污染                  | 各归其位（§5）                                     |
| 为了「复用」提前抽象出公共子包                     | 只有一处使用方，白付复杂度              | 用到第二处再抽                                      |
| 照搬 DDD 四层 / 六边形目录                   | 团队与业务不需要，徒增目录              | 用本篇固定方案                                      |

***

## 8. 加类前三问

1. 它是哪个**角色**：入口 / 用例 / 持久化 / 模型 / 契约 / 装配 / 安全 / 通用？
2. 放对应层：controller / service / mapper / entity / dto / config / security / common？
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否不抽，或改成功能前缀的具体名？

答不清 → 先放进当前 Service，别急建新类 / 新包。

***

## 9. 核对清单

- [ ] 只按技术角色分层，无「用户/订单 …/controller」这类业务子包

- [ ] 调度单向：controller → service → mapper；无反向、无跨层绕道

- [ ] layer 内每层按资源/能力平铺命名，无层内业务再分包

- [ ] controller 无业务/事务/SQL；service 无 HTTP 感知

- [ ] 出入参是 `dto`；无 `Map` / `entity` 当契约；Request/VO 分离

- [ ] `entity` 与 `dto` 分开；`common` 只放真正共用件且极薄

- [ ] `config` / `security` 无业务用例；全局异常与 Result 固定一处

- [ ] 无 `util` 万能抽屉；无光秃 `Helper` / `Manager` / `CommonUtils`

- [ ] 无为空目录与为「以后可能用」预留的包

**打回语**

- 「按横向分层分包：controller/service/mapper/entity/dto，别在大层下再套业务包。」

- 「controller 里写了业务规则，下沉到 service。」

- 「出参用了 Map，改成 dto.response 的类型。」

- 「调度要单向递减，禁止 service 反调 controller。」

- 「只有一处使用方，不要提前抽公共子包 / 空 Impl。」

- 「光秃 Helper/Manager，补功能前缀并说明归属层。」

