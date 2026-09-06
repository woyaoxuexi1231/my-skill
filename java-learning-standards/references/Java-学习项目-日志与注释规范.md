# Java 学习项目 日志与注释规范

> 范围：**学习 / 实验 / 教程型 Java 项目**的注释与日志（lab、demo、POC、教学示例，如 auth-lab 各认证模块）。
> 目标不是「上线好排查」，而是 **代码即教材——半年后回看，或别人第一次读，不借助外部资料也能看懂原理与取舍**。
> **与生产规范互斥**：业务 / 生产项目的注释与日志走 `java-code-standards/references/Java-日志与注释规范.md`，两篇不混用、不互相套用。
> **编号约定**：步骤编号统一用 **emoji 键帽数字** `1️⃣ 2️⃣ 3️⃣ 4️⃣ …`，全仓库一致（Java / Python / Vue / 学习项目规范同一套），**不用**圈号数字 `① ② ③`。
> 键帽覆盖 1~9（`数字 + U+FE0F + U+20E3`），第 10 步用 `🔟`；**11 步及以上** Unicode 无对应键帽，保留圈号 `⑪ ⑫`（见 §3.1 示例）。

***

# 第 0 章 先判断：这是学习项目还是生产项目

| 维度 | 学习项目（本篇） | 生产项目（java-code-standards） |
| --- | --- | --- |
| 读者 | 未来的自己、初学者 | 同事、值班人 |
| 注释目的 | **讲清原理、机制、取舍** | 快速理解、便于排查 |
| 注释密度 | **全类型详写，不分厚薄** | 按类类型分级（config / service 厚，controller 薄） |
| 要不要解释框架 | **要**：谁调用我、框架在背后做了什么 | 不需要，读者都懂 |
| 方法长度 | 可以长（演示完整性优先），但须标注「生产应拆分」 | ≤7 步，超了先拆方法 |
| 日志目的 | **运行时教具**：把执行流程演一遍给人看 | 线上可观测：失败可定位 |
| 入口 / 出口 / 分支日志 | **鼓励**（要看清走了哪条路） | 禁止刷屏 |
| 打印中间值 | **鼓励**（脱敏后） | 只打业务键 |
| 踩坑记录 | **鼓励保留**（曾经错在哪） | 不保留历史演进 |

判断口诀：**这份代码的读者需要「被教会」，还是只需要「被提醒」？** 前者用本篇。判断不清时按学习项目处理——宁详勿略。

***

# 第一章 注释（Comments）

## 1.1 三条硬底线

| # | 底线 | 说明 |
| --- | --- | --- |
| 1 | **代码即教材** | 读者只看代码 + 注释，就能还原这套机制怎么跑起来。「懂的人不用看、不懂的人看不懂」的注释一律不合格。 |
| 2 | **必须写「框架在背后做了什么」** | 谁在什么时候调用我、我返回的东西被谁消费、这个注解触发框架什么动作。**这是与生产注释最大的区别。** |
| 3 | **详写 ≠ 复述** | 写「为什么 / 机制 / 取舍 / 坑」，不写「这行代码在干什么」。逐行翻译代码照样打回。 |

## 1.2 类注释六要素（全类型必写）

学习项目的类注释不再「一句话带过」，按下面六项写，缺项按 §1.12 打回语处理：

1. **职责一句话**——这个类是干什么的。
2. **链路位置**——用 ASCII 图画「谁 → 我 → 谁」，标出我在整条链路的第几步。
3. **生命周期 / 调用者**——谁创建它（组件扫描？`@Bean`？）、谁调用它、什么时候调用（每次请求？启动一次？事件触发？）。
4. **关键设计选择**——为什么这样设计，代价 / 前提是什么（如「无状态」「不查 Session」「单 Token 不引入 Refresh」）。
5. **边界 / 对比**——跨模块有同名或同类实现时**必写**差异；或写清「本类不管什么」。
6. **配套文档**——指向 `docs/` 下对应原理文档（如有）。分工见 §1.10。

**合格范例**（取自 auth-lab `JwtAuthenticationFilter`，可直接照抄结构）：

