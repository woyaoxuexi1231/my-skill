# Vue 总体代码架构

> 范围：只定 **文件放哪、feature 怎么拼、有哪些层**。  
> 不管：各层内部怎么写，也不管谁调用谁。  
> 固定方案：**业务 feature 分包 + 模块内 view/composable/api 分层 + Vue 3 SPA 单体**。个人项目与生产同一套。

**技术基底**：Vue 3（Composition API + `<script setup>`）· Vite · Vue Router 4 · Pinia · TypeScript。

---

## 1. 原则

1. **先按业务 feature 切，再按技术角色分子目录**——禁止顶级全局 `views/` + `components/` + `api/` 大包互不相干；禁止 `utils` / `helpers` / `common` 万能抽屉当架构。
2. **能进 feature 的不进全局**；只有跨 feature 真正共用的，才进 `shared/` 或 `app/`。
3. **少目录**：没有第二处使用方，不抽公共。
4. **目录结构反映业务边界**，不反映技术潮流；换 UI 库不应导致目录重构。
5. 未点名：不上微前端、不上 monorepo 多包、不上「为规范而拆」的 atomic design 深层树。
6. **Vue 专用**：新项目默认 `<script setup lang="ts">`；Options API 仅维护遗留代码时使用，不混进新 feature。

**一句话判断**：新人打开 `features/` 目录，能不能一眼看出这个系统有哪几块业务？不能 → 切分有问题。

---

## 2. 目录结构

```text
project-root/
├── index.html
├── vite.config.ts
├── tsconfig.json
├── env.d.ts
├── .env / .env.development / .env.production    # 仅 VITE_* 公开变量
└── src/
    ├── main.ts                  # createApp、挂载；不写业务
    ├── App.vue                  # 根壳：router-view、全局 provider
    ├── app/                     # 应用级装配（无业务用例）
    │   ├── router/
    │   │   ├── index.ts         # 创建 router、合并 routes
    │   │   ├── guards.ts        # 全局 beforeEach 等
    │   │   └── routes/          # 按 feature 拆 route 模块再 merge
    │   ├── stores/              # 仅全局 store：auth、app-shell 等
    │   └── plugins/             # pinia、i18n 等 install
    ├── features/                # 业务 feature（核心）
    │   └── {feature}/           # 如 order、workbench、room
    │       ├── views/           # 路由级页面（与 route 一一对应）
    │       ├── components/      # 仅本 feature 用的组件
    │       ├── composables/     # 本 feature 状态与副作用
    │       ├── api/             # 本 feature HTTP 封装
    │       ├── types/           # 本 feature Request/VO/视图模型
    │       └── routes.ts        # 本 feature 路由表（export 给 app/router）
    ├── shared/                  # 跨 feature 真正共用（极薄）
    │   ├── components/          # Button、Modal、DataTable 等 UI 原语
    │   ├── composables/         # useToast、useMediaQuery 等无业务语义
    │   ├── api/
    │   │   └── http.ts          # axios/fetch 实例、拦截器、401 统一处理
    │   ├── types/               # 分页、Result 包装等跨域类型
    │   ├── utils/               # 极少数无业务纯函数（慎用）
    │   └── constants/           # 跨模块枚举（与后端对齐）
    ├── assets/                  # 静态资源（图、字体）
    └── styles/
        ├── tokens.css           # CSS 变量 / 设计令牌
        ├── base.css             # reset、全局 typography
        └── index.css            # 入口 import
```

**feature 内目录按需取用**：`views` / `composables` / `api` 是常用三层，`components` / `types` 按需建。空目录不留。

不因「项目小」改回扁平 `views/` + `components/` + `api/` 三层大包。小型单 feature 项目可只有一个 `features/main/`，但目录角色不变。

---

## 3. Feature 怎么切

### 3.1 什么算一个 feature

一个 feature = **一组围绕同一业务主体、一起变化的页面与逻辑**。判断依据：

