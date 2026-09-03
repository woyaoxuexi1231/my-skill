# Vue 日志与注释规范

> 范围：只定 **日志 / 上报怎么打、注释怎么写**。  
> 注释与可观测性是交付物的一部分，不是收尾可选项。

---

## 0. 三条硬底线

| # | 底线 | 说明 |
|---|------|------|
| 1 | **禁止一行流 TSDoc** | `/** 获取订单列表 */` 挂在 `fetchOrders` 上只是把函数名翻译成中文，等于没写。 |
| 2 | **逻辑体内必须有步骤注释** | 只有函数头注释、函数体一坨裸代码 = 读者只知道「这函数干嘛」，不知道「里面怎么干」。 |
| 3 | **导出的 API 用富文本 TSDoc** | TSDoc 支持 `@param` / `@returns` / `@example` / `@remarks` / 列表，不要用一行话糊过去。 |

**最常见的失败形态：** 函数头一行流注释，函数体 40 行零注释。

```ts
// ❌ 典型失败样本：注释复述函数名，函数体全程裸奔
/** 加载订单详情 */
export function useOrderDetail(orderId: Ref<string>) {
  const order = ref<OrderDetailVO | null>(null)
  const loading = ref(false)
  let seq = 0
  watch(orderId, async (id) => {
    const my = ++seq
    loading.value = true
    try {
      const data = await fetchOrderDetail(id)
      if (my !== seq) return
      order.value = data
    } finally {
      if (my === seq) loading.value = false
    }
  }, { immediate: true })
  return { order, loading }
}
```

---

## 1. 注释的三层结构

| 层级 | 位置 | 回答什么 | 形态 |
|------|------|----------|------|
| 文件头 / 模块注释 | 文件顶部 | 这个文件负责什么、边界与假设 | 块注释 |
| 导出函数 TSDoc | 函数上方 | 做什么、参数/返回/抛错/副作用 | 富文本 TSDoc |
| **行间注释** | 函数体内 | **这段逻辑分几步、每步为什么** | **步骤式 + emoji** |

三层的读者视角：

```text
文件头   → 我要不要动这个文件？它管什么、有什么假设
函数注释 → 我要不要调这个函数？传什么、返回什么、会抛什么
行间注释 → 我要改这段逻辑，它分几步、哪一步有坑
```

---

## 2. 日志与上报

### 2.1 通道选型

| 通道 | 用途 | 说明 |
|------|------|------|
| **`console`** | 本地开发、临时排查 | 简单直接；**禁止**把调试 `console.log` 留进生产主路径 |
| **项目统一 logger**（可选） | 带级别、可关、可桥接到上报 | 新项目若需要级别控制，在 `shared/` 做一个薄封装；不要每个 feature 自研一套 |
| **错误上报 SDK**（若已接） | 生产未捕获异常、关键业务失败 | 与后端 requestId / traceId 关联（后端提供时） |

- **新项目**：不强制一上来上 Sentry 级全家桶；但必须约定——失败如何进用户可见错误 + 开发期如何打日志。接了上报就全项目走同一入口。
- **已有项目**：已有 logger / 上报 → **不必为换而换**；写法仍遵守本篇级别与脱敏。
- 禁止同一工程多套上报抢事件、或业务里直接调三个不同 SDK。

### 2.2 级别（语义对齐后端，落点不同）

| 级别 | 何时 | 典型落点 |
|------|------|----------|
| **error** | 系统/逻辑出错、请求失败需关注、未预期异常 | `console.error` 和/或 上报 |
| **warn** | 可恢复异常、降级、废弃 API、校验被拦 | `console.warn`；按需上报 |
| **info** | 关键业务里程碑（登录成功、支付发起等）——**克制** | 开发期 console；生产默认不要刷 |
| **debug** | 细节排查 | 仅开发；生产关闭或剥离 |

生产默认：**不要**对每个请求/每次渲染打 info/debug。

### 2.3 必须

