# Vue 模块代码规范

> 本篇：**各层怎么写**（View / Composable / API / Component / Store）+ 跨层强制项（响应式纪律、异步四态、错误、表单、TS 契约、安全底线）。  
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
| 事件处理函数 | `handle` + 动作 或 动词直接命名 | `handleSubmit`、`removeRow` |
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
| 在 `computed` 里做副作用 / 发请求 | `computed` 只做纯派生；副作用放 `watch` 或事件 |
| 组件名单词（除根 `App`） | 多词名，防与 HTML 标签冲突（Vue Style Guide Priority A） |

### 0.5 TypeScript 契约

- 边界必须有类型：路由 params、API 入参/出参、组件 props、表单模型。
- 与后端 VO **同名同字段语义**；改契约两端一起改，开发期不留双轨。
- 状态用**窄联合**：`'idle' | 'loading' | 'success' | 'error'`，禁模糊 `status: string`。
- 禁止同一实体两套不兼容类型（`Order` vs `OrderInfo` vs `OrderData` 并存）。
- 不便建模时不要把所有字段改成 optional 糊弄过去；宁可用 `unknown` 在边界收窄。
- 类型导入统一 `import type { X } from '...'`，避免运行时多打一个 import。

### 0.6 异步与副作用纪律

- 网络调用只出现在：**用户事件、显式生命周期（`onMounted` 等）、路由守卫约定路径**——禁止 render / `computed` 触发请求。
- 组件卸载：abort 进行中请求、清定时器、关 WS、移除 listener（在 composable 的 `onUnmounted`）。
- 同一资源：页面内一个所有者发起请求；禁止兄弟组件无协调地各打一遍。
- `onMounted` 里注册的异步任务，必须在 `onUnmounted` 有对应清理，否则切页后仍会写已卸载组件的状态。

### 0.7 分层调用纪律

```text
View → Composable → API → HTTP Client → 后端
         ↘ Feature 组件（props / emits / slots）
         ↘ shared UI 原语
```

- **View** 编排本 feature 的 composable 与子组件，**不直接调 `api/`**。
- **Composable** 是本 feature 请求数据的位置，**唯一直接调本 feature `api/` 的一层**（跨 feature 例外见 §0.8）。
- **API** 只调 `shared/api/http`；不含 UI 状态、不弹 toast。
- **展示组件不调接口、不调 composable**（容器型组件若确需逻辑，把逻辑拆成 composable 由 view 注入，或上提到 view）。
- **UI 原语**只依赖 `shared`，不依赖任何 feature。

### 0.8 跨 feature 协作（A 需要 B 的数据）

**默认不跨 feature 直接取数**，优先让后端聚合或走路由跳转。

**允许（按优先级）：**

1. **路由跳转** `router.push({ name: 'BDetail', params })`（页面级协作的默认方式）
2. **`A composable → B api`**（仅当 B 的 api 已是稳定只读契约、且不涉及 B 侧业务规则；**B 的 `api/` 算对外契约，不算 B 的内部文件**）
3. **`shared` 类型 / 常量**（枚举、Result 包装）
4. **`app/stores`**（仅真正的全局态，如当前用户）

**禁止：**

- `A view → B view` 直接 import
- `A component → B api`（绕过本 feature 的 composable 与 view）
- `features/A → features/B/components/*`（深路径引用内部组件）
- `features/A → features/B/composables/*`（引用 B 的内部状态逻辑）
- `shared → features/*`（共享层不得依赖业务）
- A⇄B 环依赖（成环则把共享部分上收到 `shared`，或让后端聚合）

```text
依赖总纲

features/* → shared / app              √
features/A → features/B/api（只读契约） √
features/A → features/B/components     ×
shared / app → features/*              ×
```

### 0.9 Vue 响应式纪律（高频坑）

