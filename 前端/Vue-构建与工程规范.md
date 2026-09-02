# Vue 构建与工程规范

> 范围：**环境变量、Vite 配置、依赖、构建交付、工程卫生、测试底线**。  
> 目录与调用方向见 [`Vue-代码架构.md`](Vue-代码架构.md)；各层写法见 [`Vue-模块代码规范.md`](Vue-模块代码规范.md)；console/上报/注释见 [`Vue-日志与注释规范.md`](Vue-日志与注释规范.md)。  
> 本篇偏 **工程落地**，不写业务组件怎么画。

**技术基底**：Vue 3 · Vite · TypeScript · Vue Router 4 · Pinia。

---

## 1. 代码 vs 配置

| 放代码 | 放 env / Vite 配置 |
|--------|-------------------|
| 稳定业务规则与分支 | API baseURL、代理目标 |
| 领域常量 / 枚举 | 超时默认、功能开关（随环境变） |
| 组件与 composable | 公钥级配置（如可公开的 client id） |
| 路由表、权限 meta 结构 | `base` 公共路径、sourcemap 开关 |

不要把每个魔法数字都变成 env；**随环境变化**或**部署时才确定**的才进配置。  
密钥、私钥、数据库密码等**永远不进**前端包——前端可见即泄露。

---

## 2. 环境变量

### 2.1 文件约定

```text
.env                  # 全环境可共享的非敏感默认（可选）
.env.development      # 本地开发
.env.production       # 生产构建
.env.local            # 本机覆盖（必须 gitignore，勿提交）
```

- 多环境要有可切换的对应文件（或 CI 注入等价变量）；禁止「脚本自称 prod 却没有生产变量来源」。
- 变量名、含义在 README 或本仓库约定里列**键名**（不写真实密钥值）。

### 2.2 `VITE_` 规则（强制）

- 只有 **`VITE_` 前缀**会打进客户端包；用 `import.meta.env.VITE_*` 读取。
- **禁止**把密钥、Admin Token、私钥、连接串放进任何 `VITE_*`（会进 bundle，人人可下载）。
- 需要服务端保密的能力 → 走后端 API，不在前端藏。
- 类型：在 `env.d.ts`（或等价）为用到的 `ImportMetaEnv` 声明字段，避免满项目 `as string`。

```ts
// env.d.ts
interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  readonly VITE_APP_TITLE?: string
}
interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

### 2.3 禁止

- 密码 / Token 写死在源码、可提交的 `.env`、或「假装隐藏」的常量文件里。
- 同含义配置多处硬编码（有的写死 localhost，有的读 env）却说不清优先级。
- 仅本机偶然能跑的隐式默认（别人 clone 必挂且无文档）。
- 提交 `.env.local`、含真实密钥的 `.env.production`。

---

## 3. Vite 与路径

### 3.1 必须在 `vite.config.ts` 一处完成

| 项 | 约定 |
|----|------|
| 路径别名 | `@` → `src`（与架构目录一致） |
| 开发代理 | `server.proxy` 指向后端；**禁止**各 api 文件硬编码完整后端主机 |
| `base` | 按部署子路径配置；与路由 history base 一致 |
| 产物目录 | 默认 `dist`（或团队统一）；CI 据此采集 |
| 构建目标 | 与要支持的浏览器范围一致，不无故升到过新 |

### 3.2 开发代理

```ts
// 示意：目标地址来自 env 或写明仅开发用
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true,
    },
  },
}
```

- 生产不靠 Vite proxy；生产 API 地址用 `VITE_API_BASE_URL` 或同域反代（运维侧）。
- 跨域、Cookie、WebSocket 代理在 config 写清，不散落业务代码临时改。

### 3.3 禁止

- feature 内 `../../../` 深钻别的 feature 内部（依赖方向见架构篇）。
- 为「方便」把 `base` / 别名改来改去却不改路由与静态资源引用。
- 提交本机绝对路径进 config。

---

## 4. TypeScript、Lint、格式

### 必须

- 新项目默认 **TypeScript strict**（或团队已有同等严格度）；禁止为省事全局 `"strict": false` 开倒车。
- `vue-tsc`（或等价）类型检查纳入交付门禁；改契约要过类型，不靠 `any` 闯关。
- ESLint：优先 **`eslint-plugin-vue` recommended**（覆盖同元素 `v-if`+`v-for`、多词组件名等 Style Guide Priority A）；再叠加仓库 Prettier / 格式化。跟已有配置走，**不**在单次任务里换一套风格战争。
- IDE / CI 同一套规则；禁止「我本地关了 lint」。
- 团队统一 **Node 主版本**（`engines` 和/或 `.nvmrc`）；CI 与本地一致。

### 禁止

- 大面积 `// @ts-ignore` / `eslint-disable` 掩盖问题；单行禁用须写原因且尽量收窄范围。
- 新增与现有栈重复的检查工具（两套 ESLint 抢跑）。