```java
/**
 * JWT 认证过滤器 — 从 Authorization 头提取 JWT，验证并恢复认证状态。
 *
 * <p>职责：只负责"识别已登录用户"，不负责"拒绝未登录用户"。
 * 如果请求没有合法 JWT，过滤器静默跳过；后续 FilterSecurityInterceptor
 * 发现 SecurityContext 为空时会自动返回 401。</p>
 *
 * <p>继承 {@code OncePerRequestFilter}：保证每个请求只执行一次过滤逻辑，
 * 即使在 forward/include 场景下也不会重复执行。</p>
 *
 * <p>12 步执行流程（步骤 4️⃣ 一次性解析 JWT，验签/过期/格式均在此完成，避免重复解析）：
 * <pre>
 * 1️⃣ 取 Authorization 头 → 2️⃣ 检查 Bearer 前缀 → 3️⃣ 提取 JWT 字符串
 * → 4️⃣ 一次性解析 JWT（验签+过期+格式）取 username → 5️⃣ 检查 SecurityContext 是否已有认证
 * → 6️⃣ 从 DB 加载 UserDetails → 7️⃣ 校验 JWT 用户名 == DB 用户名
 * → 8️⃣ 从已解析 Claims 取权限 → 9️⃣ 创建 UsernamePasswordAuthenticationToken
 * → 🔟 设置 details → ⑪ 放入 SecurityContextHolder → ⑫ filterChain.doFilter() 继续
 * </pre>
 */
```

这段同时覆盖了：职责、边界（只识别不拒绝）、设计选择（一次解析复用 Claims）、链路位置（12 步流程图）、调用者（过滤器链每次请求）。

## 1.3 方法注释：必须交代「谁调用我」

| 要素 | 要求 |
| --- | --- |
| 一句目的 | 总是 |
| **调用者与调用时机** | **总是**——尤其 `@Override` / `@Bean` / 回调 / 监听器方法 |
| 参数语义 | 参数从哪来、格式、取值范围；`@param` 有单位 / 范围时必写 |
| 返回值去向 | 这个返回值被谁消费（给框架？给上游？）；`@return` 写是否可能为 `null` |
| 异常 | `@throws` 写「什么条件下抛 → 抛出去后被谁处理 → 最终变成什么响应」 |
| 副作用 | 改了 ThreadLocal / 写了上下文 / 发了事件 → 必写 |
| 失败行为 | 失败是抛异常、静默跳过、还是降级？ |

**重写 / 框架回调方法**额外必写三件事：**被谁调用、什么时候调用、返回值或写出的东西被谁消费**。学习项目里这三项最常被漏，也最有价值。

**合格范例**（取自 auth-lab `SecurityConfig`）：

```java
/**
 * 暴露 AuthenticationManager 为 Bean。
 *
 * <p>AuthController 登录时需要手动调用 {@code authenticationManager.authenticate()}
 * 来验证用户名密码。默认 AuthenticationManager 可通过依赖注入获得，但显式声明为 Bean
 * 更清晰且便于测试。</p>
 *
 * <p>认证流程（内部）：
 * <pre>
 *   authenticate(token) → DaoAuthenticationProvider
 *     → UserDetailsService.loadUserByUsername()   // 从 DB 加载用户
 *     → BCryptPasswordEncoder.matches()           // 比对密码
 *     → 成功返回已认证 Authentication / 失败抛 BadCredentialsException
 * </pre>
 */
@Bean
public AuthenticationManager authenticationManager(AuthenticationConfiguration c) throws Exception {
    return c.getAuthenticationManager();
}
```

## 1.4 字段与注解注释

- **每个注入的依赖**：注释「它是什么 + 我为什么需要它」。生产规范里这算废话，学习项目里这是知识点。

```java
private final JwtUtil jwtUtil;                       // JWT 工具：生成、解析、验证 JWT
private final UserDetailsService userDetailsService; // 从数据库加载用户信息
```

- **每个非显然注解**：在注解所在行尾或上一行用 `//` 说明它的作用与触发时机。

```java
@Configuration                // 声明为 Spring 配置类，启动时加载
@EnableWebSecurity            // 激活 Spring Security Web 安全（注册默认过滤器链）
@RequiredArgsConstructor      // Lombok：为所有 final 字段生成构造函数（构造注入）
```

- **配置字段 / `@Value`**：写清来自哪个配置项、默认值、单位。

```java
/** Access Token 有效期（毫秒）— 来自 application.yml，避免在代码中硬编码 */
@Value("${app.jwt.access-token-expiration}")
private long accessTokenExpirationMs;
```

- **「为什么不能这样做」**：禁令 + 原因是学习项目的高价值注释，必留。

