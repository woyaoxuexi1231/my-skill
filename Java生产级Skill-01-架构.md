# Java 生产级 Skill · 01 代码架构如何组装

> 只回答一件事：**类放哪、模块怎么拼**。不展开接口/SQL/注释。  
> **固定方案**：业务模块分包 + 模块内 MVC 三层（单体）。个人项目与生产 vibecoding 同一套。  
> 选型依据见 `Java生产级Skill-01-架构总览-目录.md`。状态：草稿。

---

## 1. 总装原则

1. **先按业务模块切，再按技术角色分目录**——不是先建一堆 `util/manager/helper`，也不是顶级按层堆全项目的 `controller/service/mapper`。
2. **能放进模块内的，不放全局**；只有跨模块真正共用的，才进 `common` / `config` / `security`。
3. **多一个目录 = 多一条心智负担**；没有第二处调用方，就不要抽到公共区。
4. 调用链：`Controller → Service → Mapper`，配置与横切靠边，不插进业务调用链。
5. 未点名：不上微服务 / 为规范而空挂多模块构建。

---

## 2. 推荐目录总览

```text
com.xxx
├── XxxApplication.java          # 启动类，仅启动
├── config/                      # 框架/中间件装配（无业务规则）
├── security/                    # 认证鉴权、过滤器、Token（无业务用例）
├── common/                      # 跨模块真正共用的内核
│   ├── Result / PageResult
│   ├── 业务异常、错误码
│   ├── 枚举、常量（跨模块）
│   └── 极少数无业务纯函数（慎用）
└── module/
    ├── {端或子域}/              # 如 teacher / workbench / dashboard
    │   ├── controller/
    │   ├── service/
    │   └── dto/                 # 仅本模块 Request / VO
    ├── biz/                     # 跨端共享的表模型与持久化（可选）
    │   ├── entity/
    │   ├── mapper/              # Java 接口
    │   └── dto/                 # 仅查询投影 Row（可选）
    └── ...
resources/
├── application.yml              # 公共配置
├── application-{profile}.yml    # 环境配置
├── mapper/**/*.xml              # SQL，路径与模块对应
└── ...
```

Mapper XML 与 `module.*.mapper` 包对应，例如 `mapper/biz/`、`mapper/dashboard/`，不要一把丢进无命名空间的大杂烩。

> 一律按上表搭，不因「项目小」改回全局 `controller/service/mapper`。

---

## 3. 各类东西放哪

| 类型                         | 放哪                                | 不要放哪                          |
| -------------------------- | --------------------------------- | ----------------------------- |
| 启动类                        | 根包 `com.xxx`                      | 塞业务逻辑                         |
| Controller                 | `module.{x}.controller`           | 公共包；跨模块互相调用 Controller        |
| Service                    | `module.{x}.service`              | `common`；不要上帝 Service 跨所有端    |
| 本模块入参/出参                   | `module.{x}.dto`                  | Entity 直接当 API；`Map` 当契约      |
| 表实体 Entity                 | `module.biz.entity`（或该域自有 entity） | controller/dto 冒充表模型          |
| Mapper 接口                  | 与实体同域：`module.biz.mapper` 等       | Service 里写 SQL 字符串凑合          |
| Mapper XML                 | `resources/mapper/...`            | 与 Java 接口随意错位                 |
| 仅查询用的行投影                   | `module.biz.dto.XxxRow` 或模块 dto   | `List<Map>` 对外                |
| 配置类（`@Configuration`）      | `config/`                         | 写业务 if-else；塞进 service 包「顺便配」 |
| 安全（Filter、JWT、UserDetails） | `security/`                       | 业务 Service 里手搓鉴权细节            |
| 全局异常处理                     | `common` 或 `config`（选一处固定）        | 每个 Controller 自己 try/catch 一套 |
| 跨模块枚举/常量                   | `common`                          | 复制多份魔法字符串                     |
| 「工具类」                      | **默认不建**；见下节                      | `common.util` 万能抽屉            |

---

## 4. 配置类怎么放

`config/` 只做**装配与开关**，例如：

- MyBatis / Redis / 线程池 / Jackson / CORS / MVC
- 读取 `application-*.yml` 的 `@ConfigurationProperties`（也可 `config.props` 子包）

规则：

- 一个关注点一个配置类，类名说人话：`RedisConfig`、`MybatisPlusConfig`。
- **配置类里不写业务用例**（不查业务表、不推审批流）。
- 环境相关值进 yml；代码里只留稳定逻辑。公共 vs `dev`/`prod` 分开。

---

## 5. 工具类怎么放（严格限制）

默认答案：**先不要抽 Utils。**

