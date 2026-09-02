# Vue 代码架构

> 入口：[../规范索引.md](../规范索引.md)  
> 范围：只定 **文件放哪、feature 怎么拼、谁调谁**。  
> 不管：各层怎么写 → [`Vue-模块代码规范.md`](Vue-模块代码规范.md)；日志注释 → [`Vue-日志与注释规范.md`](Vue-日志与注释规范.md)；构建 → [`Vue-构建与工程规范.md`](Vue-构建与工程规范.md)。  
> 固定方案：**业务 feature 分包 + 模块内 view/composable/api 分层 + Vue 3 SPA 单体**。个人项目与生产同一套。

**技术基底**：Vue 3（Composition API + `<script setup>`）· Vite · Vue Router 4 · Pinia · TypeScript。

---

## 1. 原则

1. **先按业务 feature 切，再按技术角色分子目录**——禁止顶级全局 `views/` + `components/` + `api/` 大包互不相干；禁止 `utils` / `helpers` / `common` 万能抽屉当架构。
2. **能进 feature 的不进全局**；只有跨 feature 真正共用的，才进 `shared/` 或 `app/`。
3. **少目录**：没有第二处调用方，不抽公共。
4. 调用链：`View → Composable → API → 后端`；路由与插件装配不插进业务链。
5. 未点名：不上微前端、不上 monorepo 多包、不上「为规范而拆」的 atomic design 深层树。
6. **Vue 专用**：新项目默认 `<script setup lang="ts">`；Options API 仅维护遗留代码时使用，不混进新 feature。

---

## 2. 目录

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
    │   └── constants/           # 跨模块枚举（与后端对齐）
    ├── assets/                  # 静态资源（图、字体）
    └── styles/
        ├── tokens.css           # CSS 变量 / 设计令牌
        ├── base.css             # reset、全局 typography
        └── index.css            # 入口 import
```

**不因「项目小」改回扁平 `views/` + `components/` + `api/` 三层大包。**

小型单 feature 项目可只有一个 `features/main/`，但目录角色不变。

---

## 3. 东西放哪

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
| 全局 store | `app/stores/` | 每个列表页一个 store |
| 跨域常量/枚举 | `shared/constants/` | 魔法字符串散落 template |
| 设计令牌 | `styles/tokens.css` | 组件内随机 `#3b82f6` |
| `@/` 别名 | 指向 `src/`（Vite 配置） | 跨 feature 用 `../../../` 钻内部 |

---

## 4. 分层职责（摘要）

> **怎么写**（四态、竞态、props、表单等）一律见 [`Vue-模块代码规范.md`](Vue-模块代码规范.md)。此处只定角色。

| 层 | 职责一句话 |
|----|------------|
| **View** | 路由入口；编排 composable；页面级四态壳；不直接调 API |
| **Composable** | 有状态用例；**唯一**调本 feature `api/`；竞态/提交/错误 |
| **API** | HTTP 薄封装；无 UI 状态 |
| **Feature 组件** | 本域展示；props/emits；不调 `api/` |
| **UI 原语** | 无领域；不 import `features/` |
| **Store** | 仅跨路由/session 全局态（auth、shell）；列表详情默认不用 |

---

## 5. 调用方向

### 5.1 Feature 内

```text
View → Composable → API → HTTP Client → 后端
         ↘ Feature Component（props/emits）
         ↘ shared UI 原语
```

- View **只调**本 feature composable（及 shared UI）。
- Composable **只调**本 feature api + `shared` + `app/stores`（如 auth）。
- API **只调** `shared/api/http`。
- Component **不调** composable/api（容器型 feature 组件若需逻辑，提升到 view 或拆 composable 由 view 注入）。

### 5.2 跨 feature（A 需要 B 的数据）

只通过 **B 的 composable / api / 路由跳转** 协作；不穿透 B 的内部 components。

**允许（按序）：**

1. **路由跳转** `router.push({ name: 'BDetail', params })`（默认，页面级协作）
2. **`A composable → B api`**（仅 B 的 api 已是稳定只读契约、且无 B 侧业务规则时；更常见是 A 调后端聚合接口）
3. **`shared` 类型/常量**（枚举、Result 包装）
4. **`app/stores`**（仅真正的全局态，如当前用户）

**禁止：**

- `A view → B view` 直接 import
- `A component → B api` 绕过 A 的 composable/view
- `shared → features/*`（共享层不得依赖业务）
- `features/A → features/B/components/*` 深路径引用内部组件
- AↄB 环依赖（环则抽到 `shared` 或让后端聚合）