```java
// JWT 认证过滤器 — 不能声明为 @Bean，否则 Spring Boot 会自动注册到全局过滤器链
private final JwtAuthenticationFilter jwtAuthenticationFilter;
```

## 1.5 行间步骤注释

- **写法**：`// === 步骤1️⃣：从 HTTP 请求头获取 Authorization ===`，每步先说干什么，再补「为什么 / 框架在做什么」。
- **编号**：键帽数字 `1️⃣ 2️⃣ 3️⃣ …`，**连续不跳号**；删除步骤后必须重排。
- **步数**：学习项目**允许超过 7 步**（演示完整性优先于方法短小），但超过 7 步时必须在类注释或方法注释里补一句「⚠️ 演示完整性优先，生产应拆分为 X / Y 两步」。
- **每个分支都要有注释**：`if` / `catch` 里至少一句「为什么走这个分支」「跳过后由谁兜底」。
- **关键行标记**（注释内，克制使用）：

| 标记 | 含义 |
| --- | --- |
| `★` | 整个机制的关键点 / 最容易漏的一步 |
| `⚠️` | 坑、易错、并发陷阱、不可删的权衡 |
| `✅ / ❌` | 正确写法 / 常见错误写法（成对出现） |

**合格范例**：

```java
// === 步骤4️⃣：一次性解析 JWT（验签 + 过期 + 格式，全在 parseToken 内完成）===
// 此前 extractUsername → isTokenValid → extractAuthorities 会重复解析 4 次，
// 每次都要 Base64 解码 + HMAC 验签；改为解析一次后复用 Claims
Claims claims;
try {
    claims = jwtUtil.parseToken(jwt);
} catch (Exception e) {
    log.warn("JWT 解析失败: {}", e.getMessage());
    filterChain.doFilter(request, response); // 认证失败不阻断，让后续过滤器统一处理
    return;
}
```

## 1.6 知识卡片（学习项目特有）

遇到「框架机制 / API 版本差异 / 反直觉行为」时，**就地**插一段知识卡片，用固定前缀，方便全文搜索：

```java
// 【知识点】3 参数构造 = 已认证，2 参数构造 = 未认证；credentials 传 null 是为了不保留密码
// 【版本差异】Spring Security 6.x 用 authorizeHttpRequests，antMatchers 已废弃
// 【易错】JWT Payload 只是 Base64 编码（非加密），任何人都能解码，别放敏感信息
// 【对比】Session 方案由容器维护 JSESSIONID；JWT 方案服务端不存状态，靠签名自证
```

要求：

- 一张卡片只讲一个点，**2~4 行**，不攒成小作文。
- 只在「对目标读者非显然」处插；已知常识不要反复写。
- 卡片讲的是**可迁移的知识**（换个项目也成立），不是本类实现细节——后者放普通注释。

## 1.7 踩坑 / 演进记录

学习项目允许（且鼓励）保留「这里曾经写错过」：

```java
// 此前 extractUsername → isTokenValid → extractAuthorities 会重复解析 4 次，
// 每次都要 Base64 解码 + HMAC 验签；改为解析一次后复用 Claims
```

写法三段式：**旧写法是什么 → 为什么不行 → 现在怎么解决**。只写「优化了一下」「修复 bug」一律打回。

## 1.8 待验证与实验标记

- `// LEARN-TODO(具体疑问)`——还没搞懂 / 待验证的点，写清疑问本身，不写「待研究」。
- `// 实验：把 X 改成 Y，会看到 Z 现象`——鼓励留可动手的实验提示（学习项目的独特价值）。
- 学习项目**不写**生产式的 `// FIXME 临时方案`；要保留注释代码，必须写清「为什么留 + 什么时候删」。

## 1.9 注释密度表（学习项目版）

| 类类型 | 类注释 | 方法注释 | 行间注释 |
| --- | --- | --- | --- |
| config / 安全配置 | 六要素全写 | 非常详细 + 调用时机 + 配置含义 | 每一步、每个注解 |
| filter / interceptor / 回调 | 六要素全写（含链路图） | 谁调用 + 何时调用 + 副作用 | 每步、每个分支 |
| service | 六要素全写 | 边界、失败行为、事务 | 每步 + 为什么 |
| controller | 六要素全写（含请求 / 响应样例） | 详细：入参样例、返回样例、失败码 | 每步 + 教学提示 |
| util / 工具类 | 六要素全写（含原理示意） | 每个方法讲清原理与边界 | 关键 API 逐行 |
| entity / dto | 注解含义 + 字段用途 | — | **每个字段一行** |
| 枚举 / 常量 | 每个值写业务含义 + 何时出现 | — | — |
| mapper / SQL | 查询语义 + SQL 为什么这样组织 | 逐段 SQL 注释 | — |