- 异常与业务失败：带上**足够上下文**（业务 id、路由名/path、动作、失败原因）。有 `Error` 时保留对象（`console.error(msg, err)` 或上报 `error` 字段），不要只打 `"error"`。
- HTTP 失败：记 **method + url 路径 + HTTP 状态 / 业务码**（不要记完整 token、不要默认 dump 整份 body）。
- 与后端约定了 `requestId` / `traceId`：失败日志与上报带上，便于联调。
- 同一项目风格一致：优先统一 `logger` 或统一「何时 console / 何时 report」。
- 用户可见文案走错误模型（`toUiError`）；**日志可以更技术，UI 文案不能堆栈**。

### 2.4 禁止

- 记录：密码、Access Token、Authorization、Cookie 全文、密钥、身份证/手机号等不必要 PII、支付敏感卡号。
- 默认给每个函数打进入/退出日志；在 `watch` / `computed` / 渲染路径里打高频 log。
- `catch (e) { console.log(e) }` 当唯一处理且不映射 UI 错误、不上抛、不上报。
- 用日志代替控制流（「打了就算处理完」）。
- 提交代码残留：`console.log(response)`、`console.log('here')`、`debugger`。
- 生产路径无节制 `console.log` 刷屏（含把整个 props/state 打出来）。
- 在日志里拼接后仍把敏感对象整对象传入（`console.log('user', user)` 若 user 含 token 同等泄露）。

### 2.5 推荐形态

```ts
// 好：动作 + 业务键 + 原因 + Error 对象
logger.warn('创建订单失败', { orderId, userId, reason: e.message }, e)
// 或
console.error(`[order] create failed orderId=${orderId}`, e)

// 差：无上下文 / 调试残留 / 泄密
console.log(e)
console.log('start')
console.log('token', localStorage.getItem('token'))
console.log(response.data) // 常含 PII；且易残留
```

```ts
// 好：catch 后仍走错误模型
try {
  await createOrder(body)
} catch (e) {
  error.value = toUiError(e)
  logger.error('createOrder failed', { feature: 'order' }, e)
  return
}
```

### 2.6 分层里日志放哪

| 层 | 日志 / 上报 |
|----|-------------|
| **http 拦截器** | 传输层失败、401/403 策略触发（脱敏）；可打 status + url |
| **composable** | 用例失败的业务上下文（id、动作）；与 UI error 同时存在 |
| **view / 纯展示组件** | 默认不打业务日志；除非捕获了边界错误 |
| **路由守卫** | 鉴权拒绝可 debug/warn（勿刷）；勿打 token |
| **API 函数** | 默认不打（太吵）；转换/兼容坑用注释，失败让调用方记 |

重复：同一失败不要在 http + composable + view **各打一遍无差别** error；约定「业务失败以 composable 为准，传输细节在 http」。

### 2.7 上报（项目已接时）

- 只报：**未捕获异常**、**关键 mutation 失败**、**白屏/边界错误**——不要报每一次校验未通过。
- 事件名稳定、可聚合：`order.create.failed`，禁每次不同的随机句子当事件名。
- payload 白名单字段；默认剥离 headers、cookie、密码表单。
- 用户改身份 / 登出后：清上报面包屑里的用户态（若 SDK 支持）。

---

## 3. 注释

### 3.1 文件头注释

**Composable 文件、非显而易见的 `shared` 模块**：文件头用块注释写清职责、边界、假设。

```ts
/**
 * 订单列表用例：分页查询、筛选与删除后刷新。
 *
 * 假设与边界：
 * - 筛选态与 URL query 双向同步，刷新/分享均可还原
 * - 离开页面会 abort 进行中的列表请求
 * - 排序与分页由服务端完成，前端不做客户端分页
 */
export function useOrderList() { }
```

**Vue SFC**：一般不写长篇文件头；在 `<script>` 里对非显而易见的决策写 `//` 即可。公开库级别的原语组件可为 props 补 TSDoc。

### 3.2 导出函数 / 类型：富文本 TSDoc

**必写要素：**

| 要素 | 何时必写 |
|------|----------|
| 一句目的 | **总是** |
| 补充段落（副作用、边界、失败行为） | 有非显而易见行为时**必须**写 |
| `@param` | 参数含义不自明、有单位（ms/页）、取值范围要求时 |
| `@returns` | 返回语义不自明、可能为空、是快照还是响应式引用时 |
| `@throws` | 会抛业务错误时写清**什么条件下抛** |
| `@example` | 用法不直观时（尤其原语组件与 composable） |