- 有一批**同主体**的页面（订单列表 / 详情 / 创建）；
- 共享同一批**后端接口**或同一个领域概念；
- 通常由**同一个人**维护；
- 会**因为同一个业务需求**一起改。

按主体切，不按动作切——`order` 是一个 feature，`order-create` / `order-cancel` 各自一个 feature 就切碎了。

**与后端模块对齐**：feature 划分尽量与后端 `module/{x}` 同构（order ↔ order），契约与类型演进节奏一致，避免前后端各说一套业务边界。

### 3.2 粒度

- **宁粗勿细**：起步时一个 feature 可以只有一个页面，粒度随业务增长再拆。
- feature 数量通常与一级导航 / 业务主体同量级；中型后台常见 5~15 个。
- 一个 feature 只有一个页面且从不增长 → 说明切细了，考虑合并到相邻 feature。

### 3.3 什么时候拆 feature

满足其一即可拆：

1. 一个 feature 下明显存在**两个业务主体**，各自页面互不相关。
2. feature 内文件膨胀（如超过 20 个文件）且能按主体划开。
3. 一部分需要**独立演进 / 独立负责人**，与其余部分变更节奏不同。

不满足就先不拆——拆 feature 的成本高于拆文件。

### 3.4 什么时候合并 feature

- 两个 feature **总是同时改**，边界模糊。
- 一个 feature 只服务于另一个 feature，从不单独对外。
- 拆分后出现了大量「为了绕过边界」的额外抽象。

### 3.5 `shared` 的边界

`shared` 是**跨 feature 真正共用**的东西，不是提前囤货的仓库。

| 进 `shared` | 不进 `shared` |
|-------------|---------------|
| 无业务语义的 UI 原语（Button、Modal、Table） | 带订单/房间等领域名的组件 |
| 无业务语义的 composable（useMediaQuery、useToast） | 只服务一个 feature 的组合式函数 |
| HTTP 客户端与错误规范化 | 某个 feature 的接口封装 |
| 跨域类型（PageResult、Result 包装） | 某 feature 的 Request/VO |
| 跨模块枚举/常量（与后端对齐） | 只在单处出现的常量 |

**判断口诀**：只有一处用 → 留在 feature 内；第二处出现再上收到 `shared`。**禁止**为「以后可能用」提前建 shared 组件。

`shared` 内部**不得依赖 `features/`**：一旦一个组件需要 import 业务类型或业务接口，它就属于 feature，不是 shared。

### 3.6 `app` 的边界

`app/` 只放**应用级装配**：路由创建与合并、全局守卫、全局 store（auth / shell）、插件 install。

- **禁止**在 `app/` 放业务页面、业务接口、业务组件。
- 全局 store 只在 `app/stores/`；feature 的状态默认放 feature 的 composable，不进全局。

---

## 4. 东西放哪

| 类型 | 放哪 | 不要放哪 |
|------|------|----------|
| 应用入口 | `main.ts` | 业务逻辑 |
| 根组件 | `App.vue` | feature 页面内容 |
| 路由定义 | `features/{x}/routes.ts` + `app/router` 合并 | 写在 `.vue` 里 export 一堆 magic path |
| 路由守卫 | `app/router/guards.ts` | 散落在各 view 的 `onMounted` |
| 路由级页面 | `features/{x}/views/XxxPage.vue` | `shared/components` |
| feature 组件 | `features/{x}/components/` | 全局 `components/` 按页面名堆文件 |
| 组合式函数 | `features/{x}/composables/` | 页面 `<script>` 里几百行逻辑 |
| feature API | `features/{x}/api/` | view 里直接 `axios.get` |
| feature 类型 | `features/{x}/types/` | 全项目一个 `types.ts` |
| UI 原语 | `shared/components/` | 带订单/房间等领域名的业务组件 |
| HTTP 客户端 | `shared/api/http.ts` | 每个 api 文件 new 一个 axios |
| 跨 feature 纯函数 | `shared/utils/`（慎用） | `utils` 万能抽屉 |
| 全局 store | `app/stores/` | 每个列表页一个 store |
| 跨域常量/枚举 | `shared/constants/` | 魔法字符串散落 template |
| 设计令牌 | `styles/tokens.css` | 组件内随机 `#3b82f6` |
| `@/` 别名 | 指向 `src/`（Vite 配置） | 跨 feature 用 `../../../` 钻内部 |

