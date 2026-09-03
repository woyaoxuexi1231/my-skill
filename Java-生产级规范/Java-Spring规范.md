# Java Spring / Spring Boot 规范

> 范围：Spring / Spring Boot 日常开发的**框架用法**——依赖注入、代理机制、声明式事务、Web 层、Bean 装配。  
> 本篇只讲框架怎么用；各层业务代码怎么写、包怎么分、配置怎么放，均不在此篇。

---

## 1. 依赖注入

### 必须

- **优先构造器注入**（或 `@RequiredArgsConstructor` + `final` 字段），依赖在创建时可见、可测。
- 注入接口或具体类按项目习惯，但依赖方向保持单向（不反向、不成环）。

### 禁止

- 无必要的 `@Autowired` 字段注入（难测、隐藏依赖）。
- 在业务方法里 `ApplicationContext.getBean` 当常规手段（除非框架扩展点明确需要）。
- 循环依赖靠 `@Lazy` 硬扛却不回头理清模块边界。

```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderMapper orderMapper;
}
```

---

## 2. 代理机制

下列注解依赖 Spring **代理**生效，同类内部自调用**默认不生效**：

- `@Transactional`
- `@Async`
- `@Cacheable` / `@CacheEvict` 等

### 必须

- 需要事务/异步/缓存的入口，从**外部 Bean 调用**，或拆到另一个 Bean。
- 被代理方法必须是 `public`；同类中 `this.xxx()` 不走代理。

### 代理失效的典型场景

| 场景 | 原因 | 处理 |
|------|------|------|
| `this.method()` 自调用 | 绕过了代理对象 | 拆到另一个 Bean，或从外部 Bean 调用 |
| 方法为 `private` / `final` | 无法被代理生成子类或拦截 | 改为 `public` 非 `final` |
| 类未被 Spring 管理 | 没有生成代理（如 `new` 出来的对象） | 交由容器管理 |
| 异常在方法内被 `catch` 吞掉 | 代理收不到异常信号 | 向上抛或标记回滚 |

### 禁止

- 假定 `this.xxx()` 会走代理。
- 无界 `@Async` + 默认执行器承担生产阻塞 IO。

---

## 3. 声明式事务

### 3.1 标注位置

- 事务边界标注在 **Service 方法**上，不甩在 Controller 上当常规做法。
- 一个事务方法对应一个完整的业务写操作：需要同成同败的写，放同一个事务。

### 3.2 必须显式声明的属性

| 属性 | 要求 |
|------|------|
| `rollbackFor` | 默认只回滚 `RuntimeException`；**抛出受检异常时必须写 `rollbackFor`**，否则不回滚 |
| `propagation` | 有嵌套调用需求时显式声明，不依赖默认值猜测 |
| `readOnly` | 纯查询方法标注 `readOnly = true`，交由框架优化 |
| `timeout` | 耗时不可控的事务显式设置超时，避免长期占用连接 |

```java
@Transactional(rollbackFor = Exception.class)
public void createOrder(CreateOrderRequest request) { ... }

@Transactional(readOnly = true)
public OrderDetailVO getOrderDetail(Long orderId) { ... }
```

### 3.3 事务边界

- 事务内只放需要保证原子性的数据库写操作。
- **事务方法内不做耗时不可控的阻塞等待**（远程调用、大批量处理、等待用户输入等）——事务持有的数据库连接在方法返回前不会释放，事务越长，连接占用越久。
- 先做参数校验与前置判断，再进入事务，缩短事务持有时间。

### 3.4 回滚与失效

- 异常被 `catch` 后不再抛出 → 事务**不会**回滚；要么继续抛出，要么显式 `TransactionAspectSupport.currentTransactionStatus().setRollbackOnly()`。
- 自调用、非 `public` 方法、异常被吞，是事务"看起来没生效"的三大原因（见 §2）。

### 3.5 禁止

- 假定 `this.xxx()` 会开启事务。
- 用 `@Transactional` 包裹循环内的单次写操作（应缩小粒度或批量处理）。
- 在事务方法内启动新线程处理同一事务的数据（线程间不共享事务上下文）。

---

## 4. Web 层（Spring MVC）

- 使用 `@RestController` / `@RequestMapping`（或细分动词映射）；入参校验用 `@Valid`。
- 接口返回**明确类型**（VO / DTO），不用 `Map` 裸返回。
- 全局异常处理固定一处（`@RestControllerAdvice`），不要每个 Controller 私有一套。
- 响应统一包装（响应体包装或统一的 `Result` 返回类型），全项目形态一致。

禁止：在 Filter / Interceptor 里写完整业务用例（安全基础设施除外，且仍不塞业务规则）。

---

## 5. Bean 与配置类

- `@Configuration` 一类关注点一个类；`@Bean` 方法职责清晰。
- 条件装配（`@ConditionalOn*`）用于环境/依赖差异，不要用条件注解堆业务分支。
- 不要用 `@Component` 扫描把无边界的工具类糊进容器当「全局上帝」。

---

## 6. 缓存抽象与异步（若启用）

- `@Cacheable`：必须能说清缓存名、key、过期/失效策略。
- `@Async`：必须使用**有界**、命名清晰的线程池；禁止默认无界执行器扛生产流量。
- 未有需求时不要先加 `spring-boot-starter-cache` / 异步「备用」。

---

## 7. 常见反模式

| 反模式 | 正确做法 |
|--------|----------|
| 字段注入 + 大段静态工具依赖 | 构造器注入；可测组件 |
| Service 里自调用开事务 | 拆 Bean 或调整调用链 |
| Controller 上开事务 | 事务下沉到 Service |
| 事务里做耗时不可控的阻塞操作 | 移出事务，缩短连接占用 |
| `catch` 掉异常还指望回滚 | 继续抛出或显式标记回滚 |
| 随便 `CompletableFuture.supplyAsync` 无池 | 明确执行器与拒绝策略 |
| 为「企业范」先上 Cloud / MQ / Gateway | 当前用不到就不引入 |

---

## 8. 核对清单

- [ ] 构造器注入；依赖可见  
- [ ] 事务/异步/缓存无「自调用失效」坑  
- [ ] `@Transactional` 在 Service 层；`rollbackFor` / `readOnly` / `timeout` 按需显式声明  
- [ ] 事务内无耗时不可控的阻塞操作；异常未被吞  
- [ ] 全局异常处理统一；接口返回明确类型  
- [ ] 未启用无界异步/无策略缓存  
- [ ] 配置类无业务用例  