```ts
/**
 * 创建订单并在成功后失效列表缓存。
 *
 * <p>库存不足时会抛出业务错误（code=STOCK_INSUFFICIENT），调用方需自行映射提示；
 * 本函数不弹 toast，成功反馈交给调用方决定。</p>
 *
 * @param body 创建参数；金额单位为分，数量必须大于 0
 * @returns 新订单详情（服务端返回的后端真值，非乐观更新）
 * @throws UiError 校验失败 / 库存不足 / 网络错误
 *
 * @example
 * try {
 *   const order = await createOrder(body)
 *   router.push({ name: 'OrderDetail', params: { id: order.id } })
 * } catch (e) {
 *   error.value = toUiError(e)
 * }
 */
export function createOrder(body: CreateOrderRequest) {
  return http.post<OrderDetailVO>('/api/orders', body)
}
```

**判断标准：把函数名和签名遮住，只看注释，能否知道该不该调、怎么调、会出什么事？** 不能 → 重写。

### 3.3 不需要写的情况

- 显而易见的赋值、一行 getter、琐碎的转发。
- 已用类型表达清楚的 props（不必给每个 prop 写「这是 xxx」而无约束说明）。
- 但「有内容可写却偷懒写一行」按 §0 第 1 条打回。

### 3.4 行间注释（分步骤）——重点

**这是最容易被省略、也最影响可读性的一层。**

函数头说明「做什么」，行间注释说明「怎么做的、分几步、每步为什么」。

#### 硬性要求

| 触发条件 | 要求 |
|----------|------|
| 函数体非空行 **≥ 10 行** | 必须有步骤注释 |
| 含 **≥ 3 个逻辑段落** | 每段至少一行注释 |
| 有 `if` / `switch` / `try-catch` / 循环，且做了非显而易见的事 | 必须注释**为什么走这个分支** |
| 有校验、转换、过滤、聚合等多步处理 | 按步骤编号注释 |

#### 写法：编号步骤

用**圈号数字 `①` `②` `③`**开头，一眼看出第几步、一共几步：

```ts
// ① 干什么
// ② 干什么
// ③ 干什么
```

每步**先说干什么，必要时补为什么**：

```ts
// ② 过滤已取消项：这些行不参与合计，提前剔除避免后面反复判断
```

**步骤数控制在 3~7 步。** 超过 7 步说明这个函数承担太多——先拆函数，而不是写第 8 步注释。

#### emoji 用法

| 场景 | 符号 | 说明 |
|------|------|------|
| 步骤序号 | ① ② ③ | 默认用法，让步骤可扫读 |
| 警告 / 坑 | ⚠️ | 竞态、响应式陷阱、不可删的变通 |
| 外部依赖 / 请求 | 🌐 | 跨服务调用（可选） |
| 性能相关 | ⚡ | 这里做了优化或有性能约束（可选） |

> **序号统一用圈号数字 `①` `②` `③`（U+2460 起），不用 emoji 键帽 `1️⃣` 等。**
> 键帽序号是「数字 + 变体选择符 + 组合标记」的 emoji 序列，IDEA / VS Code 等编辑器的默认等宽字体不渲染，会显示成方框；圈号数字是普通文本字符，任何编辑器、任何字体、任何语言环境都能正常显示。

**步骤序号用圈号数字，是结构化用法，不算「滥用」**；装饰性 emoji 才受克制约束。

#### 完整示例

把 §0 的失败样本改写成合格版本：