| 规则 | 说明 |
|------|------|
| **默认用 `ref`** | `ref` 适用于一切；`reactive` 只在确实需要一组对象属性时才用 |
| **`reactive` 禁止整体替换** | `state = {...}` 会丢响应性；要改就逐字段赋值，或改用 `ref` |
| **禁止解构 props** | `const { id } = defineProps<Props>()` 会丢失响应性 → 用 `props.id`，或用 `toRefs`/`toRef` |
| **禁止解构 `reactive` 后当响应源** | 需要解构用 `toRefs(state)` |
| 模板中自动解包，JS 中要 `.value` | 别在模板里写 `count.value` |
| 第三方实例用 `shallowRef` / `markRaw` | 图表、地图、编辑器实例不需要深度响应式，深度代理会拖慢并引起怪异行为 |
| 大列表用 `shallowRef` | 数千行数据深度响应式开销显著 |
| 只读语义用 `readonly` | 防止下游误改服务端真值 |
| 别把整个大对象塞进 `reactive` 再逐层改 | 拆成语义化的多个 `ref`，更好读也更好测 |

```ts
// ❌ 解构 props 丢响应性
const { orderId } = defineProps<{ orderId: string }>()
watch(() => orderId, load)      // orderId 已是死值，永远不触发

// ✅ 保持 props 引用
const props = defineProps<{ orderId: string }>()
watch(() => props.orderId, load)

// ✅ 或用 toRefs 显式解构
const props = defineProps<{ orderId: string }>()
const { orderId } = toRefs(props)
watch(orderId, load)
```

### 0.10 `computed` / `watch` / `watchEffect` 选择

| 需求 | 用 | 禁止 |
|------|----|----|
| 从现有状态**派生**一个值 | `computed` | 在 `computed` 里发请求、改状态、写日志 |
| 状态变化后**做副作用**（请求、写存储、操作 DOM） | `watch` | 用 `computed` 偷偷做副作用 |
| 依赖分散、想自动收集 | `watchEffect` | 用它监听多个源却说不清依赖，导致意外重跑 |
| 监听对象内部变化 | `watch(() => obj.deep, cb)` 或显式 `deep: true` | 无脑 `deep: true` 监听大对象（性能代价高） |
| 需要立即执行一次 | `watch(src, cb, { immediate: true })` | 手动调一次再 watch（容易漏） |
| 需要取消上一次未完成的工作 | `watch` 的 `onCleanup` / `onWatcherCleanup` | 只靠布尔标记硬扛 |

**竞态与取消**：`watch` 内发起异步，必须处理「上一次还没回来，下一次又触发了」——用 `onCleanup` 或序号（见 §2 竞态）。

---

## 1. View（`features/{x}/views/*Page.vue`）

**职责**：路由入口、读路由参数、编排 composable、拼子组件、页面级四态壳。

### 1.1 `<script setup>` 组织顺序（固定）

统一顺序，读代码的人不用找：

```text
1. imports（vue / 路由 / 组件 / composable / 类型）
2. defineProps / defineEmits / defineModel（若有）
3. 路由：useRoute / useRouter
4. 本地状态：ref
5. 派生：computed
6. 副作用：watch
7. 方法（事件处理器）
8. 生命周期：onMounted / onUnmounted
9. defineExpose（仅在确实需要时）
```

### 1.2 必须

- `<script setup lang="ts">`；从 `useRoute`/`useRouter` 取参，传给 composable。
- 页面级：`loading` / `empty` / `error`（可重试）/ 主内容，**四态在 template 里可见**。
- 权限不足与未登录：与「空数据」区分文案与动作（回登录 / 回列表 / 申请权限）。
- script 建议 ≤ ~200 行；超出拆 composable 或子组件。

### 1.3 禁止

- 复杂业务规则、字段拼装、日期/枚举转换堆在页面 script。
- 直接调 `api/` 或 `shared/api/http`。
- 在 `App.vue` 或 layout 里塞具体业务页逻辑。
- 用 `v-if` 藏按钮代替真实权限（可藏，但请求与路由仍须鉴权）。

### 1.4 推荐骨架