---

## 5. 分层职责（摘要）

| 层 | 职责一句话 |
|----|------------|
| **View**（路由页） | 路由入口；编排 composable；页面级四态壳 |
| **Composable** | 有状态用例；本 feature 的数据获取与副作用 |
| **API** | HTTP 薄封装；无 UI 状态 |
| **Feature 组件** | 本域展示与交互；props/emits |
| **UI 原语** | 无领域；不 import `features/` |
| **Store** | 仅跨路由/session 全局态（auth、shell）；列表详情默认不用 |

---

## 6. 组件分类

新建组件前先定它是哪一类——放哪、能不能有状态、能不能调接口，都由类别决定：

| 类别 | 放哪 | 知道什么 | 不知道什么 |
|------|------|----------|------------|
| **路由页 / View** | `features/{x}/views/` | 路由参数、编排哪些 composable | 具体 UI 细节（下沉到组件） |
| **Feature 展示组件** | `features/{x}/components/` | 本域展示与交互 | 路由、接口、全局 store（除只读 auth） |
| **Feature 容器组件** | `features/{x}/components/` | 组合若干展示组件、编排本域交互 | 路由参数（由 view 传入） |
| **UI 原语** | `shared/components/` | variant、尺寸、禁用/加载、无障碍 | 任何 `features/` 内容、领域词 |
| **布局壳组件** | `app/` 或 `shared/components/layout/` | 侧栏/顶栏/面包屑等跨页 chrome | 具体业务用例 |

**关键的三个禁止：**

1. **UI 原语不得 import `features/`**——一旦需要业务类型，它就不是原语。
2. **展示组件不得直接调接口**——数据由父级 props 注入或由 view 编排。
3. **布局壳不得写业务用例**——只提供插槽与壳层 chrome。

---

## 7. 路由组织

路由是**应用装配**，不是业务逻辑。

- 路由**按 feature 拆分**：`features/order/routes.ts` export `orderRoutes`，在 `app/router/index.ts` merge。
- 路径用 **kebab-case**；`name` 用 **PascalCase** 且带 feature 前缀：`OrderList`、`RoomDetail`。
- 路由组件用**懒加载**：`() => import('../views/OrderListPage.vue')`。
- 需登录的路由加统一 `meta.requiresAuth`；读取 meta 的守卫集中在 `app/router/guards.ts`，不在各页面重复判断。
- 重要列表/详情态能进 URL 的进 URL（`:id`、必要时的 query）；避免「刷新丢状态」的纯内存 flag。
- 布局壳由 `App.vue` / 嵌套路由挂载，不写具体业务用例。

---

## 8. Vite 与 env

架构侧只强调三条：**仅 `VITE_*` 进客户端**；**密钥永不进包**；**代理与 `@` 别名在 `vite.config.ts` 一处配置**。其余工程细节属构建篇。

---

## 9. 命名

| 对象 | 规则 | 示例 |
|------|------|------|
| 页面 Vue | `{Domain}{Action}Page.vue` | `OrderListPage.vue` |
| Feature 组件 | 领域前缀 + 描述 | `OrderStatusBadge.vue` |
| UI 原语 | 无领域前缀，可用 `Base`/`App` 前缀 | `BaseButton.vue`、`AppModal.vue` |
| Composable | `use` + 领域 + 动作 | `useOrderList.ts` |
| API 文件 | 领域复数或模块名 | `order.ts`、`room.ts` |
| API 函数 | 动词 + 资源 | `fetchOrderList`、`createOrder` |
| 类型 | 与后端 VO 对齐 | `OrderDetailVO`、`CreateOrderRequest` |
| 常量文件 | 语义复数 | `orderStatus.ts`，禁 `constants.ts` |