> 一句话：**学习项目没有「该薄就薄」这一条，entity 字段也要注释**——但每条注释必须有信息量，凑字数照样打回。

## 1.10 注释与配套文档的分工

- 代码注释讲**「这段代码为什么这样写」**（实现侧）；配套 `docs/*.md` 讲**「这套机制是什么」**（概念侧：原理、流程图、多方案对比）。
- 双向指路：类注释里写「机制详解见 `docs/xxx.md`」；文档引用具体类时写全限定名或类名。
- **禁止**同一段原理在注释和文档里各写一遍——注释写实现，文档写概念。

## 1.11 富文本速查

| 场景 | 推荐写法 |
| --- | --- |
| 行内代码 / 字面量 | `{@code ...}` |
| 引用类、方法 | `{@link Type}` / `{@link Type#method}` |
| 分支 / 多口径 | `<ul>` / `<ol>` 逐条 |
| 键值 / 术语 | `<dl><dt><dd>` |
| 流程图 / 样例 | `<pre>{@code ...}</pre>` |
| 步骤编号 | emoji 键帽 `1️⃣ 2️⃣ 3️⃣` |
| 关键点 / 坑 | `★` / `⚠️` |
| 知识点卡片 | `// 【知识点】` `// 【易错】` `// 【版本差异】` `// 【对比】` |

## 1.12 注释核对清单

- [ ] 类注释覆盖六要素（职责 / 链路位置 / 生命周期 / 设计选择 / 边界或对比 / 配套文档）
- [ ] 重写与回调方法写清「谁调用、何时调用、返回值给谁用」
- [ ] 每个注入依赖、每个非显然注解都有注释
- [ ] 方法体有编号步骤注释（键帽），编号连续；>7 步已标注「生产应拆分」
- [ ] 每个 `if` / `catch` 分支写清「为什么走这里、跳过后谁兜底」
- [ ] 有【知识点】/【版本差异】/【易错】/【对比】卡片（至少一个，不刷屏）
- [ ] 踩坑记录写清「旧写法 → 为什么不行 → 现在怎么解决」
- [ ] 无逐行复述代码的废话；无与代码矛盾的注释
- [ ] entity / dto 字段与枚举值全部有注释

**打回语**

- 「这是把方法名翻译了一遍，重写：讲清框架什么时候调用它、返回值被谁消费。」
- 「类注释缺链路位置，画出『谁 → 我 → 谁』。」
- 「这个重写方法没写谁调用它，学习项目里这是必写项。」
- 「这个注解对初学者不是常识，补一句它触发了什么。」
- 「注释只说了做什么，没说为什么这样设计 / 代价是什么。」
- 「步骤编号跳号了（1️⃣2️⃣3️⃣5️⃣），删步骤后要重排。」
- 「超过 7 步没标『生产应拆分』，补上。」
- 「踩坑记录只写了『优化了一下』，补：旧写法 → 为什么不行 → 现在怎么解决。」
- 「entity 字段裸奔，学习项目里每个字段都要注释。」
- 「这段原理在 docs 里已经讲过，注释只留实现侧的差异，不要复制一遍。」

***

# 第二章 日志（Logging）

## 2.1 日志的定位：运行时教具

学习项目的日志不是给值班人看的，是给**正在跑这个项目的人**看的：把注释里的流程在控制台真实演一遍。判断标准是——

> **把代码注释合上，只看启动后的控制台输出，能不能还原出这套机制的执行顺序与分支走向？**

## 2.2 三条硬底线

| # | 底线 | 说明 |
| --- | --- | --- |
| 1 | **流程可见** | 每个关键步骤、每个分支出口都要有日志。生产规范里被禁止的「进出日志 / 分支日志」，这里是必做项。 |
| 2 | **与注释对齐** | 日志文案与行间步骤注释一一对应（同一件事、同一套说法）；长流程带上与注释相同的步骤号。 |
| 3 | **仍然不泄密** | 密码、完整 Token、Authorization 头、密钥原文不落日志；要观察就打脱敏片段（如 `token=eyJhbGci…（仅前 8 位）`）并注明。 |

## 2.3 级别与场景（学习项目版）