---

## 5. 依赖纪律

每个依赖都有成本：体积、升级、认知、供应链、打包。

### 必须

- 只引入**当前用到**的包；不预装「以后可能用」的微前端 / 巨型 UI 套件 / 第二套状态库。
- 同一关注点不并存两套（两个日期库、两套 UI、两个 HTTP 客户端）。
- 优先 Vue / Vite 生态内已有选择（Router、Pinia、仓库已用的组件库）。
- lockfile（`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock`）**提交**；CI 用冻结安装（如 `pnpm install --frozen-lockfile`）。

### 禁止

- 为一个小函数引入巨型库（且项目已有等价工具时）。
- 随便升 major 又不看 breaking change。
- 把 `node_modules` 或构建产物当源码提交。
- 在业务 PR 里顺手「大扫除换依赖」无说明。

### 脚本约定（推荐）

```text
dev       → vite 开发服
build     → vue-tsc -b && vite build（或等价：先类型再构建）
preview   → vite preview
lint      → eslint
test      → vitest（有则）
typecheck → vue-tsc --noEmit
```

脚本名与 CI 调用一致；不要本机一个命令、CI 另一个互不相干。

---

## 6. 构建与交付诚实性

### 声称完成之前至少

- [ ] `build`（含类型检查）能通过  
- [ ] 适用时 lint 通过  
- [ ] 关键路由能打开；主路径交互可用  
- [ ] 成功路径无新增明显 console error  
- [ ] 无残留 `debugger`、调试用 `console.log(response)`  

未实际执行构建/测试时，**禁止**声称「已通过」「生产就绪」。

### 产物与部署

- 生产静态资源走 CDN/网关时：注意 `base`、缓存与 `index.html` 不长期强缓（避免用户卡旧入口）。
- 环境切换靠构建时 env 或运行时运维注入的**公开**配置，不靠改源码打多份业务分支。
- Docker / Nginx 示例若有：与 `base`、反代 `/api` 一致；本篇不绑定某一云厂商。

### Sourcemap、上报与安全头

- 生产 sourcemap：**默认不公网直出**完整 map；若上传给错误监控，走私有通道，勿把 `.map` 裸挂在可匿名下载的 CDN 上（除非团队明文接受）。
- 上报 SDK 的 DSN 若必须进前端：视为「可公开的写入端点」，仍不在此塞其他密钥；事件脱敏见日志篇。
- **CSP**：生产建议由网关/Nginx 配 Content-Security-Policy（限制脚本来源）；前端避免 `eval`、无必要的 inline script。细则与 Cookie/CSRF 见模块规范 §8。
- 配套头（部署侧）：`X-Content-Type-Options`、`Referrer-Policy`、按需 `frame-ancestors` / 点击劫持防护——不在业务代码里「假装设置」。

---

## 7. Git 与工程卫生

