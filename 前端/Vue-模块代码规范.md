# Vue 模块代码规范

> 前提：目录、依赖方向、谁调谁见 [`Vue-代码架构.md`](Vue-代码架构.md)。  
> 本篇：**各层怎么写**（View / Composable / API / Component / Store）+ 跨层强制项（异步四态、错误、表单、TS 契约、安全底线）。  
> 分册：[`Vue-日志与注释规范.md`](Vue-日志与注释规范.md) · [`Vue-构建与工程规范.md`](Vue-构建与工程规范.md)。  
> **不管**：产品信息架构怎么定、视觉稿怎么画；业务强制要求按业务实现，但仍须符合本篇写法。

**技术基底**：Vue 3（`<script setup lang="ts">`）· Vite · Vue Router 4 · Pinia · TypeScript。

---

## 0. 通例

### 0.1 命名（写法侧）

架构篇已定文件/目录命名；本篇补充**标识符**：

| 对象 | 规则 | 示例 |
|------|------|------|
| 页面组件 | `{Domain}{Action}Page` | `OrderListPage` |
| Feature 组件 | 领域前缀 + 描述 | `OrderStatusBadge` |
| UI 原语 | 无领域前缀 | `BaseButton`、`AppModal` |
| Composable | `use` + 领域 + 动作 | `useOrderList`、`useOrderForm` |
| API 函数 | 动词 + 资源 | `fetchOrderList`、`createOrder` |
| 类型 | 与后端 VO/Request 对齐 | `OrderDetailVO`、`CreateOrderRequest` |
| 布尔 ref | `is`/`has`/`can` 前缀 | `isSubmitting`、`hasMore` |
| 事件 | `on` + 动词（props 回调）或 Vue `emit` 动词短语 | `onConfirm` / `emit('confirm')` |

禁：`data`、`temp`、`obj`、`handle`、`doSomething`、光秃 `utils`/`helpers`。

### 0.2 一类一事

一个文件一种角色：路由页 / 组合式 / API / 展示组件 / UI 原语 / 全局 store。

- **默认**：不为「企业范」先抽无策略的中间层（禁止只转发一层的 `*Service.ts`）。
- **允许抽层的例外**：稳定跨 feature 契约、可测隔离、明确复用且已有第二调用方。

### 0.3 状态归属（加状态前先问）

```text
仅 UI 临时态？        → 组件内 ref
表单草稿？            → 表单 composable / 页面局部
服务端真值？          → composable 请求结果（勿当「本地随便改的对象」）
跨路由 / session？    → URL（优先）或 app/stores
认证 / 权限？         → app/stores + 路由 meta
能进 URL？            → 进 query/params（可分享、可刷新）
```

**默认局部**；无第二消费者不进 Pinia；不为「以后可能用」全局化。

### 0.4 通用编码红线

| 禁止 | 正确做法 |
|------|----------|
| View 里直接 `axios`/`fetch` | View → composable → api → `shared/api/http` |
| Feature 组件调 `api/` | props/emits；请求在 composable |
| 只有成功路径的 UI | 显式 loading / empty / error / 权限拒绝 |
| 用过期响应写状态 | 请求序号 / AbortController / 离开页忽略 |
| `catch` 空吞或只 `console.log` | 映射错误模型 + 用户可感知反馈 |
| `any` / `as any` 当默认 | 边界类型化；实在不知用 `unknown` 再收窄 |
| 魔法字符串散落 template | `shared/constants` 或 feature 枚举 |
| 列表用数组下标当 `:key`（可重排时） | 稳定业务 id；`v-for` 在组件上也要 `:key` |
| **同一元素**同时 `v-if` + `v-for` | 过滤用 `computed`；或 `v-if` 提到外层 / `<template>` |
| 子组件里直接改 props / 解构后当本地源改 | 只读 props；要改走 emit / `v-model` / `defineModel` |
| 派生数据再镜像一份 ref 双向 sync | `computed` 派生 |
| 在 `watch`/`computed` 里偷偷发请求 | 显式事件或 `onMounted`/用户动作触发 |
| 组件名单词（除根 `App`） | 多词名，防与 HTML 标签冲突（Vue Style Guide Priority A） |

### 0.5 TypeScript 契约

- 边界必须有类型：路由 params、API 入参/出参、组件 props、表单模型。
- 与后端 VO **同名同字段语义**；改契约两端一起改，开发期不留双轨。
- 状态用**窄联合**：`'idle' | 'loading' | 'success' | 'error'`，禁模糊 `status: string`。
- 禁止同一实体两套不兼容类型（`Order` vs `OrderInfo` vs `OrderData` 并存）。
- 不便建模时不要把所有字段改成 optional 糊弄过去。