```ts
/**
 * 订单详情用例：按 id 拉取详情，id 变化时自动重拉。
 *
 * <p>并发切换 id 时用单调序号丢弃过期响应，避免旧数据覆盖新数据。</p>
 *
 * @param orderId 订单 id 的响应式引用（通常来自路由参数）
 * @returns 详情数据、加载态与错误态
 */
export function useOrderDetail(orderId: Ref<string>) {
  const order = ref<OrderDetailVO | null>(null)
  const loading = ref(false)
  const error = ref<UiError | null>(null)

  // 用于判定响应是否过期：每次请求自增
  let seq = 0

  watch(orderId, async (id) => {
    // ① 领取本次请求序号：id 快速切换时靠它丢弃旧响应
    const my = ++seq

    // ② 进入加载态并清空旧数据，避免刷新瞬间闪出上一个订单
    loading.value = true
    error.value = null
    order.value = null

    try {
      const data = await fetchOrderDetail(id)

      // ⚠️ ③ 过期响应直接丢弃：期间已切换到别的订单，写回会串数据
      if (my !== seq) return

      order.value = data
    } catch (e) {
      if (my !== seq) return
      error.value = toUiError(e)
    } finally {
      // ④ 仅最后一次请求负责收尾，避免提前关掉 loading
      if (my === seq) loading.value = false
    }
  }, { immediate: true })

  return { order, loading, error }
}
```

再看一个含分支的例子：

```ts
async function submit() {
  // ① 防重复提交：isSubmitting 期间直接丢弃后续点击
  if (isSubmitting.value) return
  isSubmitting.value = true

  try {
    // ② 提交：服务端是价格与库存的唯一权威，前端不预计算
    const created = await createOrder(form.value)

    // ③ 成功后失效列表缓存，回到列表时能看到新建项
    await listStore.invalidate()

    // ④ 跳转详情：创建成功后不能停在空表单让用户以为失败
    await router.push({ name: 'OrderDetail', params: { id: created.id } })
  } catch (e) {
    // ⚠️ ⑤ 校验错误映射到字段，其余走页级错误；不清空用户已填内容
    const uiError = toUiError(e)
    if (uiError.fieldErrors) {
      applyFieldErrors(uiError.fieldErrors)
    } else {
      pageError.value = uiError
    }
  } finally {
    isSubmitting.value = false
  }
}
```

#### 行间注释反模式

```ts
// ❌ 逐行复述代码（把 TS 翻译成中文）
const rows = ref([])          // 定义行数据
loading.value = true          // 设置加载中
await fetchOrders()           // 调用接口

// ❌ 只有函数头注释，函数体裸奔
// ❌ 注释与代码矛盾（改了代码没改注释）
// ❌ 用注释解释烂命名（应改名）
// ❌ 每步都加装饰 emoji，看不出重点
```

**判断一句行间注释是否有价值：删掉它，读者会不会多花时间才能看懂？** 不会 → 删掉这句注释。

### 3.5 注释内容：写「为什么」

优先回答：

```text
为什么这样设计交互 / 状态归属？
为什么竞态用序号而不是 abort（或反过来）？
为什么这个状态进 URL？
为什么这里用 shallowRef / markRaw？
为什么有这个浏览器 / iOS 变通？何时可删？
为什么不能 v-html / 为什么焦点如此移动？
为什么列表必须服务端分页？
```

不写：

```text
设置 loading / 调用 API / 获取订单列表 / 定义变量
```

该写注释的类别（出现时就要写）：

| 类别 | 写什么 |
|------|--------|
| 业务规则 | 非显而易见的可编辑条件、状态机分支 |
| 竞态 / 取消 | 为何忽略过期响应；signal 生命周期 |
| 响应式陷阱 | 为何用 `shallowRef`、为何不能解构、为何整体替换会失效 |
| URL / 路由状态 | 为何用 query 形状；兼容旧参数名 |
| 浏览器 / 平台怪癖 | iOS Safari、焦点、剪贴板须在用户手势内等 |
| 可访问性 | 焦点陷阱、为何不用 div 按钮、活区说明 |
| 性能 | 为何虚拟化、为何防抖、为何不深 watch |
| 安全 | 为何不直接 `v-html`；token 存放取舍 |
| 兼容 / 变通 | 为何存在、何时可删 |
| API 契约 | 后端日期用 epoch、字段名历史原因等边界转换 |

### 3.6 模板里的注释