| 级别 | 什么时候用 | 说明 |
| --- | --- | --- |
| `INFO` | 流程节点：收到请求、解析完成、认证恢复、签发成功 | 默认级别，跑起来就该看到完整链路 |
| `DEBUG` | 数据细节：完整 claims、权限列表、构造参数 | 想看细节时开 `logging.level.<包>=DEBUG`，并在 README 写出这行配置 |
| `WARN` | 可恢复的分支：Token 过期 / 解析失败 / 查库失败 | 走的是「跳过」分支，不是系统故障 |
| `ERROR` | 真正的意外：配置缺失、依赖不可用 | 学习项目里很少出现 |

## 2.4 鼓励 vs 禁止

**鼓励**

- 入口 / 出口日志（`收到登录请求: {}` / `登录成功，JWT 已签发: {}`）
- 分支日志（走了 `if` 的哪一支、跳过的原因）
- 中间值（用户名、权限列表、有效期、解析出的 claims 摘要）
- 与注释同号的步骤日志

**禁止**

- 打印密码、完整 JWT、Authorization 头、密钥原文
- 循环体内逐条打印（跑一次几万行，看不过来）
- 只打 `log.error("error", e)` 而没有任何上下文
- 「打了日志就算处理完」——日志后 `return` 必须注释说明跳过后由谁兜底

## 2.5 文案格式

`动作 + 结果/原因 + 关键值`，中文，与注释用词一致：

```java
log.info("收到登录请求: {}", loginRequest.getUsername());
log.warn("登录失败（密码错误）: {}", loginRequest.getUsername());
log.info("JWT 认证恢复成功: 用户={}, 权限={}", username, authorities);
```

**长流程（≥5 步）带步骤号**，与注释编号严格一致：

```java
// === 步骤4️⃣：一次性解析 JWT（验签 + 过期 + 格式，全在 parseToken 内完成）===
claims = jwtUtil.parseToken(jwt);
log.debug("4️⃣ JWT 解析通过: subject={}, exp={}", claims.getSubject(), claims.getExpiration());
```

需要观察敏感内容时打脱敏片段：

```java
log.debug("收到 JWT: {}…（仅前 8 位，完整 token 不落日志）", jwt.substring(0, 8));
```

## 2.6 日志核对清单

- [ ] 跑一次完整流程，控制台能还原执行顺序与分支走向
- [ ] 日志文案与行间注释的说法、步骤号一致
- [ ] 每个 `catch` / 跳过分支有日志，并说明兜底方
- [ ] 无密码 / 完整 Token / 密钥；需要观察的已脱敏并注明
- [ ] 无循环内刷屏日志

**打回语**

- 「这个分支跳过了但没日志，跑起来看不出走了哪条路。」
- 「日志步骤号是 3️⃣，注释里是 5️⃣，对齐一下。」
- 「整条 Token 打进日志了，改成前 8 位 + 脱敏说明。」
- 「catch 里只打了日志，没写清跳过后由谁兜底（过滤器链？全局异常处理？）。」
- 「日志写的是『处理请求』，注释写的是『恢复认证』，两边说法统一一下。」

***

# 第三章 完整范例

## 3.1 合格样例骨架（filter 类，可直接当模板）

```java
/**
 * JWT 认证过滤器 — 从 Authorization 头提取 JWT，验证并恢复认证状态。
 *
 * <p>1️⃣ 职责：只负责"识别已登录用户"，不负责"拒绝未登录用户"。</p>
 * <p>2️⃣ 链路位置：请求 → 【本类】→ UsernamePasswordAuthenticationFilter → FilterSecurityInterceptor → Controller</p>
 * <p>3️⃣ 调用者：Tomcat 每次 HTTP 请求调用一次（继承 OncePerRequestFilter 保证不重复执行）。</p>
 * <p>4️⃣ 设计选择：无状态，不查 Session；步骤4️⃣一次性解析 JWT 后复用 Claims，避免 4 次重复验签。</p>
 * <p>5️⃣ 边界：不做授权判断，授权由 SecurityConfig 的 authorizeHttpRequests 规则负责。</p>
 * <p>6️⃣ 配套文档：docs/auth-principles/JWT认证原理.md</p>
 */
@Slf4j
@Component                      // 注册为 Spring Bean（但不是 @Bean 声明的 Filter）
@RequiredArgsConstructor        // 构造注入 JwtUtil + UserDetailsService
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    /** 4️⃣ 一次性解析 JWT —— 验签 + 过期 + 格式全在 parseToken 内完成 */
    @Override
    protected void doFilterInternal(...) throws ServletException, IOException {
        // === 步骤1️⃣：取 Authorization 头 ===
        // 格式示例：Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
        String authHeader = request.getHeader("Authorization");

        // === 步骤2️⃣：没有 Authorization 头或不是 Bearer 格式 → 静默跳过 ===
        // 后续 FilterSecurityInterceptor 会因为没有认证而返回 401
        if (!StringUtils.hasText(authHeader) || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        ...
    }
}
```