### 0.6 异步与副作用纪律

- 网络调用只出现在：**用户事件、显式生命周期（`onMounted` 等）、路由守卫约定路径**——禁止 render / `computed` 触发请求。
- 组件卸载：abort 进行中请求、清定时器、关 WS、移除 listener（在 composable 的 `onUnmounted`）。
- 同一资源：页面内一个所有者发起请求；禁止兄弟组件无协调地各打一遍。

---

## 1. View（`features/{x}/views/*Page.vue`）

**职责**：路由入口、读路由参数、编排 composable、拼子组件、页面级四态壳。

### 必须

- `<script setup lang="ts">`；从 `useRoute`/`useRouter` 取参，传给 composable。
- 页面级：`loading` / `empty` / `error`（可重试）/ 主内容，四态在 template 里可见。
- 权限不足与未登录：与「空数据」区分文案与动作（回登录 / 回列表 / 申请权限）。
- script 建议 ≤ ~200 行；超出拆 composable 或子组件。

### 禁止

- 复杂业务规则、字段拼装、日期/枚举转换堆在页面 script。
- 直接调 `api/` 或 `shared/api/http`。
- 在 `App.vue` 或 layout 里塞具体业务页逻辑。
- 用 `v-if` 藏按钮代替真实权限（可藏，但请求与路由仍须鉴权）。

### 推荐骨架

```vue
<script setup lang="ts">
import { useRoute } from 'vue-router'
import { useOrderDetail } from '../composables/useOrderDetail'

const route = useRoute()
const orderId = computed(() => String(route.params.id))
const { order, loading, error, reload } = useOrderDetail(orderId)
</script>

<template>
  <PageShell :loading="loading" :error="error" :empty="!loading && !order" @retry="reload">
    <OrderDetailHeader v-if="order" :order="order" />
    <!-- ... -->
  </PageShell>
</template>
```

---

## 2. Composable（`features/{x}/composables/useXxx.ts`）

**职责**：有状态用例——请求、表单流程、派生视图模型、订阅；**本 feature 唯一调 `api/` 的地方**。

### 必须

- 对外暴露：`ref`/`computed`/方法；命名见意图（`submit`、`reload`、`selectedIds`）。
- 处理：**竞态**（路由/入参变化时忽略旧响应或 abort）、**重复提交**（`isSubmitting` 门闩）、**错误 surfacing**（结构化 error，不丢原因）。
- 入参变化（如 `orderId`）用 `watch`/`watchEffect` 时写清：何时重拉、是否重置列表。
- 需要 auth / 全局壳：可读 `app/stores`；不在 composable 里操作 DOM 选型细节（交给组件）。

### 竞态（强制选一种，全项目一致）

```ts
// 模式 A：单调序号
let seq = 0
async function load(id: string) {
  const my = ++seq
  loading.value = true
  error.value = null
  try {
    const data = await fetchOrderDetail(id)
    if (my !== seq) return
    order.value = data
  } catch (e) {
    if (my !== seq) return
    error.value = toUiError(e)
  } finally {
    if (my === seq) loading.value = false
  }
}

// 模式 B：AbortController（http 层支持 signal 时优先）
```

### 禁止

- 返回原始 axios 响应让 view 解包。
- 在 composable 里 `ElMessage`/`toast` 与业务强耦合到死（若项目约定「mutation 成功统一 toast」，集中在一处策略，并注释约定；列表加载失败优先内联 error）。
- 把本该 URL 拥有的筛选态只放内存，导致刷新丢失（列表筛选项能进 query 的进 query）。
- 上帝 composable（一个 `useOrder` 包揽列表+详情+表单+WebSocket）；按用例拆 `useOrderList` / `useOrderDetail` / `useOrderForm`。

### 命名

`use` + 领域 + 用例。禁 `useData`、`useRequest`（无领域）、`useXxxManager`。

---

## 3. API（`features/{x}/api/*.ts`）+ HTTP 边界

**职责**：HTTP 薄封装——路径、方法、类型化入参/出参；**无 UI 状态、无 toast**。

### 3.1 Feature API

```ts
// features/order/api/order.ts
import { http } from '@/shared/api/http'
import type { OrderDetailVO, CreateOrderRequest, PageResult } from '../types'

export function fetchOrderList(params: { pageNum: number; pageSize: number }) {
  return http.get<PageResult<OrderDetailVO>>('/api/orders', { params })
}

export function fetchOrderDetail(id: string) {
  return http.get<OrderDetailVO>(`/api/orders/${id}`)
}

export function createOrder(body: CreateOrderRequest) {
  return http.post<OrderDetailVO>('/api/orders', body)
}
```