- `<!-- -->` 只用于**非显而易见**的结构意图（如「此槽位给权限不足态」），不要给每个 `div` 贴标签。
- 禁止在模板注释里写密钥、环境地址、临时账号密码。
- 四态分支（loading/empty/error）若不易分辨，可加一行注释说明这一支对应用户看到的什么状态。

### 3.7 注释必须正确

```text
代码已改 → 审查附近注释 → 更新或删除过时注释
```

- 错误注释比没有注释更糟。
- 不要用注释弥补烂命名：先改成 `useOrderList` / `isSubmitting`，再补真正需要的「为什么」。
- 重构后步骤编号要重新连续（不要出现 ① ② ④）。

### 3.8 各层注释重点

| 层 | 注释重点 |
|----|----------|
| View | 页面级权限/四态特殊分支；少而准 |
| Composable | 文件头写假设；行内写竞态、刷新策略、与 URL 同步、业务规则 |
| API | 传输格式转换、与后端不一致的历史字段 |
| UI 原语 | 焦点、a11y、受控模式 |
| Store | 为何是全局态；登出清理约定 |
| 路由守卫 | meta 含义；重定向为何用 replace |

---

## 4. Emoji（允许，克制）

### 原则

- **适当、少量、有辨识度**——不是装饰义务。
- 步骤序号用圈号数字 `①` `②` `③`，属于**结构化用法**，不在此限（见 §3.4）。
- **禁止**每条注释、每条日志都加；禁止一串表情刷屏。
- 同一类事件尽量固定同一符号（例如失败用同一类）。

### 适合加的地方

| 场景 | 说明 |
|------|------|
| 行间步骤序号 | ① ② ③（默认用法） |
| 警告性说明 | 竞态陷阱、响应式坑、不可删变通、安全注意（⚠️） |
| 失败 / 降级 / 告警日志 | 让 error/warn 更好扫 |
| 关键路径节点 | 鉴权就绪、应用启动完成（开发期） |

### 不适合加的地方

- 每行业务注释、每条 debug、每个 prop 说明。
- 用 emoji 代替清楚文字（表情不能替代 `orderId=`）。
- 给终端**用户**看的 Toast/文案靠 emoji 表达对错（产品另有规范除外）。

### 示例

```ts
// ⚠️ 忽略过期响应：快速切换订单详情时防止旧请求覆盖新数据
if (my !== seq) return

logger.error('❌ 创建订单失败', { orderId }, e)
```

---

## 5. 核对清单

**日志 / 上报**

- [ ] 无调试残留 `console.log` / `debugger` 进主路径  
- [ ] 失败有业务上下文；保留 Error；级别合理  
- [ ] 无 token / 密码 / 多余 PII；无整包敏感 response dump  
- [ ] 未用日志代替 UI 错误处理  
- [ ] 同一失败未在多层无差别重复刷屏  
- [ ] 已接上报时：事件可聚合、payload 脱敏  
- [ ] emoji（若有）仅关键/失败点，未滥用  

**注释**

- [ ] composable / 非显而易见模块有文件头，写清职责与假设  
- [ ] 导出 API 用富文本 TSDoc（`@param` / `@returns` / `@throws`），**无一行流**  
- [ ] **函数体 ≥10 行或多逻辑段的，有编号步骤注释（① ② ③）**  
- [ ] 步骤数 ≤ 7；超过说明函数该拆  
- [ ] 分支 / 循环 / 异常处理写了「为什么走这个分支」  
- [ ] 竞态、响应式陷阱、a11y、安全、变通有「为什么」  
- [ ] 无复述代码的废话注释；无与代码矛盾的注释  
- [ ] 步骤编号连续，无跳号  

**打回语**

- 「这是把函数名翻译了一遍，重写：写清失败行为、副作用、参数约束。」  
- 「函数体 40 行零注释，补编号步骤注释。」  
- 「步骤注释只写了『调用接口』，没说为什么这么调。」  
- 「第 3 步删了，编号还是 ①②④，重排。」  
- 「7 步以上了，先拆函数再补注释。」  
- 「失败日志缺 orderId。」  
- 「生产路径留下 console.log(response)。」  
- 「这条注释与代码矛盾，更新后再提。」  
- 「emoji 过密，只在步骤序号和警示处保留。」  
