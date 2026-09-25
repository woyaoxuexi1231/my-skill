# 打包与两种生产模式

脚本和 skill **同级**。以后换地方：整夹带走（脚本 + 各 skill 文件夹），在该目录执行打包。

```text
任意目录/
  pack-frontend-skills.ps1
  INSTALL.md
  prod-frontend/
  prod-frontend-full/
  frontend-creative-director/
  ...
```

## 日常使用

| 模式 | 口令 | 对应包 |
| ---- | ---- | ------ |
| 精选 | `启用 prod-frontend` | `-Set curated` |
| 全量 | `启用 prod-frontend-full` | `-Set all` |

都是：给需求 + 素材 → **一路做完**，不逐步确认。

```text
启用 prod-frontend。
需求：……
素材路径：……
直接做完。
```

## 打包

在**本目录**（和 skill 同级）执行：

```powershell
.\pack-frontend-skills.ps1 -Set curated -Zip
.\pack-frontend-skills.ps1 -Set all -Zip
```

产物：`./dist/curated-日期.zip` 或 `./dist/all-日期.zip`

### 装到别的项目

解压后，把里面的 **skill 文件夹**拷进目标 `.cursor/skills/`。  
脚本也可一并放进该目录，方便下次再打包。

- **curated**：约 10 个（prod-frontend + CD + critique + impeccable + taste + ui-ux-pro-max + 动画组）
- **all**：本目录下除 `dist` 外的全部 skill 文件夹

激活口令不会自动下载依赖；拷了什么，那边才有什么。