- 只用 `shared/api/http`；禁止每个文件 `axios.create`。
- 传输格式转换（epoch ↔ Date、枚举归一、null）放在 **API 边界或 composable 入口**，禁止 template 里解析传输格式。
- 函数返回**已解包的业务数据**（或项目统一的 `Result<T>` 成功态 data）；失败走抛错 / Result 错误态，全项目一种，不混用。

### 3.2 `shared/api/http.ts`

**职责**：实例、baseURL、超时、鉴权头/Cookie、拦截器、401/403 统一映射、错误规范化。

| 必须 | 禁止 |
|------|------|
| 超时有明确默认值 | 无超时的无限挂起 |
| 401 → 清会话 + 跳登录（或项目统一策略） | 每个调用点复制 Authorization |
| 业务码与 HTTP 状态映射成一种 `UiError` / 规范错误 | 失败时返回 `[]` / `null` 假装成功 |
| 支持 `signal`（取消） | 在拦截器里弹业务 toast 抢 composable 的语义（除非项目明文约定「仅网络层通用提示」） |

### 3.3 禁止

- View/Component 直调 http。
- 相邻接口返回结构深度不一致（有的 `{ data }`、有的裸数组）还不在边界归一。
- 用空数组掩盖 4xx/5xx。

---

## 4. Component

### 4.1 Feature 组件（`features/{x}/components/`）

**知道**：本域展示与交互。  
**不知道**：路由装配、直接 API、全局随便改 store（除明确注入的只读 auth 等）。

- 数据与回调由父级 **props / emits / slots** 注入。
- **禁止** `import` 本 feature `api/`；需要逻辑 → 上提 view/composable。
- 不要从零重写 `shared` 已有原语的视觉与交互。

### 4.2 UI 原语（`shared/components/`）

**知道**：variant、尺寸、禁用/加载、无障碍。  
**禁止**：任何 `features/` import、订单/房间等领域词。

### 4.3 组件 API 设计

优先：

```text
小而显式的 props（defineProps 带类型；禁 defineProps(['a','b']) 裸数组）
清晰的 emit
明确的 disabled / loading
必要的 slots
```

避免：

```text
巨大 options 对象
boolean 组合爆炸（disabled + enabled 相反）
挂载时隐藏副作用（一 mount 就请求/跳转）
为透传而透传的 6 层 props（改为组合或作用域槽）
直接修改 props（含深层字段当可变源）
```

需要 20 个 boolean 的组件 → 重新设计，不是再加 prop。

受控/非受控、焦点、浮层 portal 等非显而易见契约：用类型 + 一两行注释说明。

### 4.3.1 Vue 模板红线（Style Guide Priority A）

```vue
<!-- ❌ 同元素 v-if + v-for -->
<li v-for="u in users" v-if="u.active" :key="u.id">...</li>

<!-- ✅ -->
<li v-for="u in activeUsers" :key="u.id">...</li>
```

- 组件名多词（`OrderStatusBadge`）；仅根 `App` 可单词语例外。
- 列表/`v-for`：**稳定** `:key`（业务 id）；组件上的 `v-for` 同样强制。

### 4.4 浮层（Modal / Drawer / Popover / Toast）

- 全项目一套浮层与 z-index/焦点策略；禁止每个 feature 自研一套。
- 严重错误不要**只**靠 Toast；列表/表单失败优先内联或页级 error。
- 不要把「每个操作都开 Modal」当默认架构。

---

## 5. Store（Pinia，`app/stores/`）

**职责**：跨路由、跨 feature、与 session 绑定的状态。典型：**auth**、**app shell**。

### 必须先能回答

1. 离开当前页后是否仍需要？  
2. 多个无亲缘组件是否同时读写？  
3. URL 能否表达？（能则优先 URL）

### 写法

- 列表/详情/表单：**默认 composable**，不建 `useOrderListStore`。
- auth：登录态、用户信息、登出清缓存；身份变更必须清用户级客户端缓存。
- 禁止：每个复选框/弹层一个 store；在 store 里堆 DOM/组件引用。

---

## 6. 表单与校验

每个表单在动手前想清：

```text
初始值 · 校验规则 · 校验时机 · 提交中状态
服务端错误如何映射到字段 · 成功后去哪 · 取消/脏数据怎么办
```

### 必须