| 情况                 | 做法                                                    |
| ------------------ | ----------------------------------------------------- |
| 只被一个 Service 用     | 私有方法或该类内包可见方法                                         |
| 两个同模块 Service 用    | 同模块下小类，如 `module.teacher.support.Xxx`                 |
| 多模块都用、且无业务语义       | 才进 `common`，并命名成具体能力（如 `TimeRanges`），禁止 `CommonUtils` |
| 带业务规则（状态怎么判、权限怎么算） | **不是工具类**，进对应 Service / `common` 枚举或领域方法              |

禁止垃圾桶：`StringUtils`（业务向）、`DateUtils`、`BusinessUtils`、`Helper`、`Manager` 大杂烩。

---

## 6. 组装关系（调用方向）

### 6.1 模块内（默认）

```text
controller → service → mapper → DB
                ↘ 必要时 → Redis / 外部 HTTP（经明确组件）
                ↘ 同模块 support
```

- Controller 只调**本模块** Service。
- Service 调本模块 support、本域或 `biz` 的 Mapper、以及 `common` 的枚举/异常等。
- 禁止：Controller → Mapper（跳过 Service，除非极简单只读且团队明文约定）。

### 6.2 跨业务模块（A 要用 B 的能力）

原则：**只通过对方的 Service（或对方专门暴露的门面）协作**；不穿透对方的 Controller / 内部 dto / Mapper（`biz` 共享表除外，见下）。

```text
允许（按优先级选用）：

① A.service → B.service
   最常见。A 编排用例时注入 B 的 Service，调 B 已有业务方法。
   例：workbench 下单前校验老师 → 调 teacher 的 TeacherService。

② A.service → B 的门面（可选，调用方变多时再抽）
   在 B 下增加薄门面，如 module.B.api.BFacade / BQueryService，
   只暴露给外模块的稳定方法；内部仍转调 B.service。
   外模块禁止再直接依赖 B 的「一堆杂 Service」时再上，默认不必先建。

③ A.service → biz.mapper / biz 上的共享查询
   仅当读写的是**跨端共享表模型**（本来就放在 biz），且没有必须经过 B 的业务规则。
   若改数据会破坏 B 的不变量（状态机、权限、库存等）→ 必须走 ①/②，禁止直捅表。

④ 共用内核 → common（枚举、错误码、纯技术能力）
   不是「跨模块调业务」，是用稳定内核。禁止把 A/B 的业务规则塞进 common。

禁止：

× A.controller → B.controller（HTTP 内部互打或直接调对方 Controller）
× A.controller → B.service（跳过本模块 Service，把编排堆在入口）
× A.service → B.controller
× A.service → B.mapper（B 自有表；绕过 B 的校验与事务边界）
× A 依赖 B 的 Request/VO 等 API dto「图省事复用」
× B / common / config / security → A.service（下层或无关模块反依赖）
× 为了跨模块调用去新建双向依赖（A→B 且 B→A）；出现环则抽到 biz/common 或上移编排到第三方模块
```

示意：

```text
module.A.controller → module.A.service ┬→ module.A 自己的 mapper（若有）
                                       ├→ module.biz.mapper     （共享表）
                                       ├→ module.B.service      （跨模块业务）
                                       └→ common / 基础设施组件

module.B.controller → module.B.service → …（对称，不回调 A.controller）
```

### 6.3 依赖方向（总纲）

```text
业务模块 A/B  →  biz / common / security / config
业务模块 A    →  业务模块 B.service（或 B.api 门面）   √ 单向协作
业务模块 B    →  业务模块 A                            × 不要形成环
common / config / security → 业务模块                  ×
```

依赖只能**向稳定方向**或**向被调用方的 Service/门面**；不反向、不环依赖、不穿透持久化。

### 6.4 跨模块怎么选（一句话）

1. 只要 B 的规则/数据 → **调 B.service**。  
2. 只是共享表、无 B 规则 → 可走 **biz.mapper**。  
3. 外模块调用 B 的入口变多、B 内部 Service 太碎 → 再在 B 抽 **api 门面**。  
4. 其它歪路（调 Controller、掏 Mapper、共用对方 VO）→ 一律不采用。

---

## 7. 一句话检查

新加一个类之前问：

1. 它属于**哪个业务模块**？没有模块 → 真的是全局横切吗？
2. 它是**用例 / 持久化 / 装配 / 安全 / 纯契约**里的哪一种？
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否改成有业务含义的名字，或根本不抽？

三问答不清，就先放进当前 Service 里，别急着建目录。

---

## 8. 遗留仓库（全局按层）怎么处理

若已有项目是顶级 `controller/` `service/` `mapper/`：

- **不强制**一次性搬家。
- 新功能优先放进 `module.{业务}`；能挪的旧类顺手收拢。
- Review 时仍遵守第 6 节调用方向，避免「按层目录 + 跨域乱调」叠加。

---

## 下一步（先不动）

架构对齐后，再写短篇：**接口契约怎么放进这套目录**（Request/VO/Result 规则）。