禁：光秃的 `utils.ts`、`helpers.ts`、`common.ts`、`data.ts`、`index.vue`（除路由懒加载入口外）。

---

## 10. 与后端协作（契约面）

- 字段名、枚举值与后端 VO **对齐**；前端 `types/` 与后端 dto 同步改，开发期不留双轨。
- 列表轻量、详情按需：路由进详情页再调 detail API，不在 list 接口塞满嵌套。
- 展示文案、拼接、格式化在**前端**；后端只出结构化字段。
- 传输格式转换（epoch ↔ Date、null 归一）收敛在 API 边界，不散落到模板。

---

## 11. 架构反模式

| 反模式 | 问题 | 正确方向 |
|--------|------|----------|
| 全站 `src/views` + `src/components` 按技术分 | 改一个业务要在多个目录间横跳 | 改 `features/{domain}/` |
| 一个 feature 塞下所有业务 | 等于没分 feature | 按业务主体切 |
| 一个页面一个 feature | feature 碎成渣 | 按主体聚合 |
| `App.vue` 500 行业务 | 根壳被业务污染 | 迁到 feature view + composable |
| `utils` / `helpers` 万能抽屉 | 什么都往里扔，无人负责 | 用具体语义名，或留在 feature 内 |
| 为「复用」提前建 shared 组件 | 只有一处使用方，白付复杂度 | 第二处出现再上收 |
| shared 组件 import `features/` 类型 | 共享层被业务污染 | 降级为 feature 组件 |
| 每个 feature 复制一份 axios | 连接与错误策略各写各的 | 只用 `shared/api/http.ts` |
| 每个列表页一个 Pinia store | 全局态泛滥 | 状态归 feature 的 composable |
| 从 `features/a` import `features/b/components/Foo.vue` | 跨 feature 穿透内部 | 提升到 `shared` 或走路由 |
| 根目录 `hooks/`（React 习惯） | 与 Vue 生态不符 | Vue 项目用 `composables/` |

---

## 12. 加文件前三问

1. 属于哪个 **feature**？没有 → 是否真是 `shared` / `app` 横切？
2. 角色是：路由页 / 组合式 / API / 展示组件 / UI 原语 / 全局 store？
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否不抽，或改成 **具体业务名**？

答不清 → 先写进当前 composable 或 page，别急建目录。

---

## 13. 核对清单

- [ ] 无顶层 `views/` + `components/` + `api/` 大包；按 feature 分包  
- [ ] feature 划分能反映业务主体；新人看 `features/` 能说出系统有哪几块  
- [ ] 粒度合理：无「只有一个页面」的空壳 feature，也无塞满业务的巨型 feature  
- [ ] 能进 feature 的不在全局；`shared` 只放 ≥2 处共用的东西且极薄  
- [ ] `shared` 无任何 `features/` 依赖；`app/` 无业务用例  
- [ ] 组件类别清晰：原语无领域词，展示组件不调接口，布局壳不写业务  
- [ ] 路由按 feature 拆分并懒加载；守卫集中在 `app/router/guards.ts`  
- [ ] 无 `utils` 万能抽屉；无光秃 `Helper` / `Manager` / `common.ts`  
- [ ] 无为空目录与为「以后可能用」预留的文件  

**打回语**

- 「按 feature 分包，别建全局 views/components/api 大包。」
- 「这个 feature 只有一个页面且从不增长，合并到相邻 feature。」
- 「只有一处使用方，不要提前抽到 shared。」
- 「shared 组件 import 了 features 的类型，降级为 feature 组件。」
- 「UI 原语里出现了订单相关文案/字段，去掉领域语义。」
- 「布局壳里写了业务用例，抽出业务部分。」
- 「光秃 utils/helpers，补具体语义名并说明归属。」