> 完整实现见 auth-lab `jwt-auth` 模块的 `JwtAuthenticationFilter`（12 步流程）、`SecurityConfig`（六段式配置注释）、`JwtUtil`（原理示意 + 逐行 API 注释）。这三篇是本规范的参考实现。

## 3.2 生产写法 → 学习写法（对照）

**生产式（在学习项目里不合格）**

```java
/**
 * 用户登录；凭证错误抛 BadCredentialsException。
 */
@PostMapping("/auth/login")
public ResponseEntity<TokenResponse> login(@RequestBody LoginRequest req) {
    ...
}
```

**学习式（合格）**

```java
/**
 * 用户登录 — 验证用户名密码，签发 JWT。
 *
 * <p>调用者：前端登录表单（POST /api/jwt/auth/login），本接口在 SecurityConfig 中 permitAll()。</p>
 *
 * <p>请求体：
 * <pre>{@code
 * { "username": "admin", "password": "123456" }
 * }</pre>
 *
 * <p>认证流程：
 * <pre>
 * 1️⃣ 创建未认证的 UsernamePasswordAuthenticationToken（2 参数构造）
 * 2️⃣ authenticationManager.authenticate() → DaoAuthenticationProvider
 *    → UserDetailsService.loadUserByUsername() → 查 DB
 *    → BCryptPasswordEncoder.matches() → 比密码
 *    → 成功返回已认证 Authentication / 失败抛 BadCredentialsException
 * 3️⃣ JwtUtil.generateAccessToken() → 生成 JWT
 * 4️⃣ 返回 TokenResponse（token + tokenType + expiresIn）
 * </pre>
 *
 * @param loginRequest 用户名密码；为空抛 400，密码错误抛 401
 * @return 200 + TokenResponse；不含 Refresh Token（本模块单 Token 方案）
 * @throws ResponseStatusException 参数为空（400）或凭证错误（401，由 ExceptionTranslationFilter 转换）
 */
@PostMapping("/auth/login")
public ResponseEntity<TokenResponse> login(@RequestBody LoginRequest loginRequest) {
```

***

# 附录 A 复制即用模板

## A.1 类注释模板

```java
/**
 * <一句话职责>。
 *
 * <p>1️⃣ 职责边界：<做什么 / 不做什么，不做的由谁负责></p>
 * <p>2️⃣ 链路位置：<上游> → 【本类】→ <下游></p>
 * <p>3️⃣ 调用者：<谁创建 / 谁调用 / 何时调用 —— 每次请求？启动一次？事件触发？></p>
 * <p>4️⃣ 设计选择：<为什么这样设计，代价或前提是什么></p>
 * <p>5️⃣ 边界 / 对比：<与同类实现的差异></p>
 * <p>6️⃣ 配套文档：docs/<路径>.md</p>
 *
 * <p>执行流程：
 * <pre>
 * 1️⃣ … → 2️⃣ … → 3️⃣ …
 * </pre>
 */
```

## A.2 方法注释模板（重写 / 回调专用）

```java
/**
 * <一句话目的>。
 *
 * <p>调用者：<谁调用 / 什么时候调用 / 触发条件></p>
 * <p>返回值去向：<框架拿去做什么 / 上游怎么用></p>
 * <p>失败行为：<抛什么 / 静默跳过 / 降级，跳过后由谁兜底></p>
 *
 * @param x <来源 + 格式 + 取值范围>
 * @return <语义 + 是否可能 null>
 * @throws XxxException <什么条件下抛 → 被谁处理 → 最终响应>
 */
```

## A.3 行间步骤注释模板

```java
// === 步骤1️⃣：<干什么> ===
// <为什么这样做 / 框架在这一步做了什么>
// 【知识点】<可迁移的知识点>
// ⚠️ <坑 / 易错 / 权衡>
```
