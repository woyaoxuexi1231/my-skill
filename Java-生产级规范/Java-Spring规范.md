# Java Spring / Spring Boot 规范

> 范围：Spring / Spring Boot 日常开发的**框架用法**（注入、代理、事务、Web、Bean 装配习惯）。  
> 包放哪见 `Java-代码架构.md`；业务层怎么写见 `Java-模块代码规范.md`；yml/profile 细节见 `Java-配置与工程规范.md`。

---

## 1. 依赖注入

### 必须

- **优先构造器注入**（或 `@RequiredArgsConstructor` + `final` 字段），依赖在创建时可见、可测。
- 注入接口或具体类按项目习惯，但依赖方向仍遵守架构（不反向、不成环）。

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

## 2. 代理与注解生效范围

下列注解依赖 Spring **代理**，同类内部自调用**默认不生效**：

- `@Transactional`
- `@Async`
- `@Cacheable` / `@CacheEvict` 等

### 必须

- 需要事务/异步/缓存的入口，从**外部 Bean 调用**，或拆到另一个 Bean。
- 写清事务边界：同一业务原子写操作放同一事务；长耗时外部 IO 默认不进事务（详见外部调用规范）。

### 禁止

- 假定 `this.xxx()` 会走代理。
- `@Transactional` 甩在 Controller 上当常规（事务边界优先在 Service）。
- 无界 `@Async` + 默认执行器打生产阻塞 IO。

---

## 3. Web 层（Spring MVC）

- 使用 `@RestController` / `@RequestMapping`（或细分动词映射）；入参校验用 `@Valid` + 统一异常处理。
- 统一响应、分页、错误码形态见模块规范 **Controller / API 契约**。
- 全局异常处理固定一处（`@RestControllerAdvice` 等），不要每个 Controller 私有一套。

禁止：在 Filter/Interceptor 里写完整业务用例（安全基础设施除外，且仍不塞域逻辑）。

---

## 4. Bean 与配置类

- `@Configuration` 一类关注点一个类；`@Bean` 方法职责清晰。
- 条件装配（`@ConditionalOn*`）用于环境/依赖差异，不要用条件注解堆业务分支。
- 不要用 `@Component` 扫描把无边界的工具类糊进容器当「全局上帝」。

更细的 yml、profile、密钥：见 `Java-配置与工程规范.md`。

---

## 5. 缓存抽象与异步（若启用）

- `@Cacheable`：必须能说清缓存名、key、过期/失效；与 Redis 规范一致。
- `@Async`：必须使用**有界**、命名清晰的线程池；禁止默认无界执行器扛生产流量；禁止用 `Executors` 工厂隐藏无界风险（与模块规范一致）。
- 未有需求时不要先加 spring-boot-starter-cache / 异步「备用」。

---

## 6. 常见反模式

| 反模式 | 正确做法 |
|--------|----------|
| 字段注入 + 大段静态工具依赖 | 构造器注入；可测组件 |
| Service 里自调用开事务 | 拆 Bean 或调整调用链 |
| Controller 开事务 + 调外部 HTTP | 事务下沉 Service；HTTP 事务外 |
| 随便 `CompletableFuture.supplyAsync` 无池 | 明确执行器与拒绝策略 |
| 为「企业范」先上 Cloud / MQ / Gateway | 单体用满再谈；与架构原则一致 |

---

## 7. 核对清单

- [ ] 构造器注入；依赖可见  
- [ ] 事务/异步/缓存无「自调用失效」坑  
- [ ] 全局异常处理统一  
- [ ] 未启用无界异步/无策略缓存  
- [ ] 配置类无业务用例  
