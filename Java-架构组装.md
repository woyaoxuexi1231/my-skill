# Java 架构组装

> 范围：只定 **类放哪、模块怎么拼、谁调谁**。  
> 不管：接口契约细则、SQL 写法、注释规范（另篇）。  
> 固定方案：**业务模块分包 + 模块内 MVC 三层 + 单体**。个人与生产同一套。

---

## 1. 原则

1. **先按业务模块切，再按技术角色分目录**——禁止顶级全局 `controller/` `service/` `mapper/` 大包，禁止 `util` / `manager` / `helper` 万能抽屉当架构。
2. **能进模块的不进全局**；只有跨模块真正共用的，才进 `common` / `config` / `security`。
3. **少目录**：没有第二处调用方，不抽公共。
4. 调用链：`Controller → Service → Mapper`；配置与安全不插进业务链。
5. 未点名：不上微服务、不上「为规范而拆」的多模块构建、不上 DDD/六边形。

---

## 2. 目录

```text
com.xxx
├── XxxApplication.java          # 仅启动
├── config/                      # 框架/中间件装配（无业务规则）
├── security/                    # 认证鉴权、Filter、Token（无业务用例）
├── common/                      # 跨模块真正共用的内核（极薄）
│   ├── Result / PageResult
│   ├── 业务异常、错误码
│   ├── 跨模块枚举/常量
│   └── 极少数无业务纯函数（慎用）
└── module/
    ├── {业务}/                  # 如 teacher / workbench / order
    │   ├── controller/
    │   ├── service/
    │   └── dto/                 # 仅本模块 Request / VO
    ├── biz/                     # 可选：跨端共享表模型与持久化
    │   ├── entity/
    │   ├── mapper/
    │   └── dto/                 # 仅查询投影 Row（可选）
    └── ...
resources/
├── application.yml
├── application-{profile}.yml
└── mapper/**/*.xml              # 与 Java mapper 包对应，如 mapper/biz/
```

不因「项目小」改回全局按层分包。

---

## 3. 东西放哪

| 类型 | 放哪 | 不要放哪 |
|------|------|----------|
| 启动类 | 根包 | 业务逻辑 |
| Controller | `module.{x}.controller` | 公共包；跨模块调别人的 Controller |
| Service | `module.{x}.service` | `common`；跨所有域的上帝 Service |
| 本模块入参/出参 | `module.{x}.dto` | Entity 当 API；`Map` 当契约 |
| Entity | `module.biz.entity` 或该域自有 entity | 放进 controller/dto |
| Mapper 接口 | 与实体同域 | Service 里拼 SQL 字符串 |
| Mapper XML | `resources/mapper/...` | 与接口路径错位 |
| 查询投影 Row | `biz.dto` 或模块 dto | `List<Map>` 对外 |
| `@Configuration` | `config/` | 写业务用例 |
| 安全 | `security/` | 业务 Service 里手搓鉴权 |
| 全局异常 / Result | `common` 或 `config`（固定一处） | 每个 Controller 私有一套 |
| 跨模块枚举/常量 | `common` | 复制魔法字符串 |
| 「工具类」 | 默认不建（见 §5） | `common.util` 垃圾桶 |

---

## 4. 配置

`config/` 只做装配与开关：MyBatis、Redis、线程池、Jackson、CORS、MVC、`@ConfigurationProperties` 等。

- 一类关注点一个类，名如 `RedisConfig`、`MybatisPlusConfig`。
- 不写业务用例（不查业务表、不推流程）。
- 环境值进 yml；代码只留稳定逻辑。

---

## 5. 工具类

**默认不抽。**

| 情况 | 做法 |
|------|------|
| 一个 Service 用 | 私有方法 / 包内方法 |
| 同模块多个 Service 用 | `module.{x}.support.Xxx`（具体名） |
| 多模块、无业务语义 | 才进 `common`，名如 `TimeRanges`；禁 `CommonUtils` |
| 带业务规则 | 进对应 Service / 枚举；不是工具类 |

禁：业务向 `StringUtils`、`DateUtils`、`BusinessUtils`、`Helper`、`Manager` 大杂烩。

---

## 6. 调用方向

### 6.1 模块内

```text
controller → service → mapper → DB
                ↘ Redis / HTTP 客户端（明确组件）
                ↘ 同模块 support
```

- Controller 只调**本模块** Service。
- Service 可调：本模块 support、本域/`biz` Mapper、`common`。
- 禁：Controller → Mapper（除非团队明文约定的极简只读）。

### 6.2 跨模块（A 需要 B）

只通过 **B.service**（或 B 专门门面）协作；不穿透 B 的 Controller / API dto / 自有 Mapper。

**允许（按序）：**

1. **`A.service → B.service`**（默认）  
2. **`A.service → B.api` 门面**（外模块调用变多、B 内部 Service 太碎时再抽；默认先不建）  
3. **`A.service → biz.mapper`**（仅共享表、且无 B 侧业务不变量）  
4. **`common`**（枚举/错误码/纯技术；禁止塞 A/B 业务规则）

**禁止：**

- `A.controller → B.controller` / `B.service`
- `A.service → B.controller`
- `A.service → B.mapper`（B 自有表）
- A 复用 B 的 Request/VO
- `common` / `config` / `security` → 业务模块
- A⇄B 环依赖（环则抽到 `biz`/`common`，或把编排升到第三方模块）

```text
A.controller → A.service ┬→ 本域 mapper（若有）
                         ├→ biz.mapper
                         ├→ B.service（或 B.api）
                         └→ common / 基础设施

B.controller → B.service → …（不回调 A.controller）
```

### 6.3 依赖总纲

```text
业务模块 → biz / common / security / config
业务模块 A → B.service（或 B.api）     √ 单向
业务模块 B → A                         × 成环
common / config / security → 业务模块  ×
```

### 6.4 跨模块选型

1. 要 B 的规则或受保护数据 → **调 B.service**  
2. 纯共享表、无规则 → **biz.mapper**  
3. 外呼入口多且乱 → **再抽 B.api**  
4. 其它歪路 → 不用  

---

## 7. 加类前三问

1. 属于哪个**业务模块**？没有 → 是否真是全局横切？  
2. 角色是：用例 / 持久化 / 装配 / 安全 / 契约？  
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否不抽或改成具体名？  

答不清 → 先放进当前 Service，别急建目录。