### 建议 gitignore（至少）

```text
node_modules
dist
dist-ssr
*.local
.env.local
.env.*.local
.DS_Store
coverage
*.log
```

- 含真实密钥的文件不进库；演示用假值可进 `.env.development` 且标注非生产。
- 编码 UTF-8；换行风格团队统一（推荐 lf）。
- 不要提交：IDE 个人杂讯、巨大二进制、误放的导出数据。

### 目录与架构一致

- 新建文件服从 `features/` · `shared/` · `app/`；不为了配一个工具破坏依赖方向。
- 删除死代码、废弃 env 键、双轨 API；开发期约定「可改契约」时改完不留幽灵配置。

---

## 8. 单元 / 组件测试（底线）

有测试工具时遵守；没有也不要假装有覆盖率。

### 必须（一旦引入 Vitest / Testing Library 等）

- 测试放在约定位置（如 `*.spec.ts` / `__tests__`），禁止与无断言的临时脚本冒充测试。
- 遵守 AIR：Automatic（自动 assert，禁用人肉看 console 验收）、Independent（不依赖执行顺序）、Repeatable（不依赖偶发外部环境；HTTP 可 mock）。
- 优先测：纯函数 / 校验器、错误映射、关键 composable 状态转换、鉴权跳转、表单提交抑制。
- 语义化查询优先；少绑偶然 CSS class。

### 不要

- 追逐无意义覆盖率数字。
- 为测而测破坏生产代码可读性。
- E2E 未接稳时宣称「全流程已自动化」。

无测试框架的小型项目：交付仍须手工过关键路径，且不谎报「单测已过」。

---

## 9. 本地联调与后端协作（工程面）

- 本地默认：Vite proxy → 后端；前后端 VO 字段名对齐，改契约两边一起改。
- Mock：仅当后端未就绪且团队约定可用；Mock 与真实契约偏差要标 TODO/可删期限，禁止 Mock 形状漂成第二套 API。
- HTTPS / Cookie 本地坑：在 README 记清，不在业务里写死只适合某台机器的 hack。

---

## 10. 反模式速查

| 反模式 | 正确方向 |
|--------|----------|
| 密钥进 `VITE_*` | 保密逻辑放后端 |
| api 里写死 `http://192.168.x.x` | proxy + `VITE_API_BASE_URL` |
| 无 lockfile / 不提交 lockfile | 锁版本进库 + CI 冻结安装 |
| 为过类型全局关 strict | 修类型或收窄边界 |
| 「能跑」但从未 `build` | 交付前过构建门禁 |
| 生产公网挂全量 sourcemap | 私有上传或关闭 |
| 一次 PR 换 UI 库 + 状态库 | 无需求不换；要换单独说明 |
| `.env.local` 提交到 Git | gitignore |
| 无 eslint-plugin-vue / 关 Priority A | 启用 recommended；修同元素 v-if+v-for 等 |

---

## 11. 核对清单

**环境与配置**

- [ ] 仅公开配置进 `VITE_*`；无密钥进库、进包  
- [ ] `env.d.ts` 声明用到的变量；`.env.local` 已忽略  
- [ ] 开发代理与生产 baseURL 策略说得清  

**Vite / 工程**

- [ ] `@` → `src`；proxy / `base` / 产物目录在 config 一处  
- [ ] lockfile 在库；未引入用不到的巨型依赖、无重复栈  

**质量门禁**

- [ ] typecheck + build 实际跑过；适用时 lint 过  
- [ ] 无 `debugger`、无调试 console 残留  
- [ ] 有测试则关键路径有断言且可重复；无测试不谎报  

**交付**

- [ ] 未谎报构建/测试结果  
- [ ] 生产 sourcemap / 上报策略符合团队安全预期  

打回示例：「密钥进了 VITE_。」 / 「没跑 build 就说完成。」 / 「api 写死内网 IP。」 / 「lockfile 没提交。」