- 字段值**单一数据源**（不要 input 本地一份、submit 又一份对不上）。
- 提交中禁用重复提交（`isSubmitting`）。
- 失败可恢复：保留用户已填内容；服务端字段错误映射到对应项。
- 可访问：有 label；错误有文案，不只标红。

### 禁止

- 提交逻辑写进每个 Input 子组件。
- 两个字段的对话框却上沉重表单框架。
- **仅**依赖客户端校验当安全边界（服务端校验仍是权威）。
- 校验失败或局部服务端错误后清空整表。

校验逻辑放在 **表单 composable**（或明确的 `validators`），view 只绑值与展示错误。

---

## 7. 错误模型与交互四态（跨层强制）

### 7.1 错误分类（前端须能区分）

| 类型 | 典型来源 | UX 方向 |
|------|----------|---------|
| 网络/超时 | 传输层 | 可重试；内联或页级 |
| 未登录 / 401 | 会话失效 | 跳登录；清会话 |
| 无权限 / 403 | 授权 | 与「空」「未找到」文案区分 |
| 校验失败 | 400 + 字段 | 内联到字段 |
| 冲突 / 版本过期 | 409 等 | 提示刷新后再试 |
| 未找到 | 404 | 空态/404 页 |
| 未知服务端错误 | 5xx | 通用失败 + 可重试；**不**把堆栈给用户 |

- 用户可见文案：具体、可行动；禁唯一句「出错了」糊弄（能更具体时）。
- **禁止**把内部异常字符串、堆栈、原始后端载荷直接展示给终端用户。
- 规范化函数建议集中：`toUiError(e)`（放 `shared` 或 http 旁），composable 统一用。

### 7.2 四态

每一个重要界面显式处理：

1. **Loading** — 用户知道在进行  
2. **Empty** — 无数据，必要时给下一步 CTA  
3. **Error** — 原因 + 是否可重试  
4. **Success** — 主内容；mutation 按风险给反馈  

部分区块失败：不要无必要整页崩溃（区块级 error）。

---

## 8. 认证、路由权限与导航（写法侧）

### 8.1 会话存放（OWASP 对齐，强制）

- **默认**：会话走后端下发的 **`HttpOnly` + `Secure` + `SameSite`** Cookie（或 BFF）；前端 JS **读不到**长期凭证。
- **禁止**用 `localStorage` / `sessionStorage` 存 Access Token、Refresh Token、Session ID、JWT（XSS 即可被偷）。例外须团队书面批准并缩小寿命与权限。
- 若短期 access token 必须进内存：仅内存变量、页刷即失，靠 Cookie 刷新；仍不落 Web Storage。
- Cookie 会话的写操作：后端须有 **CSRF** 防护；前端按约定带 CSRF 头/Token 或同站自定义头——**SameSite 不能单独当银弹**。
- 登录成功后的回跳 URL：只允许站内相对路径或白名单域名；**禁止**把未校验的 `redirect` query 直接 `router.push`（open redirect）。

### 8.2 守卫与权限

- 401/403 在 **http 拦截器 + 路由守卫** 收敛；页面不复制三套 `if (!token)`。
- 需登录路由：`meta.requiresAuth`；守卫只在 `app/router/guards.ts`。
- **Pinia**：在守卫**回调内**再 `useAuthStore()`，禁止模块顶层取 store（安装顺序会挂，见 Pinia 官方）。
- 登出：清 store、清用户级缓存、作废进行中的已认证请求假设。
- UI 藏入口 ≠ 授权；写操作仍以服务端为准。

### 8.3 导航与历史

- 默认 `router.push`；认证跳转、清理 query、替换当前历史坑位用 `replace`，避免用户按后退卡在登录死胡同。
- 脏表单离开（未保存）：适当时确认；破坏性丢稿要可感知。
- 创建实体成功后导航到有用目的地（详情/列表），不要无反馈地停在空表单。

细则若与构建/env 相关（`VITE_*`、代理、CSP），见构建篇。

---

## 9. 列表、表格与筛选

- 行 `:key` 用稳定业务 id。  
- 分页 / 筛选 / 排序：默认**服务端**；禁止拉全量假装分页。  
- 有 COUNT 接口就不要为计数拉整表。  
- 筛选态能进 URL 的进 URL（分享、刷新、后退才说得通）。  
- 批量操作：明确选择模型与操作中态；防重复提交。  
- 大列表：考虑虚拟化；不要默认渲染数千 DOM。

---

## 10. 样式、a11y、安全底线（写法红线）

> 不单独开设计系统专篇；token + 下列红线即底线。构建/CSP 见构建篇。

### 样式

