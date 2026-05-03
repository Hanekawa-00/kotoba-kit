# Kotoba Kit（言葉キット）

[![CI](https://github.com/Hanekawa-00/kotoba-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/Hanekawa-00/kotoba-kit/actions/workflows/ci.yml)

> [English](README.md)

一款离线优先的日语字典与学习工具集。基于 Flutter 构建，覆盖所有主流平台，以可靠的本地词典查词为核心。

## 功能特性

### 已实现

- **本地 MDict 查词** — 导入 `.mdx`/`.mdd` 词典文件；支持精确匹配与前缀建议，完全离线。
- **在线词典源** — Weblio、Jisho 在线查词，与本地结果并列展示，可按源独立开关。
- **WebView 渲染** — 词典条目以浏览器 HTML 渲染，包含作用域 CSS、词条交叉链接、嵌入式音频/图片支持，遵循 LunaTranslator 渲染模式。
- **多源聚合结果** — 并行搜索本地与在线词典，结果按来源分组，通过快速切换芯片浏览。
- **词典管理** — 在设置页面中导入、启用/禁用、删除词典。
- **Material 3 主题** — 浅色/深色/跟随系统、主题色预设、OLED 纯黑模式、紧凑密度。
- **跨平台** — Windows（自定义标题栏）、Linux、macOS、Android、iOS、Web。响应式布局在移动端底部导航与桌面端侧边栏间自适应切换。

### 计划中

| 功能 | 说明 |
|---|---|
| 日语分词引擎 | 基于 MeCab 的形态素分析，实现按词边界查词 |
| 造句练习 | AI 辅助翻译造句、选择题、自由造句三种模式 |
| 语法库 | 离线 JLPT N5–N1 语法参考，含用法与例句 |
| TTS 发音 | 三级降级语音合成（Gemini → Cloud → 本地兜底） |
| 拍照识词 | 摄像头拍摄物体/文字，边界框标注 + 点击查词 |
| 练习历史 | 本地持久化历史记录，支持筛选与导入导出 |

详见 `docs/japanese-learning-app-design.md` 获取完整架构与实施路线图。

## 平台支持

| 平台 | 状态 |
|---|---|
| Windows | 已支持（自定义窗口边框） |
| Linux | 已支持（自定义窗口边框） |
| macOS | 已生成项目 |
| Android | 已支持 |
| iOS | 已生成项目 |
| Web | 字典页面可用（本地 MDX 存根，在线源可用） |

## 快速开始

```bash
flutter pub get
flutter run -t lib/main_development.dart
```

按环境入口运行：

```bash
flutter run -t lib/main_development.dart   # 开发
flutter run -t lib/main_staging.dart       # 预发布
flutter run -t lib/main_production.dart    # 生产
```

或通过 `--dart-define` 指定：

```bash
flutter run --dart-define=APP_ENV=staging
flutter run --dart-define=APP_ENV=production --dart-define=APP_NAME=KotobaKit
```

## 常用命令

```bash
# 格式化、分析、测试
dart format lib test scripts
flutter analyze
flutter test

# 本地完整检查
pwsh ./scripts/check.ps1

# 重新生成国际化代码
flutter gen-l10n

# 生成新功能模块
dart run scripts/new_feature.dart <feature_name>

# 发布构建
flutter build windows --release -t lib/main_production.dart
flutter build apk --release --split-per-abi -t lib/main_production.dart
flutter build web --release -t lib/main_production.dart
```

## 项目结构

```
lib/
  main*.dart                  # 各环境入口文件
  l10n/                       # ARB 国际化文件（英文、中文）
  src/
    app/                      # 应用启动与 MaterialApp 引导
    core/                     # 配置、错误处理、日志、路由、主题、
                              #   设置、网络 (Dio)、存储 (Hive CE)、
                              #   缓存、平台服务、窗口管理
    data/
      models/                 # DictionaryConfig、DictionaryEntry、
                              #   OnlineDictionaryConfig
      repositories/           # DictionaryRepository + 本地/在线持久化
      services/
        dictionary_service_*.dart   # MDX/MDD 文件解析（IO + 存根）
        online_sources/             # WeblioSource、JishoSource + LRU 缓存
    features/
      dictionary/             # 查词页面 + 状态管理
      home/                   # 首页仪表盘
      settings/               # 偏好设置 + 词典管理
      about/                  # 关于页面
      components/             # 模板组件展示（已禁用）
    shared/                   # 可复用组件（PageFrame、SectionCard、
                              #   AppShell、AppStateViews、ConfirmActionDialog）
```

## 架构概览

- **状态管理**: Riverpod 3.x — `AsyncNotifier` 管理词典状态，Provider 注入基础设施。
- **路由导航**: `go_router` + `StatefulShellRoute.indexedStack` — 切换标签页时保留滚动位置与组件状态。
- **词典管线**: `DictionaryPage` → `DictionaryController` → `DictionaryRepository` → `DictionaryService`（本地 MDX）+ `OnlineDictionarySource`（Weblio/Jisho）— 并行搜索，合并结果 → `InAppWebView` 渲染。
- **响应式**: 760px 断点 — 以下移动端底部导航，以上桌面端侧边栏。
- **主题系统**: Material 3 `ColorScheme.fromSeed` + 自定义 `ThemeExtension` 设计令牌（间距、圆角、动效）。

## 设计文档

- `docs/japanese-learning-app-design.md` — 完整产品架构与实施路线图
- `docs/kotoba_kit_design_architecture.md` — 词典专项设计（MDX/MDD 导入、查词管线、WebView 渲染）
- `docs/architecture.md` — 模板级架构（路由、状态、数据层）
- `docs/design_system.md` — 设计令牌与响应式规则
- `AGENTS.md` — AI Agent 与开发者协作规范

## 许可证

MIT — 详见 [LICENSE](LICENSE)。
