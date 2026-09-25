# skill

给 Agent 用的 skill 和提示词。装到别的项目时，把对应文件夹拷进 `.cursor/skills/`。

## 工程提示词

| 文件 | 用途 |
|---|---|
| [Java Production Development Engineer](./Java%20Production%20Development%20Engineer.md) | Java 生产开发 |
| [Java Production Code Optimization Engineer](./Java%20Production%20Code%20Optimization%20Engineer.md) | Java 优化 |
| [Java Code Documentation Engineer](./Java%20Code%20Documentation%20Engineer.md) | Java 文档 |
| [Python Production Development Engineer](./Python%20Production%20Development%20Engineer.md) | Python 生产开发 |
| [Python Code Documentation Engineer](./Python%20Code%20Documentation%20Engineer.md) | Python 文档 |
| [Frontend Production Development Engineer](./Frontend%20Production%20Development%20Engineer.md) | 前端生产开发 |
| [Frontend Code Documentation Engineer](./Frontend%20Code%20Documentation%20Engineer.md) | 前端文档 |
| [生成Java知识点提示词](./生成Java知识点提示词.md) | 生成 Java 知识点 |
| [旅游攻略生成提示词v2](./旅游攻略生成提示词v2.md) | 旅游攻略 |

## 前端 skill 包

目录：[前端skill](./前端skill/)。打包与安装见 [INSTALL.md](./前端skill/INSTALL.md)。

日常口令：

- 精选：`启用 prod-frontend`
- 全量：`启用 prod-frontend-full`

```powershell
cd docs/skill/前端skill
.\pack-frontend-skills.ps1 -Set curated -Zip
.\pack-frontend-skills.ps1 -Set all -Zip
```