```text
A.view → A.composable → A.api
                    ┬→ shared
                    ├→ app/stores（auth）
                    └→ router → B.view（页面级）

B.view → B.composable → B.api（不回调 A.view）
```

### 5.3 依赖总纲

```text
features/* → shared / app
features/A → features/B 的内部文件     ×
shared / app → features/*                ×
```

---

## 6. 路由与守卫

- 路由**按 feature 拆分**：`features/order/routes.ts` export `orderRoutes`，在 `app/router/index.ts` merge。
- 路径用 **kebab-case**；`name` 用 **PascalCase** 且带 feature 前缀：`OrderList`、`RoomDetail`。
- 需登录的路由加统一 `meta.requiresAuth`；守卫只在 `app/router/guards.ts` 读 meta，不在 page 里重复写三套 `if (!token)`。
- **Pinia 在守卫内取**：`beforeEach` **回调里面**再 `useAuthStore()`，禁止文件顶层取 store（Pinia 官方：安装顺序问题）。
- 路由组件用 **懒加载**：`() => import('../views/OrderListPage.vue')`。
- 重要列表/详情态能进 URL 的进 URL（`:id`、必要时的 query）；避免「刷新丢状态」的纯内存 flag。
- 布局壳：跨页 chrome（侧栏/顶栏）放 `app/` 或 `shared` 的 layout 组件，由 `App.vue` / 嵌套路由挂载；**不写**具体业务用例。
- `provide`/`inject`：只传主题、壳层能力等无业务用例依赖；禁止用 inject 偷偷穿透调别的 feature 内部。

---

## 7. Vite 与 env

> 细则见 [`Vue-构建与工程规范.md`](Vue-构建与工程规范.md)。架构侧只强调：仅 `VITE_*` 进客户端；密钥永不进包；代理与 `@` 别名在 `vite.config.ts` 一处配置。

---

## 8. 命名

| 对象 | 规则 | 示例 |
|------|------|------|
| 页面 Vue | `{Domain}{Action}Page.vue` | `OrderListPage.vue` |
| Feature 组件 | 领域前缀 + 描述 | `OrderStatusBadge.vue` |
| UI 原语 | 无领域前缀 | `BaseButton.vue`、`AppModal.vue` |
| Composable | `use` + 领域 + 动作 | `useOrderList.ts` |
| API 文件 | 领域复数或模块名 | `order.ts`、`room.ts` |
| API 函数 | 动词 + 资源 | `fetchOrderList`、`createOrder` |
| 类型 | 与后端 VO 对齐 | `OrderDetailVO`、`CreateOrderRequest` |

禁：光秃的 `utils.ts`、`helpers.ts`、`common.ts`、`data.ts`、`index.vue`（除路由懒加载入口外）。

---

## 9. 加文件前三问

1. 属于哪个 **feature**？没有 → 是否真是 `shared` / `app` 横切？  
2. 角色是：路由页 / 组合式 / API / 展示组件 / UI 原语 / 全局 store？  
3. 若叫 `*Util` / `*Helper` / `*Manager`——能否不抽，或改成 **具体业务名**？  

答不清 → 先写进当前 composable 或 page，别急建目录。

---

## 10. 与后端协作（架构面）

- 字段名、枚举值与 Java 模块 VO **对齐**；前端 `types/` 与后端 dto 同步改，开发期不留双轨。
- 列表轻量、详情按需：路由进详情页再调 detail API，不在 list 接口塞满嵌套。
- 展示文案、拼接、格式化在 **前端**；后端只出结构化字段（与 Java 生产级「Service 不拼 UI 串」对称）。
- 401/403 语义与后端 `Result.code` 约定一致，在 `http` 拦截器一处映射。

---

## 11. 反模式（架构级）

| 反模式 | 正确方向 |
|--------|----------|
| 全站 `src/views` + `src/components` 按技术分 | 改 `features/{domain}/` |
| `App.vue` 500 行业务 | 迁到 feature view + composable |
| 列表页 `onMounted` 里 5 个 await 串行 | composable 内 `Promise.all` 或后端聚合 |
| 每个 feature 复制一份 axios | 只用 `shared/api/http.ts` |
| `stores/orderList`、`stores/orderDetail`… | 合并进 `useOrderList` composable |
| 从 `features/a` import `features/b/components/Foo.vue` | 提升到 `shared` 或路由跳转 |
| 根目录 `hooks/`（React 习惯） | Vue 项目用 `composables/` |