```vue
<script setup lang="ts">
import { computed } from 'vue'
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

**职责**：有状态用例——请求、表单流程、派生视图模型、订阅；**本 feature 唯一调 `api/` 的地方**（跨 feature 例外见 §0.8）。

### 2.1 必须

- 对外暴露：`ref`/`computed`/方法；命名见意图（`submit`、`reload`、`selectedIds`）。
- **统一返回形态**：状态与行为一起返回，view 直接解构使用：

```ts
export function useOrderList() {
  const rows = ref<OrderListItemVO[]>([])
  const total = ref(0)
  const loading = ref(false)
  const error = ref<UiError | null>(null)

  async function reload() { /* ... */ }

  return { rows, total, loading, error, reload }
}
```

- 处理：**竞态**（路由/入参变化时忽略旧响应或 abort）、**重复提交**（`isSubmitting` 门闩）、**错误 surfacing**（结构化 error，不丢原因）。
- 入参变化（如 `orderId`）用 `watch` 时写清：何时重拉、是否重置列表。
- 需要 auth / 全局壳：可读 `app/stores`；不在 composable 里操作 DOM 选型细节（交给组件）。
- 卸载清理：`onUnmounted` 中 abort 请求、清定时器（`onScopeDispose` 亦可）。

### 2.2 竞态（强制选一种，全项目一致）

```ts
// 模式 A：单调序号
let seq = 0
async function load(id: string) {
  const my = ++seq
  loading.value = true
  error.value = null
  try {
    const data = await fetchOrderDetail(id)
    if (my !== seq) return          // ⚠️ 忽略过期响应：快速切换时防旧数据覆盖新数据
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

### 2.3 禁止

- 返回原始 axios 响应让 view 解包。
- 在 composable 里把 toast 与业务逻辑写死耦合（若项目约定「mutation 成功统一提示」，集中在**一处**策略函数并注释约定；列表加载失败优先内联 error）。
- 把本该 URL 拥有的筛选态只放内存，导致刷新丢失（列表筛选项能进 query 的进 query）。
- 上帝 composable（一个 `useOrder` 包揽列表+详情+表单+WebSocket）；按用例拆 `useOrderList` / `useOrderDetail` / `useOrderForm`。

### 2.4 命名

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
- **返回约定（全项目统一，二选一后不得混用）**：默认返回**已解包的业务数据**（`http.get<T>()` 直接得到 `T`）；失败**抛错**，由调用方映射 `toUiError`。若项目约定返回 `Result<T>`，则所有接口一律返回 `Result<T>`，成功态取 `data`，失败态在边界抛错——**不允许有的接口裸数据、有的包 Result**。

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

### 4.4 组件通信选型

| 场景 | 方式 |
|------|------|
| 父 → 子 | `props` |
| 子 → 父 | `emits` |
| 父子双向绑定 | `defineModel()` / `v-model:xxx` |
| 内容分发与定制 | `slots`（含作用域插槽） |
| 跨多层后代（主题、壳层能力） | `provide` / `inject`，仅传无业务用例依赖的东西 |
| 兄弟 / 无亲缘组件 | 提升到共同父级，或用 `app/stores`（仅真全局态） |
| 跨路由 / session | URL query/params 优先，其次 `app/stores` |

**禁止**：事件总线（mitt 等）当常规通信手段——它绕过了组件树，出问题时无法追踪数据来源。

### 4.5 props / emits / model 的类型化写法

```vue
<script setup lang="ts">
// ✅ 类型化 props + 默认值
const props = withDefaults(defineProps<{
  order: OrderDetailVO
  disabled?: boolean
  maxRows?: number
}>(), {
  disabled: false,
  maxRows: 20,
})

// ✅ 类型化 emits（3.3+ 简写）
const emit = defineEmits<{
  cancel: []
  confirm: [orderId: string]
  'update:keyword': [value: string]
}>()

// ✅ 双向绑定（3.4+）
const keyword = defineModel<string>('keyword', { required: true })
const selected = defineModel<number>('selected')   // 对应 v-model
</script>
```

- **props 只读**：任何修改都通过 emit / `defineModel`，禁止直接赋值（含改深层字段）。
- **props 命名**：template 中 `kebab-case`，声明处 `camelCase`。
- **`defineExpose` 谨慎使用**：优先用 emits 通知父级；只有在父级确实需要命令式调用（如 `focus()`、`reset()`）时才暴露。

### 4.6 属性透传与 `inheritAttrs`

包装原生元素（如给 `BaseInput` 套壳）时：

```vue
<script setup lang="ts">
defineOptions({ inheritAttrs: false })   // 避免 attrs 落到错误的根元素
</script>

<template>
  <div class="field">
    <input v-bind="$attrs" />   <!-- attrs 显式绑定到目标元素 -->
  </div>
</template>
```

### 4.7 模板写法红线

| 规则 | 说明 |
|------|------|
| **禁同元素 `v-if` + `v-for`** | `v-if` 优先级更高，且每次渲染都要遍历；改用 `computed` 过滤，或 `v-if` 外提到 `<template>` |
| **`v-for` 必带稳定 `:key`** | 用业务 id，不用数组下标（列表可重排时会错乱）；组件上的 `v-for` 同样强制 |
| **`v-if` vs `v-show`** | 条件很少变 / 需要销毁重建 → `v-if`；切换频繁 → `v-show` |
| 复杂表达式进 `computed` | 模板里不写三元套三元、不写长链式取值 |
| 事件处理器传引用 | `@click="handleSubmit"`；需参数用 `@click="row => handleRemove(row.id)"` |
| 指令用缩写 | `:` 与 `@`，全项目一致 |
| **禁 `v-html`** | 必须时仅用于可信且**已消毒**内容（明确消毒库，勿手写半截正则） |
| 组件名多词 | 仅根 `App` 可单单词语例外 |
| 属性顺序（Style Guide） | 定义（`is`/`v-is`）→ 列表渲染 → 条件 → 渲染方式 → 全局感知 → 唯一特性 → 双向绑定 → 其他 → 事件 → 内容 |
| 空元素自闭合 | 无内容组件 `<BaseIcon />` |

### 4.8 浮层（Modal / Drawer / Popover / Toast）

- 全项目一套浮层与 z-index/焦点策略；禁止每个 feature 自研一套。
- 严重错误不要**只**靠 Toast；列表/表单失败优先内联或页级 error。
- 不要把「每个操作都开 Modal」当默认架构。

---

## 5. Store（Pinia，`app/stores/`）

**职责**：跨路由、跨 feature、与 session 绑定的状态。典型：**auth**、**app shell**。

### 5.1 建 store 前必须能回答

1. 离开当前页后是否仍需要？  
2. 多个无亲缘组件是否同时读写？  
3. URL 能否表达？（能则优先 URL）

### 5.2 写法

- 用 **setup store**（与 Composition API 一致），不用 options store：

```ts
export const useAuthStore = defineStore('auth', () => {
  const user = ref<UserVO | null>(null)
  const isLoggedIn = computed(() => user.value !== null)

  async function login(body: LoginRequest) { /* ... */ }
  function logout() { /* 清用户态 + 清用户级缓存 */ }

  return { user, isLoggedIn, login, logout }
})
```

- 列表/详情/表单：**默认 composable**，不建 `useOrderListStore`。
- auth：登录态、用户信息、登出清缓存；身份变更必须清用户级客户端缓存。
- 禁止：每个复选框/弹层一个 store；在 store 里堆 DOM/组件引用。
- **禁止在模块顶层取 store**：`useXxxStore()` 必须在函数/组件作用域内调用（路由守卫请在**回调内部**调用，否则 Pinia 未安装会报错）。

---

## 6. 表单与校验

每个表单在动手前想清：

```text
初始值 · 校验规则 · 校验时机 · 提交中状态
服务端错误如何映射到字段 · 成功后去哪 · 取消/脏数据怎么办
```

### 6.1 必须

- 字段值**单一数据源**（不要 input 本地一份、submit 又一份对不上）。
- 提交中禁用重复提交（`isSubmitting`）。
- 失败可恢复：保留用户已填内容；服务端字段错误映射到对应项。
- 可访问：有 label；错误有文案，不只标红。
- 校验时机：失焦校验 + 提交前全量校验，不要「输入第一个字符就报红」。

### 6.2 禁止

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
- 规范化函数集中：`toUiError(e)`（放 `shared` 或 http 旁），composable 统一用。

### 7.2 四态

每一个重要界面显式处理：

1. **Loading** — 用户知道在进行  
2. **Empty** — 无数据，必要时给下一步 CTA  
3. **Error** — 原因 + 是否可重试  
4. **Success** — 主内容；mutation 按风险给反馈  

部分区块失败：不要无必要整页崩溃（区块级 error）。

---

## 8. 认证、路由权限与导航

### 8.1 会话存放（OWASP 对齐，强制）

- **默认**：会话走后端下发的 **`HttpOnly` + `Secure` + `SameSite`** Cookie（或 BFF）；前端 JS **读不到**长期凭证。
- **禁止**用 `localStorage` / `sessionStorage` 存 Access Token、Refresh Token、Session ID、JWT（XSS 即可被偷）。例外须团队书面批准并缩小寿命与权限。
- 若短期 access token 必须进内存：仅内存变量、页刷即失，靠 Cookie 刷新；仍不落 Web Storage。
- Cookie 会话的写操作：后端须有 **CSRF** 防护；前端按约定带 CSRF 头/Token 或同站自定义头——**SameSite 不能单独当银弹**。
- 登录成功后的回跳 URL：只允许站内相对路径或白名单域名；**禁止**把未校验的 `redirect` query 直接 `router.push`（open redirect）。

### 8.2 守卫与权限

- 401/403 在 **http 拦截器 + 路由守卫** 收敛；页面不复制三套 `if (!token)`。
- 需登录路由：`meta.requiresAuth`；守卫集中在 `app/router/guards.ts`。
- **Pinia**：在守卫**回调内**再 `useAuthStore()`，禁止模块顶层取 store（安装顺序会挂）。
- 登出：清 store、清用户级缓存、作废进行中的已认证请求假设。
- UI 藏入口 ≠ 授权；写操作仍以服务端为准。

### 8.3 导航与历史

- 默认 `router.push`；认证跳转、清理 query、替换当前历史坑位用 `replace`，避免用户按后退卡在登录死胡同。
- 脏表单离开（未保存）：适当时确认；破坏性丢稿要可感知。
- 创建实体成功后导航到有用目的地（详情/列表），不要无反馈地停在空表单。

---

## 9. 列表、表格与筛选

- 行 `:key` 用稳定业务 id。  
- 分页 / 筛选 / 排序：默认**服务端**；禁止拉全量假装分页。  
- 有 COUNT 接口就不要为计数拉整表。  
- 筛选态能进 URL 的进 URL（分享、刷新、后退才说得通）。  
- 批量操作：明确选择模型与操作中态；防重复提交。  
- 大列表：考虑虚拟化；不要默认渲染数千 DOM。
- 表格列定义（表头、宽度、格式化器）集中声明，不在模板里堆 20 个 `<el-table-column>` 各写一套格式化函数。

---

## 10. 样式、a11y、安全底线

> 不单独开设计系统专篇；token + 下列红线即底线。

### 10.1 样式

- 颜色/间距/字号优先 `styles/tokens.css` 变量；禁组件内随机 `#3b82f6`。  
- Feature 不复制一套与 `shared` 冲突的按钮视觉。  
- 响应式：关键操作在窄屏仍可用；不要假设「仅桌面」。  
- **样式作用域（Style Guide Priority A）**：除 `App` / layout / 全局 `styles/*` 外，SFC 样式必须 **`scoped`**（或 CSS Modules / 等效 BEM）；禁止未作用域的组件样式污染全局。
- 深度选择器 `:deep()` 只用于确实需要改子组件内部的场景，不作为常规手段。

### 10.2 可访问性（WCAG 可编码底线）

- 交互控件用语义元素或正确 ARIA；**禁 `div` 冒充按钮**还不处理键盘。  
- 表单控件有 label；图标按钮有可访问名称（`aria-label` / 可见文案）。  
- 浮层：焦点陷阱与关闭后焦点恢复按原语统一实现。  
- **可见焦点**：禁止全局干掉 `outline`；用 `:focus-visible` 保证键盘用户看得见。  
- **对比度**：正文对照约 **4.5:1**、大文本/UI 控件约 **3:1**（AA）；token 选色时就要守。  
- **表单错误**：无效字段 `aria-invalid`；错误文案与控件关联；提交失败时焦点落到首个错误。  
- **动态反馈**：loading / 重要 toast 可用 `aria-live`（`polite`），勿对高频无关更新刷屏。  
- 尊重 `prefers-reduced-motion`：非必要动效可关或减弱。

### 10.3 安全

- **默认不** `v-html`；必须时仅可信且**已消毒**内容。  
- 不在前端「藏密钥」；密钥永不进 `VITE_*`。  
- 会话存放与 CSRF：见 §8.1。  
- 日志/上报不落密码、token、隐私字段。  
- 用户输入参与 URL/查询时注意编码；不把未校验输入当指令执行。

---

## 11. 错误边界与白屏

- 关键壳（`App` / layout）或路由出口附近：捕获渲染期错误，展示可恢复 UI（重试/回首页），**禁止**未处理异常直接白屏。  
- Vue：`onErrorCaptured` / `app.config.errorHandler` 与上报衔接；在 handler 里记上下文，勿空吞。  
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
| **解构 props 后 watch 死活不触发** | `props.x` 或 `toRefs` |
| **`reactive` 整体替换丢响应** | 逐字段赋值或改用 `ref` |
| 深度 `watch` 整个大表 | 指定具体路径或 `shallowRef` |
| `computed` 里发请求 | 副作用改 `watch` / 事件 |
| 事件总线满天飞 | props/emits 或提升状态 |

---

## 14. 加代码前五问

1. 这段逻辑属于 View / Composable / API / Component / Store 哪一层？  
2. 异步失败、空、加载，用户分别看到什么？  
3. 入参变化或离开页面时，旧请求会不会写坏状态？  
4. 类型是否在边界对齐后端？有没有 `any` 偷懒？  
5. 若再加一个 boolean prop / 一个 store——能不能重新设计而不是叠复杂度？  

答不清 → 先写进当前 composable 或 page 的正确层，别急着抽「通用万能层」。

---

## 15. 核对清单

**分层与依赖**

- [ ] 每层只做自己的事：View 不调 api、组件不请求、composable 是本 feature 请求入口  
- [ ] 无跨 feature 穿透内部组件/composable；无环依赖  
- [ ] 组件类别正确（原语无领域词、展示组件不调接口）  

**响应式与状态**

- [ ] 未解构 props；未整体替换 `reactive`  
- [ ] 派生用 `computed` 且无副作用；副作用放 `watch` 且有清理  
- [ ] 大对象/第三方实例用 `shallowRef` / `markRaw`  
- [ ] 状态归属正确：能局部不全局，能进 URL 不进 store  

**异步与四态**

- [ ] loading / empty / error / success 四态可见  
- [ ] 有竞态处理（序号或 abort）；卸载有清理  
- [ ] 提交有防重复；错误用 `toUiError` 映射而非静默  

**组件与类型**

- [ ] `defineProps` / `defineEmits` / `defineModel` 均类型化，无裸数组  
- [ ] props 只读；双向绑定走 model；无 6 层透传  
- [ ] `v-for` 有稳定 key；无同元素 `v-if`+`v-for`  
- [ ] 边界无 `any`；与后端 VO 字段对齐  

**质量底线**

- [ ] 样式 `scoped`；焦点可见；无 div 冒充按钮  
- [ ] 无 `v-html` 未消毒内容；无密钥进前端  
- [ ] 无调试残留；关键路径手工过过  

**打回语**

- 「展示组件里调了 api，上提到 composable。」  
- 「解构了 props 导致 watch 不触发，改用 props.x 或 toRefs。」  
- 「reactive 整体替换会丢响应性，逐字段赋值或改 ref。」  
- 「computed 里发了请求，副作用挪到 watch。」  
- 「接口返回有的裸数据有的包 Result，统一成一种。」  
- 「跨 feature import 了 B 的内部组件，改走路由或上收 shared。」  
- 「v-for 用了数组下标当 key，换成业务 id。」  
- 「同元素 v-if + v-for，用 computed 过滤。」  
- 「直接改了 props，改用 emit / defineModel。」  
- 「四态缺 empty，空数据时页面一片空白。」  
- 「卸载没清理定时器/请求，切页后仍在跑。」  
- 「这个 store 只有一个页面在用，降回 composable。」  