- 颜色/间距/字号优先 `styles/tokens.css` 变量；禁组件内随机 `#3b82f6`。  
- Feature 不复制一套与 `shared` 冲突的按钮视觉。  
- 响应式：关键操作在窄屏仍可用；不要假设「仅桌面」。  
- **样式作用域（Vue Style Guide Priority A）**：除 `App` / layout / 全局 `styles/*` 外，SFC 样式必须 **`scoped`**（或 CSS Modules / 等效 BEM）；禁止未作用域的组件样式污染全局。

### 可访问性（WCAG 可编码底线）

- 交互控件用语义元素或正确 ARIA；**禁 `div` 冒充按钮**还不处理键盘。  
- 表单控件有 label；图标按钮有可访问名称（`aria-label` / 可见文案）。  
- 浮层：焦点陷阱与关闭后焦点恢复按原语统一实现。  
- **可见焦点**：禁止全局干掉 `outline`；用 `:focus-visible` 保证键盘用户看得见。  
- **对比度**：正文对照约 **4.5:1**、大文本/UI 控件约 **3:1**（AA）；token 选色时就要守。  
- **表单错误**：无效字段 `aria-invalid`；错误文案与控件关联；提交失败时焦点落到首个错误。  
- **动态反馈**：loading / 重要 toast 可用 `aria-live`（`polite`），勿对高频无关更新刷屏。  
- 尊重 `prefers-reduced-motion`：非必要动效可关或减弱。

### 安全

- **默认不** `v-html`；必须时仅可信且**已消毒**内容（明确消毒手段，勿手写半截正则）。  
- 不在前端「藏密钥」；密钥永不进 `VITE_*`。  
- 会话存放与 CSRF：见 §8.1。  
- 日志/上报不落密码、token、隐私字段（见日志篇）。  
- 用户输入参与 URL/查询时注意编码；不把未校验输入当指令执行。

---

## 11. 错误边界与白屏

- 关键壳（`App` / layout）或路由出口附近：捕获渲染期错误，展示可恢复 UI（重试/回首页），**禁止**未处理异常直接白屏。  
- Vue：`onErrorCaptured` / `app.config.errorHandler` 与上报衔接（见日志篇）；在 handler 里记上下文，勿空吞。  
- 区块级失败优先区块 error，不要无必要打垮整页。

---

## 12. 性能写法（够用即可）

- 路由级懒加载（架构已要求）；大依赖不塞进首屏公共路径。  
- 派生用 `computed`；避免无必要的深 `watch`。  
- 搜索输入等昂贵动作：防抖；不要每个按键打全量查询（利于 INP）。  
- **CLS**：图片 / 异步块在加载前留**显式宽高或占位**，避免首屏内容把布局顶开。  
- 非 LCP 图片可用 `loading="lazy"`；首屏关键大图不要懒到看不见。  
- 不为「优化」把清晰代码改成晦涩技巧；能测再微优化。  
- 列表稳定 key；少引入「为一个函数上巨型库」。

---

## 13. 反模式速查

| 反模式 | 正确方向 |
|--------|----------|
| 上帝 Page 500 行 | 拆 composable + feature 组件 |
| 展示组件里请求 | 上提 composable |
| 每个勾选 Pinia | 局部 ref / 页面 composable |
| 静默 `catch` | `toUiError` + 四态 |
| 过期响应写回 | 序号或 abort |
| `any` 开路 | 边界类型 / `unknown` |
| 全量下载 + 客户端假分页 | 服务端分页 |
| 复制按钮只改颜色 | 用原语 variant / token |
| `watch` 里双向镜像两份 state | 一份源 + `computed` |
| 空数组当失败 | 抛错 / 错误态 |
| 仅客户端校验 | 服务端仍校验 |
| 隐藏按钮当授权 | 路由 + 服务端 |
| `localStorage` 存长期 token | HttpOnly Cookie / BFF |
| 同元素 `v-if`+`v-for` | computed 过滤或外提 `v-if` |
| 改 props 当本地状态 | emit / `defineModel` |
| 全局 `outline: none` | `:focus-visible` |
| 图片无尺寸导致乱跳 | 宽高或占位防 CLS |

---

## 14. 加代码前五问

1. 这段逻辑属于 View / Composable / API / Component / Store 哪一层？  
2. 异步失败、空、加载，用户分别看到什么？  
3. 入参变化或离开页面时，旧请求会不会写坏状态？  
4. 类型是否在边界对齐后端？有没有 `any` 偷懒？  
5. 若再加一个 boolean prop / 一个 store——能不能重新设计而不是叠复杂度？  

答不清 → 先写进当前 composable 或 page 的正确层，别急着抽「通用万能层」。
