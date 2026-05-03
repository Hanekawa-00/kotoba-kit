# 日语学习跨平台应用 — 完整架构与详细设计文档

> **版本：** v2.0  
> **日期：** 2026-05-03  
> **基座仓库：** [Hanekawa-00/flutter-template](https://github.com/Hanekawa-00/flutter-template)  
> **参考仓库：**
> - 字典系统：[HIllya51/LunaTranslator](https://github.com/HIllya51/LunaTranslator)（⭐ 11.4k）
> - 造句练习：[Hanekawa-00/Japanese-Sentence-Pratice](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice)
> - 物体检测：[Hanekawa-00/sync](https://github.com/Hanekawa-00/sync)

---

## 目录

1. [项目概述](#1-项目概述)
2. [参考仓库分析](#2-参考仓库分析)
3. [技术选型总览](#3-技术选型总览)
4. [离线优先架构设计](#4-离线优先架构设计)
5. [功能模块详细设计](#5-功能模块详细设计)
   - [5.1 MDict 本地字典](#51-mdict-本地字典)
   - [5.2 日语分词引擎](#52-日语分词引擎)
   - [5.3 多模型 LLM 层](#53-多模型-llm-层)
   - [5.4 TTS 语音合成](#54-tts-语音合成)
   - [5.5 造句练习引擎](#55-造句练习引擎)
   - [5.6 语法库](#56-语法库)
   - [5.7 练习历史](#57-练习历史)
   - [5.8 拍照识词](#58-拍照识词)
6. [项目目录结构](#6-项目目录结构)
7. [数据流与状态管理](#7-数据流与状态管理)
8. [路由设计](#8-路由设计)
9. [实施路线图](#9-实施路线图)
10. [完整依赖清单](#10-完整依赖清单)
11. [附录](#11-附录)

---

## 1. 项目概述

### 1.1 项目定位

一款**离线优先**的日语学习跨平台应用。核心功能为**本地 MDict 字典查询**、**AI 辅助造句练习**、以及**拍照识词（多模态视觉词汇）**。

### 1.2 目标平台

| 平台 | 状态 | 来源 |
|---|---|---|
| Android | ✅ | flutter-template 已配置 |
| iOS | ✅ | flutter-template 已配置 |
| Web | ✅ | flutter-template 已配置 |
| Windows | ✅ | flutter-template 已配置（window_manager） |
| macOS | ✅ | flutter-template 已配置 |
| Linux | ✅ | flutter-template 已配置 |

### 1.3 核心设计原则

| 原则 | 说明 |
|---|---|
| 🔌 **离线优先** | 字典、分词、语法库、历史记录全部本地运行，不依赖网络 |
| 🌐 **在线按需** | 仅 LLM 造句反馈 + TTS 语音合成 + 多模态识别使用在线 API（本地兜底） |
| 🔀 **模型无关** | LLM 层基于 LangChain.dart 统一抽象，支持 OpenAI / Gemini / Claude / Ollama 随意切换 |
| 📦 **本地词库** | 基于 `dict_reader` 纯 Dart 解析 MDict (.mdx/.mdd)，用户自行导入词典文件 |
| 🧩 **模块化** | 字典、造句、语法库、拍照识词为独立 Feature，可单独使用或联动 |

---

## 2. 参考仓库分析

### 2.1 flutter-template — 基座框架

| 项目 | 详情 |
|---|---|
| **仓库** | <https://github.com/Hanekawa-00/flutter-template> |
| **语言** | Dart 3.11+ / Flutter 3.x |
| **状态管理** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) 3.3.1 |
| **路由** | [go_router](https://pub.dev/packages/go_router) 17.2.3 |
| **网络** | [dio](https://pub.dev/packages/dio) 5.9.2 |
| **存储** | [hive_ce](https://pub.dev/packages/hive_ce) 2.19.3 + [shared_preferences](https://pub.dev/packages/shared_preferences) 2.5.5 |
| **桌面** | [window_manager](https://pub.dev/packages/window_manager) 0.5.1 |
| **i18n** | flutter_localizations + ARB 文件 |
| **架构** | 分层特征架构：`app → core → data → features → shared` |

**已有基础设施（直接复用）：**
- ✅ MaterialApp.router + GoRouter 路由系统
- ✅ Riverpod 状态管理（ConsumerWidget / NotifierProvider）
- ✅ Dio 网络层（拦截器架构）
- ✅ Hive CE 本地 NoSQL 存储
- ✅ 环境配置（dev / staging / prod）
- ✅ 主题系统 + Design Tokens（Material 3）
- ✅ AppShell 响应式导航（侧边栏 / 底部栏自适应）
- ✅ 桌面窗口管理 + 命令面板
- ✅ State Views（loading / error / empty 组件）
- ✅ 反馈弹窗系统
- ✅ Feature 模板（home / settings / components / about）

**关键源码：**
- [bootstrap.dart](https://github.com/Hanekawa-00/flutter-template/blob/main/lib/src/app/bootstrap.dart) — 应用入口，MaterialApp.router + Riverpod
- [pubspec.yaml](https://github.com/Hanekawa-00/flutter-template/blob/main/pubspec.yaml) — 依赖清单

### 2.2 LunaTranslator — 字典系统参考

| 项目 | 详情 |
|---|---|
| **仓库** | <https://github.com/HIllya51/LunaTranslator> |
| **语言** | C++（核心） + Python（UI / 插件） |
| **许可** | GPL-3.0（⚠️ 仅参考架构，代码不可直接复用） |
| **星标** | 11.4k |

**字典架构（参考设计）：**

- **抽象基类** `cishubase`：定义 `search(word) → str` 统一接口，所有字典 Provider 继承此类
- **Provider 模式**：每种字典源一个独立 Provider
- **缓存层**：LRUCache（32 条目）
- **异步搜索**：@threader 装饰器确保 UI 不阻塞

```
                    ┌──────────────┐
                    │  cishubase   │  (抽象基类)
                    │  search()    │
                    └──────┬───────┘
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌─────▼──────┐ ┌──────▼──────┐
    │   MDict     │ │   Jisho    │ │   Weblio    │ ...
    │  (本地离线)  │ │  (在线API) │ │  (在线API)  │
    └─────────────┘ └────────────┘ └─────────────┘
```

**MDict 实现（参考设计）：**

| 组件 | 说明 |
|---|---|
| 解析库 | `mdict_/readmdict` — 解析 .mdx（文本）和 .mdd（资源） |
| 索引层 | SQLite `MDX_INDEX` 表 — 存储文件偏移而非加载全文 |
| 查询 | SQL 查询索引 → 文件偏移读取 → 解压返回 |
| 模糊匹配 | `NativeUtils.distance()` 编辑距离 |
| 加密支持 | 支持加密词典 + zlib/LZO 压缩 |

**关键源码：**
- [cishubase.py](https://github.com/HIllya51/LunaTranslator/blob/main/src/LunaTranslator/cishu/cishubase.py) — 字典抽象基类
- [mdict.py](https://github.com/HIllya51/LunaTranslator/blob/main/src/LunaTranslator/cishu/mdict.py) — MDict 实现（SQLite 索引 + 模糊搜索）
- [cishu/ 目录](https://github.com/HIllya51/LunaTranslator/tree/main/src/LunaTranslator/cishu) — 所有字典 Provider

**日语分词（参考设计）：**

使用 MeCab + UniDic 词典。LunaTranslator 中 MeCab 通过 Python 绑定调用，返回 `WordSegResult`（词条 + 读音）。

### 2.3 Japanese-Sentence-Pratice — 造句练习参考

| 项目 | 详情 |
|---|---|
| **仓库** | <https://github.com/Hanekawa-00/Japanese-Sentence-Pratice> |
| **语言** | TypeScript / React 19 / Vite 6 |
| **AI 引擎** | [@google/genai](https://www.npmjs.com/package/@google/genai) (Gemini 2.5 Flash) |

**练习模式：**

| 模式 | 说明 |
|---|---|
| 📝 翻译造句 | 给出中文 → 用户翻译成日语 → AI 评分（0-100）+ 修正 + 解释 |
| 🎯 选择题 | 给出中文 → 4 选 1 正确日语 → AI 生成干扰项 |
| ✅ 自由造句 | 用户输入日语 → AI 检查语法/自然度 |

**AI 交互设计（参考）：**

- **Prompt 分层**：`getLevelSpecificPrompt()` 按 JLPT N5-N1 生成不同难度/话题的提示词
- **流式评估**：SSE streaming → 结构化头部解析（score / evaluation / correctedSentence）→ 解释正文流式输出
- **语法库**：本地 `jlpt_grammar_full.json` 含语法点/用法/例句，LLM 从中随机抽取语法点定向出题
- **TTS**：`gemini-2.5-flash-preview-tts` 模型，`Leda` 音色
- **历史**：localStorage 持久化，支持导入/导出 JSON

**关键源码：**
- [types.ts](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/types.ts) — 数据类型定义（SentenceTask / Feedback / GrammarPoint 等）
- [geminiService.ts](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/geminiService.ts) — Gemini API 交互（Prompt 模板 + 流式评估 + TTS）
- [App.tsx](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/App.tsx) — 应用状态机
- [package.json](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/package.json) — 依赖清单

### 2.4 sync — 物体检测参考

| 项目 | 详情 |
|---|---|
| **仓库** | <https://github.com/Hanekawa-00/sync> |
| **语言** | TypeScript / React 19 / Vite 6 |
| **AI 引擎** | [@google/genai](https://www.npmjs.com/package/@google/genai) |
| **主模型** | `gemini-robotics-er-1.6-preview`（机器人空间理解专用模型） |
| **备选模型** | `gemini-flash-latest` |
| **状态管理** | [jotai](https://www.npmjs.com/package/jotai)（原子化状态） |

**核心能力：**

| 能力 | 说明 |
|---|---|
| 🔲 2D 边界框 | `box_2d: [ymin, xmin, ymax, xmax]` 归一化 0-1000 |
| 📍 点位标注 | `point: [y, x]` 归一化 0-1000 |
| ✏️ 自由绘制 | `perfect-freehand` 手绘区域标注，合并到图片发送 |
| 🔍 悬停揭示 | Hover 时显示/隐藏边界框标签 |
| 🔧 JSON 修复 | `jsonrepair` 自动修复模型返回的畸形 JSON |
| 📐 图片预处理 | 最大 640px 缩放后发送，减少 Token 消耗 |

**Prompt 设计（来源：Prompt.tsx）：**

```typescript
// 2D 边界框检测的 prompt
const getRoboticsPrompt = (type, target) => {
  return `Task: Detect ${target}.
Return a JSON array of objects.
Each object must have:
- "box_2d": [ymin, xmin, ymax, xmax] (coordinates 0-1000)
- "label": text label
Example: [{"box_2d": [100, 200, 300, 400], "label": "example"}]
Avoid points. Return ONLY the JSON.`;
};
```

**坐标转换（来源：Prompt.tsx `formattedBoxes`）：**

```typescript
// box_2d [ymin, xmin, ymax, xmax] (0-1000) → 归一化 0-1
{
  x: xmin / 1000,                     // 左边界
  y: ymin / 1000,                     // 上边界（注意 y 在前！）
  width: (xmax - xmin) / 1000,        // 宽度
  height: (ymax - ymin) / 1000,       // 高度
  label: box.label || "unknown",
}
```

**边界框渲染（来源：Content.tsx）：**

边界框用 CSS `position: absolute` 定位，百分比坐标渲染：

```tsx
<div style={{
  top: box.y * 100 + '%',     // ymin/1000 * 100
  left: box.x * 100 + '%',    // xmin/1000 * 100
  width: box.width * 100 + '%',
  height: box.height * 100 + '%',
}}>
  <div>{box.label}</div>
</div>
```

**关键源码：**
- [Prompt.tsx](https://github.com/Hanekawa-00/sync/blob/main/src/Prompt.tsx) — API 调用 + JSON 解析 + 坐标转换（核心逻辑）
- [Content.tsx](https://github.com/Hanekawa-00/sync/blob/main/src/Content.tsx) — 边界框渲染 + hover 交互 + 自由绘制
- [Types.ts](https://github.com/Hanekawa-00/sync/blob/main/src/Types.ts) — 数据类型（BoundingBox2DType / PointingType）
- [atoms.ts](https://github.com/Hanekawa-00/sync/blob/main/src/atoms.ts) — Jotai 状态原子
- [consts.ts](https://github.com/Hanekawa-00/sync/blob/main/src/consts.ts) — 默认 Prompt 模板
- [package.json](https://github.com/Hanekawa-00/sync/blob/main/package.json) — 依赖清单

---

## 3. 技术选型总览

### 3.1 网络依赖矩阵

| 功能模块 | 网络依赖 | 技术方案 |
|---|---|---|
| 📖 字典查询 | ❌ 完全离线 | [dict_reader](https://pub.dev/packages/dict_reader) (Dart 原生 MDict 解析) |
| ✂️ 日语分词 | ❌ 完全离线 | [mecab_for_dart](https://pub.dev/packages/mecab_for_dart) (MeCab FFI 绑定) |
| 📚 语法库 | ❌ 完全离线 | JSON Asset 本地打包 |
| 📝 练习历史 | ❌ 完全离线 | [hive_ce](https://pub.dev/packages/hive_ce) (本地 NoSQL) |
| ⚙️ 应用设置 | ❌ 完全离线 | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| 🤖 LLM 对话 | ✅ 在线 | [langchain](https://pub.dev/packages/langchain) 多 Provider 统一接口 |
| 🔊 TTS 发音 | ✅ 在线 + 本地兜底 | Gemini TTS → [cloud_text_to_speech](https://pub.dev/packages/cloud_text_to_speech) → [flutter_tts](https://pub.dev/packages/flutter_tts) |
| 📸 拍照识词 | ✅ 在线 | Gemini 2.5 Flash 多模态（框出文字+物体 → 点击查词） |

### 3.2 核心依赖一览

```yaml
# === 基础框架（来自 flutter-template）===
flutter_riverpod: ^3.3.1         # 状态管理
go_router: ^17.2.3              # 路由导航
dio: ^5.9.2                     # HTTP 客户端
hive_ce: ^2.19.3                # 本地 NoSQL 存储
hive_ce_flutter: ^2.3.4         # Hive Flutter 适配
shared_preferences: ^2.5.5      # KV 配置
window_manager: ^0.5.1          # 桌面窗口管理

# === 🆕 离线字典 ===
dict_reader: ^1.6.0             # MDict (.mdx/.mdd) 解析

# === 🆕 日语分词 ===
mecab_for_dart: ^0.2.0          # MeCab 日语形态素分析

# === 🆕 LLM 多模型 (LangChain.dart 生态) ===
langchain: ^0.8.1               # 核心抽象
langchain_openai: ^0.8.1+1      # OpenAI (GPT-4o/5, o3)
langchain_google: ^0.3.2        # Google (Gemini 2.5 Pro/Flash)
langchain_anthropic: ^0.3.1     # Anthropic (Claude 4.5 Sonnet)
langchain_ollama: ^0.4.1        # Ollama (本地模型，可选)

# === 🆕 TTS 语音（三级降级：Gemini → Cloud → 本地）===
google_generative_ai: ^0.4.0    # Gemini TTS（首选）
cloud_text_to_speech: ^1.1.0    # Google/Azure/Amazon TTS
flutter_tts: ^4.2.5             # 本地系统 TTS（离线兜底）
just_audio: ^0.9.40             # 跨平台音频播放

# === 🆕 拍照识词 ===
image_picker: ^1.1.0            # 相机 + 相册

# === 🆕 工具 ===
connectivity_plus: ^6.0.0       # 网络状态检测
path_provider: ^2.1.0           # 文件路径
```

### 3.3 LangChain.dart 支持的 LLM Provider

| Provider | 包名 | 模型示例 | 适用场景 |
|---|---|---|---|
| OpenAI | [langchain_openai](https://pub.dev/packages/langchain_openai) | GPT-4o, GPT-4.1, o3, o4-mini | 造句练习 |
| Google | [langchain_google](https://pub.dev/packages/langchain_google) | Gemini 2.5 Pro/Flash | **推荐用于拍照识词**（原生 bounding box） |
| Anthropic | [langchain_anthropic](https://pub.dev/packages/langchain_anthropic) | Claude 4.5 Sonnet, Opus | 造句练习 |
| Ollama | [langchain_ollama](https://pub.dev/packages/langchain_ollama) | Llama 4, Gemma 3, Qwen3, Mistral | 本地运行（可选） |
| Mistral | langchain_mistralai | Mistral Large | 造句练习 |

> **切换 LLM 只需修改一行 Provider 实例化参数，其余代码完全不变。**  
> **拍照识词强烈推荐 Gemini**：Gemini 2.5 系列专门为 `box_2d` 边界框检测做了后训练，空间定位精度远超其他多模态模型。

---

## 4. 离线优先架构设计

### 4.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                       UI Layer (Flutter)                     │
│  DictPage  PracticePage  VisualPage  GrammarPage  History   │
│  SettingsPage  HomePage                                      │
└──────┬───────────┬───────────┬───────────┬──────────────────┘
       │           │           │           │
  ┌────▼────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐
  │Riverpod │ │Riverpod│ │Riverpod│ │Riverpod│
  │Providers│ │Providers│ │Providers│ │Providers│
  └────┬────┘ └───┬────┘ └───┬────┘ └───┬────┘
       │           │           │           │
┌──────▼───────────▼───────────▼───────────▼──────────────────┐
│                    Repository Layer                          │
│  DictRepo  PracticeRepo  VisualRepo  GrammarRepo  HistoryRepo│
└──┬──────────┬────────┬────────┬────────┬───────────────────┘
   │          │        │        │        │
┌──▼──┐  ┌───▼───┐ ┌─▼────┐ ┌─▼───┐ ┌─▼────┐ ┌──────────────┐
│MDict│  │ MeCab │ │Gemini│ │JSON  │ │Hive  │ │  LangChain   │
│.mdx │  │ 分词  │ │2.5   │ │Asset │ │ CE   │ │  (在线)      │
│离线 │  │ 离线  │ │在线  │ │离线  │ │离线  │ │  OpenAI 等   │
└─────┘  └───────┘ └──────┘ └──────┘ └──────┘ └──────────────┘
```

### 4.2 离线保障策略

- **所有本地功能**在无网络时 100% 可用
- LLM / TTS / 多模态调用前检查网络状态（[connectivity_plus](https://pub.dev/packages/connectivity_plus)），无网络时显示明确提示
- TTS 无网络时自动降级到系统本地引擎
- MDict 词典文件由用户自行导入（.mdx + .mdd），存储在应用沙箱内
- MeCab IPA 词典随应用打包或首次启动自动下载

---

## 5. 功能模块详细设计

> **实现状态：** 5.1 = 已实现 | 5.2-5.8 = 设计阶段（未实现）

### 5.1 MDict 本地字典 ✅

> **参考：** [LunaTranslator 字典架构](https://github.com/HIllya51/LunaTranslator/tree/main/src/LunaTranslator/cishu)

#### 5.1.1 技术方案

使用 [dict_reader](https://pub.dev/packages/dict_reader)（pub.dev, v1.6.0）纯 Dart 解析 MDict 文件，**零网络依赖**。该包支持 .mdx（文本索引）和 .mdd（资源文件）格式，与 LunaTranslator 的 `readmdict` 库功能对等。

```dart
// dict_reader 核心 API（实际使用的接口）
import 'package:dict_reader/dict_reader.dart';

final reader = DictReader('/path/to/dictionary.mdx');
await reader.initDict(); // 必须先初始化

// 读取词典元数据
final title = reader.header['Title'];
final entryCount = reader.numEntries;

// 精确查询（返回匹配记录的偏移信息列表）
final matches = await reader.locateAll('食べる');

// 读取单条记录内容
final recordBytes = await reader.readOneMdx(matches.first);

// 前缀/模糊搜索（返回匹配词列表）
final suggestions = reader.search('たべ', limit: 8);

// 读取 .mdd 资源文件内容
final resourceBytes = await reader.readOneMdd(resourceMatch);
```

**源码参考：**
- [dict_reader on pub.dev](https://pub.dev/packages/dict_reader)
- [dict_reader GitHub](https://github.com/mumu-lhl/dict_reader)

#### 5.1.2 词典管理

```
用户流程：
1. 字典页面 → 导入 .mdx 文件（通过原生文件选择器，仅显示 .mdx 类型）
2. 应用将 .mdx 复制到 App Support/dictionaries/<id>/ 目录
3. 自动检测并复制同名 .mdd 资源文件（如存在）
4. 通过 DictReader 读取词典头部 Title 和 numEntries 元数据
5. 配置持久化到 SharedPreferences（JSON 序列化）
6. 支持同时加载多本词典
7. 每本词典可独立启用/禁用（启用状态变更后自动重新搜索）
8. 支持删除词典（删除文件 + 清理配置）
```

DictReader 实例按需惰性初始化并缓存在 Map<String, DictReader> 中，.mdd Reader 同理独立缓存。词典加载时不构建额外索引，由 dict_reader 内部管理索引。

#### 5.1.3 数据模型

```dart
@immutable
class DictionaryEntry {
  final String word;                 // 用户查询/显示的词条
  final String definitionHtml;       // 已修复资源引用的 HTML 定义（可直接渲染）
  final String sourceDictionary;     // 来源词典名称
  final String? resolvedWord;        // 跟随 @@@LINK= 重定向后的目标词（无重定向则为 null）
  final List<String> redirectChain;  // 重定向跳转链
  bool get isRedirected => resolvedWord != null && resolvedWord != word;
}

@immutable
class DictionarySearchResult {
  final String query;
  final List<DictionaryEntry> entries;
  final List<String> suggestions;    // 无精确匹配时返回的前缀建议（最多 12 条）
  static const empty = DictionarySearchResult(query: '', entries: [], suggestions: []);
}

@immutable
class DictionaryImportResult {
  final DictionaryConfig config;
  final bool copiedMdd;              // 是否同时导入了 .mdd 文件
}

@immutable
class DictionaryConfig {
  final String id;                   // 唯一标识符: {sourceName}_{timestamp}
  final String name;                 // 词典名称（来自 MDict Title 头部）
  final String mdxPath;              // .mdx 文件绝对路径
  final String? mddPath;             // .mdd 文件绝对路径（可选）
  final DateTime importedAt;         // 导入时间
  final bool enabled;                // 是否启用（默认 true）
  final int? entryCount;             // 条目数量（来自 DictReader.numEntries）
  // 支持 fromJson / toJson / copyWith
}
```

#### 5.1.4 Riverpod Provider 设计

实际实现采用**单一 AsyncNotifier + 扁平 State** 模式，而非分散的 family provider：

```dart
// 仓库注入
final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  final repository = LocalDictionaryRepository(
    SharedPreferencesAsync(),
    DictionaryService(),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

// 控制器（AsyncNotifier — 管理搜索、导入、启用/禁用、删除）
final dictionaryControllerProvider =
    AsyncNotifierProvider<DictionaryController, DictionaryState>(
      DictionaryController.new,
    );

// 核心状态：一个扁平不可变类
class DictionaryState {
  final List<DictionaryConfig> configs;
  final DictionarySearchResult result;
  final String query;
  final bool isSupported;           // 平台是否支持（Web 为 false）
  final bool isImporting;
  final bool isSearching;
  final String? errorMessage;
  final String? lastImportedName;
  bool get hasEnabledDictionary => configs.any((c) => c.enabled);
}
```

`DictionaryController` (AsyncNotifier) 提供方法：
- `build()` — 初始化：加载配置列表，检测 `isSupported`
- `importDictionary()` — 调用仓库导入，重新加载配置，如有查询则自动重搜
- `search(String query)` — 空查询返回空结果；调用仓库搜索已启用词典
- `setEnabled(String id, bool enabled)` — 切换启用状态，如有查询则自动重搜
- `deleteDictionary(DictionaryConfig)` — 删除文件 + 配置，重新加载，自动重搜
- `clearImportNotice()` — 清除导入成功提示

DictReader 实例由 `DictionaryService` 内部惰性缓存（`Map<String, DictReader>`），不通过 Riverpod 暴露。

#### 5.1.5 WebView 渲染与 HTML 资源修复

字典条目通过 `InAppWebView` 渲染为浏览器 HTML（非 Flutter Widget 树），遵循 LunaTranslator 的渲染模式：

**HTML 模板：**
- 每条记录包装在完整 HTML 文档中
- 内容置于 `<div id="luna_dict_internal_view">` 内
- 内联 JavaScript 辅助函数：`luna_post_resize`、`safe_mdict_search_word`、`mdict_play_sound`、`replacelongvarsrcs`、`clear_hightlight`
- 主题色彩通过 Dart 端注入 CSS 变量（`_cssColor`、`_cssString`）
- WebView 高度通过 `lunaResize` JS handler 动态调整（160px ~ 5000px 范围）

**资源修复（`_repairMdictHtml`）：**
- `entry://` 链接 → `javascript:safe_mdict_search_word('...')` 回调
- `sound://` 链接 → `javascript:mdict_play_sound(...)` 内联 base64 音频
- 图片/字体等资源 → 通过读取 .mdd 或本地文件后转为 `data:` URI 内联
- 外部 CSS 文件内容 → 收集后作为内联 `<style>` 块追加
- CSS `url()` 引用 → 同样转为内联 data URI
- 资源查找顺序：本地文件（mdx 旁边）→ .mdd 同名记录（容忍多种路径格式）→ 保留原始 URL

**重定向解析（`_readResolvedEntries`）：**
- 递归解析 `@@@LINK=target`，最大深度 8
- 循环检测（visited set）
- 多目标重定向时展开为多条 `DictionaryEntry`

**WebView 内部跨词查询：**
- 用户点击条目内任意词 → JavaScript 调用 `safe_mdict_search_word` → Flutter 端 JS handler (`lunaSearchWord`) → 通过 URL 提取查找词 → 调用 `dictionaryControllerProvider.search(word)` → 页面原地重建结果
- 通过 `shouldOverrideUrlLoading` 拦截 `entry://`、`mdict://`、`bword://` 协议的 URL，阻止默认导航行为

#### 5.1.6 分词二次查询联动（计划中，尚未实现）

计划与 MeCab 分词引擎联动（参考 LunaTranslator 的分词二次查询）：

```
字典详情页显示释义时：
1. MeCab 对释义中的日语例句进行分词
2. 每个分词渲染为可点击 Chip（ActionChip）
3. 点击分词 → 触发新的字典查询 → navigate('/dictionary/:word')
```

当前版本的词间跳转通过 WebView JavaScript bridge 实现（见 5.1.5），尚未集成 MeCab 分词。

---

### 5.2 日语分词引擎 🆕

> **参考：** [LunaTranslator 分词系统](https://github.com/HIllya51/LunaTranslator)（MeCab + UniDic）

#### 5.2.1 技术方案

使用 [mecab_for_dart](https://pub.dev/packages/mecab_for_dart)（pub.dev），基于 MeCab 0.996 的 Dart FFI 绑定，**完全离线**。

| 特性 | 说明 |
|---|---|
| 底层 | MeCab 0.996 C 库，通过 `dart:ffi` 调用 |
| 词典 | IPADIC（推荐，~50MB）/ UniDic / NEologd |
| 输出 | 词条 + 词性 + 读音 + 原形 |
| 平台 | Android / iOS / Windows / macOS / Linux / Web |

**源码参考：**
- [mecab_for_dart on pub.dev](https://pub.dev/packages/mecab_for_dart)
- [mecab_for_flutter GitHub](https://github.com/CaptainDario/mecab_for_flutter)

#### 5.2.2 数据模型

```dart
class Token {
  final String surface;     // 表層形（食べ）
  final String reading;     // 読み（タベ）
  final String baseForm;    // 原形（食べる）
  final String pos;         // 品詞（動詞）
  final String posDetail;   // 品詞細分類（一段）
}
```

#### 5.2.3 封装设计

```dart
class JapaneseTokenizer {
  static JapaneseTokenizer? _instance;
  late MeCab _mecab;

  Future<void> initialize({String? dicDir}) async {
    _mecab = MeCab();
    await _mecab.open(dicDir);
  }

  List<Token> tokenize(String text) {
    final node = _mecab.parseToNode(text);
    // 遍历 MeCab Node 链表，提取 Token
  }

  /// 提取所有独立词（供字典二次查询用，过滤助词/助动词/记号）
  List<String> extractWords(String text) {
    return tokenize(text)
        .where((t) => t.pos != '助詞' && t.pos != '助動詞' && t.pos != '記号')
        .map((t) => t.baseForm.isNotEmpty ? t.baseForm : t.surface)
        .toList();
  }
}
```

---

### 5.3 多模型 LLM 层 🆕

> **参考：** [Japanese-Sentence-Pratice 的 Gemini AI 交互](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/geminiService.ts)

#### 5.3.1 设计目标

- **不绑定单一模型提供商**
- 用户可在设置中自由切换 OpenAI / Gemini / Claude / Ollama
- 统一 `BaseChatModel` 接口，业务代码零改动
- 支持流式输出（Streaming）

#### 5.3.2 LangChain.dart 统一抽象

> **包来源：** [langchaindart.dev](https://pub.dev/publishers/langchaindart.dev/packages)

```dart
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

/// LLM 工厂：根据用户设置返回对应的 ChatModel
BaseChatModel createLLM(AppSettings settings) {
  switch (settings.llmProvider) {
    case LLMProvider.openai:
      return ChatOpenAI(
        apiKey: settings.openaiKey,
        model: settings.openaiModel,          // 'gpt-4o'
        temperature: 0.7,
      );
    case LLMProvider.gemini:
      return ChatGoogleGenerativeAI(
        apiKey: settings.geminiKey,
        model: settings.geminiModel,          // 'gemini-2.5-flash'
        temperature: 0.7,
      );
    case LLMProvider.anthropic:
      return ChatAnthropic(
        apiKey: settings.anthropicKey,
        model: settings.anthropicModel,       // 'claude-sonnet-4-20250514'
        temperature: 0.7,
      );
    case LLMProvider.ollama:
      return ChatOllama(
        baseUrl: settings.ollamaUrl,          // 'http://localhost:11434'
        model: settings.ollamaModel,          // 'qwen3:14b'
        temperature: 0.7,
      );
  }
}
```

#### 5.3.3 造句练习 Prompt 模板

直接参考 [geminiService.ts](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/geminiService.ts) 的设计：

```dart
class PracticePromptTemplate {
  /// 生成中文句子（供用户翻译）
  /// 参考：geminiService.ts getLevelSpecificPrompt()
  static PromptTemplate sentenceGeneration(
    Difficulty level, 
    SentenceLength length,
    GrammarPoint? grammarPoint,
  ) {
    final levelGuidance = switch (level) {
      Difficulty.N5 => "日常话题（问候、家庭、食物、购物），使用 です/ます 形",
      Difficulty.N4 => "爱好、计划、请求许可，涉及可能形/条件形/授受动词",
      Difficulty.N3 => "工作、校园、表达意见，涉及被动/使役/～はずだ/～べきだ",
      Difficulty.N2 => "社会议题、新闻、正式场合，涉及敬語/～うちに/～かわりに",
      Difficulty.N1 => "抽象/技术/文学话题，复杂句式，高级词汇",
    };

    final grammarInstruction = grammarPoint != null
        ? '''
语法重点：${grammarPoint.grammarPoint}
含义：${grammarPoint.meaningCn}
用法：${grammarPoint.usage}
句子必须自然地融入此语法点。
'''
        : '请选择一个适合 JLPT $level 的常用语法点并自然融入。';

    return PromptTemplate.fromTemplate('''
你是一位日语教师。请生成一句自然的中文句子供学生翻译成日语。

要求：
- JLPT 等级：$level ($levelGuidance)
- 句子长度：$length
- $grammarInstruction

请只输出这句中文，不要加任何解释。
    ''');
  }

  /// 评估用户翻译（流式）
  /// 参考：geminiService.ts evaluateSentenceStream()
  static PromptTemplate translationEvaluation() {
    return PromptTemplate.fromTemplate('''
评估以下日语翻译。

中文原文：{chineseSentence}
用户翻译：{userTranslation}

请用以下格式回复（严格遵守）：
score: [0-100的整数分数]
evaluation: [一句话总体评价]
correctedSentence: [更自然/正确的日语表达]

---
[详细解释，包括语法错误分析、词汇建议、自然度评价等]
    ''');
  }
}
```

#### 5.3.4 流式评估

```dart
class PracticeRepository {
  final BaseChatModel _llm;
  
  Stream<EvaluationChunk> evaluateTranslationStream({
    required String chineseSentence,
    required String userTranslation,
  }) async* {
    final prompt = PracticePromptTemplate.translationEvaluation().format({
      'chineseSentence': chineseSentence,
      'userTranslation': userTranslation,
    });
    
    final stream = _llm.stream(PromptValue.string(prompt));
    
    String buffer = '';
    bool headerParsed = false;
    
    await for (final chunk in stream) {
      buffer += chunk.output;
      
      if (!headerParsed && buffer.contains('\n---\n')) {
        final parts = buffer.split('\n---\n');
        final header = _parseHeader(parts[0]);
        headerParsed = true;
        
        yield EvaluationChunk.structured(
          score: header.score,
          evaluation: header.evaluation,
          corrected: header.corrected,
        );
        
        if (parts.length > 1) {
          yield EvaluationChunk.explanation(parts[1]);
        }
      } else if (headerParsed) {
        yield EvaluationChunk.explanation(chunk.output);
      }
    }
  }
}
```

---

### 5.4 TTS 语音合成 🆕

> **参考：** [Japanese-Sentence-Pratice 的 TTS 实现](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/geminiService.ts)（`generateSpeech` 函数 + `gemini-2.5-flash-preview-tts`）

#### 5.4.1 三级降级策略

日语 TTS 发音质量直接影响学习体验，采用三级降级：

| 优先级 | 方案 | 引擎 | 质量 | 网络 |
|---|---|---|---|---|
| 🥇 **Gemini TTS** | [google_generative_ai](https://pub.dev/packages/google_generative_ai) | `gemini-2.5-flash-preview-tts` | ⭐⭐⭐⭐⭐ | 在线 |
| 🥈 **Cloud TTS** | [cloud_text_to_speech](https://pub.dev/packages/cloud_text_to_speech) | Google Cloud / Azure / Amazon | ⭐⭐⭐⭐ | 在线 |
| 🥉 **本地 TTS** | [flutter_tts](https://pub.dev/packages/flutter_tts) | Android TTS / iOS AVSpeechSynthesizer | ⭐⭐⭐ | **离线** |

> **推荐 Gemini TTS**：日语发音自然度远超传统 TTS，对声调（アクセント）和自然停顿的把握极佳。在 Japanese-Sentence-Pratice 项目中已验证（`Leda` 音色）。

#### 5.4.2 各方案对比

| 维度 | Gemini TTS | Cloud TTS | 本地 TTS |
|---|---|---|---|
| 日语自然度 | 🏆 最佳（AI 原生） | 优秀 | 一般（机械感） |
| 延迟 | 中（AI 生成） | 低（专用 API） | 极低（本地） |
| 费用 | Gemini API 配额 | 按字符计费 | 免费 |
| 离线可用 | ❌ | ❌ | ✅ |
| 多音色 | Leda / Puck / Charon / Kore / Fenrir / Aoede | 多厂商多音色 | 系统默认 |

#### 5.4.3 封装设计

```dart
enum TTSMode { gemini, cloud, local, auto }

class TTSService {
  late final GoogleGenerativeAI? _genAI;      // Gemini TTS
  late final CloudTextToSpeech? _cloudTTS;     // 云 TTS
  late final FlutterTts _localTTS;             // 本地兜底
  TTSMode _mode;

  Future<void> initialize({
    required TTSMode mode,
    String? geminiApiKey,
    TTSProvider? cloudProvider,
    String? cloudCredentials,
  }) async {
    _mode = mode;
    _localTTS = FlutterTts();
    await _localTTS.setLanguage('ja-JP');
    if (geminiApiKey != null) _genAI = GoogleGenerativeAI(apiKey: geminiApiKey);
    if (cloudProvider != null) _cloudTTS = CloudTextToSpeech(/*...*/);
  }

  /// 🥇 Gemini TTS（参考 geminiService.ts generateSpeech）
  Future<Uint8List?> _speakWithGemini(String text) async {
    if (_genAI == null) return null;
    try {
      final model = _genAI!.getGenerativeModel(
        model: 'gemini-2.5-flash-preview-tts',
        generationConfig: GenerationConfig(
          responseModalities: [Modality.audio],
          speechConfig: SpeechConfig(
            voiceConfig: VoiceConfig(
              prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: 'Leda'),
            ),
          ),
        ),
      );
      final response = await model.generateContent([
        Content.text('Say it clearly in Japanese: $text'),
      ]);
      final audioBase64 = response.candidates
          ?.first.content?.parts
          ?.firstWhereOrNull((p) => p.inlineData != null)
          ?.inlineData?.data;
      if (audioBase64 != null) return base64.decode(audioBase64);
    } catch (_) { /* 降级 */ }
    return null;
  }

  /// 统一入口：自动降级
  Future<void> speakJapanese(String text, {bool isOnline = true}) async {
    if (_mode == TTSMode.local || !isOnline) {
      return _localTTS.speak(text);
    }

    // 尝试 Gemini → Cloud → Local
    Uint8List? audio;
    if (_mode == TTSMode.gemini || _mode == TTSMode.auto) {
      audio = await _speakWithGemini(text);
    }
    if (audio == null && (_mode == TTSMode.cloud || _mode == TTSMode.auto)) {
      audio = await _speakWithCloud(text);
    }
    if (audio != null) {
      return _playAudio(audio);
    }
    return _localTTS.speak(text);
  }
}
```

---

### 5.5 造句练习引擎 🆕

> **参考：** [Japanese-Sentence-Pratice 完整实现](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice)

#### 5.5.1 练习模式

| 模式 | 说明 | 离线可用 | 来源 |
|---|---|---|---|
| 📝 **翻译造句** | 给出中文 → 用户翻译成日语 → AI 评分纠错 | ❌ 需 LLM | Japanese-Sentence-Pratice |
| 🎯 **选择题** | 给出中文 → 4 选 1 正确日语 → AI 生成干扰项 | ❌ 需 LLM | Japanese-Sentence-Pratice |
| ✅ **自由造句** | 用户输入日语 → AI 检查语法/自然度 | ❌ 需 LLM | Japanese-Sentence-Pratice |
| 📖 **语法浏览** | 按 JLPT 等级浏览语法点 + 例句 | ✅ 离线 | 本地 JSON |

#### 5.5.2 状态机

```
Welcome ──→ Loading ──→ Practicing ──→ Feedback
  ↑                         │              │
  └─────────────────────────┴──────────────┘
             (下一题 / 返回)

附加路径：
  Welcome → Grammar    (离线语法浏览)
  Welcome → History    (离线历史查看)
  Welcome → Visual     (拍照识词)
```

#### 5.5.3 数据模型

```dart
// 参考：Japanese-Sentence-Pratice types.ts
enum Difficulty { N5, N4, N3, N2, N1 }
enum SentenceLength { short, medium, long }
enum GameMode { translation, multipleChoice, sentenceCheck }
enum GameState { welcome, loading, practicing, feedback, grammar, history }

class SentenceTask {
  final String chineseSentence;
  final GrammarPoint? grammarPoint;
}

class PracticeFeedback {
  final int score;             // 0-100
  final String evaluation;     // 一句话评价
  final String correctedSentence;
  final String explanation;    // 详细解释
}

class MultipleChoiceTask {
  final String chineseSentence;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final GrammarPoint? grammarPoint;
}

class GrammarPoint {
  final Difficulty level;
  final String grammarPoint;   // 如 "～はずだ"
  final String meaningCn;      // 中文含义
  final String usage;          // 接续法
  final String exampleJa;      // 日语例句
  final String exampleCn;      // 中文翻译
  final String note;           // 备注
}
```

#### 5.5.4 与字典联动

造句反馈页中的日语文本经过分词处理，任意单词可点击查询 MDict 词典（与字典功能联动）：

```dart
/// 可分词 + 可查词的日语文本组件
class JapaneseTextWithDictionary extends ConsumerWidget {
  final String text;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.read(tokenizerProvider).tokenize(text);
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: tokens.map((token) => ActionChip(
        label: Text(token.surface, style: TextStyle(fontSize: 16)),
        onPressed: () => context.push('/dictionary/${token.baseForm}'),
      )).toList(),
    );
  }
}
```

---

### 5.6 语法库 🆕

> **数据来源：** [Japanese-Sentence-Pratice](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice) 的 `jlpt_grammar_full.json`

#### 5.6.1 实现

```dart
class GrammarRepository {
  List<GrammarPoint>? _cache;

  Future<List<GrammarPoint>> loadAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/jlpt_grammar_full.json');
    _cache = (json.decode(jsonStr) as List)
        .map((e) => GrammarPoint.fromJson(e))
        .toList();
    return _cache!;
  }

  List<GrammarPoint> filterByLevel(Difficulty level) { /* ... */ }
  GrammarPoint? randomByLevel(Difficulty level) { /* ... */ }
}
```

---

### 5.7 练习历史 🆕

> **参考：** [Japanese-Sentence-Pratice historyService.ts](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/historyService.ts)

使用 [hive_ce](https://pub.dev/packages/hive_ce)（已在 flutter-template 中配置）替代 localStorage：

```dart
@HiveType(typeId: 10)
class HistoryItem extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final int timestamp;
  @HiveField(2) final String gameMode;
  @HiveField(3) final String difficulty;
  @HiveField(4) final String chineseSentence;
  @HiveField(5) final String userSentence;
  @HiveField(6) final String correctedSentence;
  @HiveField(7) final int score;
  @HiveField(8) final String evaluation;
  @HiveField(9) final String explanation;
}
```

功能：
- 按时间倒序展示 | 按模式/难度筛选
- 点击可重新查看反馈详情
- 支持导出/导入 JSON（参考 historyService.ts 的 mergeAndSaveHistory）
- 上限 200 条（自动裁剪）

---

### 5.8 拍照识词 🆕（ビジュアル単語帳）

> **直接参考：** [Hanekawa-00/sync](https://github.com/Hanekawa-00/sync) — Google AI Studio 空间理解应用  
> **核心技术：** `gemini-robotics-er-1.6-preview` / `gemini-2.5-flash` 原生 `box_2d` 边界框检测  
> **关键源码：** [Prompt.tsx](https://github.com/Hanekawa-00/sync/blob/main/src/Prompt.tsx)（API 调用 + 坐标转换）、[Content.tsx](https://github.com/Hanekawa-00/sync/blob/main/src/Content.tsx)（边界框渲染）  
> **参考文章：** [Use Gemini 2.5 for Zero-Shot Object Detection & Segmentation](https://blog.roboflow.com/gemini-2-5-object-detection-segmentation/)

#### 5.8.1 功能概述

用户拍照或上传图片后，AI 多模态模型自动识别图中所有**日语文字**和**物体**，以边界框标记，用户点击任意框即可查询 MDict 词典。

```
使用场景：
  📸 日本街头招牌 → 框出「ラーメン」「営業中」→ 点击查词
  📸 日语教科书页面 → 框出所有生词 → 逐个查询
  📸 实物场景 → 框出「自転車」「信号機」→ 点击学单词
```

#### 5.8.2 为什么选 Gemini

Gemini 系列是目前**唯一**专门为 `box_2d` 边界框检测做过后训练的多模态模型。sync 项目验证了两款模型的效果：

| 模型 | 定位 | 适用场景 |
|---|---|---|
| `gemini-robotics-er-1.6-preview` | 机器人空间理解专用 | 🏆 物体空间定位精度最高（sync 默认） |
| `gemini-2.5-flash` / `gemini-flash-latest` | 通用多模态 | 日语 OCR + 物体识别的平衡选择 |

| 对比 | Gemini | GPT-4o | Claude 4.5 |
|---|---|---|---|
| 原生 box_2d | ✅ 后训练优化 | ❌ 不稳定 | ❌ 不支持 |
| JSON 结构化输出 | ✅ responseSchema / responseMimeType | ✅ | ❌ |
| 延迟 | 低 | 中 | 中 |

#### 5.8.3 Prompt 设计

直接采用 sync 项目验证过的 Prompt 格式（来源：[Prompt.tsx getRoboticsPrompt()](https://github.com/Hanekawa-00/sync/blob/main/src/Prompt.tsx)）：

```dart
/// 拍照识词 Prompt（经过 sync 项目验证的格式）
class VisualVocabularyPrompt {
  /// 日语文字 + 物体联合检测
  static String buildPrompt({required String target}) {
    return '''
Task: Detect ${target}.
Return a JSON array of objects.
Each object must have:
- "box_2d": [ymin, xmin, ymax, xmax] (coordinates 0-1000)
- "label": text label (Japanese text or object name in Japanese)
Example: [{"box_2d": [100, 200, 300, 400], "label": "ラーメン"}]
Avoid points. Return ONLY the JSON.''';
  }

  /// 日语学习场景 —— 同时检测文字和物体
  static String buildJapaneseLearningPrompt() {
    return '''
Task: Detect all Japanese text and objects in this image.
Return a JSON array of objects.
Each object must have:
- "box_2d": [ymin, xmin, ymax, xmax] (coordinates 0-1000)
- "label": the Japanese text, or the Japanese name of the object
- "type": "text" or "object"
Example: [
  {"box_2d": [100, 200, 300, 400], "label": "ラーメン", "type": "text"},
  {"box_2d": [400, 100, 550, 350], "label": "信号機", "type": "object"}
]
Avoid points. Return ONLY the JSON. Limit to 25 items.''';
  }
}
```

#### 5.8.4 坐标系统

⚠️ **关键细节**（来源：sync Prompt.tsx `formattedBoxes`）：

Gemini 返回的 `box_2d` 是 **[ymin, xmin, ymax, xmax]** 格式（Y 在前！），归一化到 0-1000。

```dart
/// 坐标转换：Gemini box_2d [ymin, xmin, ymax, xmax] (0-1000) → 归一化 (0.0-1.0)
/// 参考：sync Prompt.tsx formattedBoxes
class Box2DConverter {
  /// 从 Gemini 返回的 box_2d 计算归一化矩形
  static Rect fromBox2d(List<int> box2d) {
    final ymin = box2d[0] / 1000.0;  // 上边界（Y 在前！）
    final xmin = box2d[1] / 1000.0;  // 左边界
    final ymax = box2d[2] / 1000.0;  // 下边界
    final xmax = box2d[3] / 1000.0;  // 右边界
    
    return Rect.fromLTRB(
      xmin,                           // left
      ymin,                           // top
      xmax,                           // right
      ymax,                           // bottom
    );
  }
  
  /// 归一化矩形 → 屏幕像素（Flutter 用）
  static Rect toScreen(Rect normalized, double screenWidth, double screenHeight) {
    return Rect.fromLTRB(
      normalized.left * screenWidth,
      normalized.top * screenHeight,
      normalized.right * screenWidth,
      normalized.bottom * screenHeight,
    );
  }
}
```

#### 5.8.5 图片预处理

参照 sync 的做法（[Prompt.tsx handleSend](https://github.com/Hanekawa-00/sync/blob/main/src/Prompt.tsx)），发送前将图片缩放至最大 640px：

```dart
/// 图片预处理：缩放至最大 640px（减少 Token 消耗 + 加速推理）
/// 参考：sync Prompt.tsx maxSize = 640
Future<Uint8List> preprocessImage(File imageFile) async {
  final image = img.decodeImage(await imageFile.readAsBytes())!;
  
  const maxSize = 640;
  final scale = min(maxSize / image.width, maxSize / image.height);
  
  if (scale < 1.0) {
    final resized = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );
    return Uint8List.fromList(img.encodePng(resized));
  }
  
  return Uint8List.fromList(img.encodePng(image));
}
```

> 需要添加依赖：`image: ^4.0.0`（Dart 图片处理库）

#### 5.8.6 API 调用 + JSON 容错解析

参照 sync 的容错策略（`jsonrepair` + 多字段名回退）：

```dart
class VisualVocabularyService {
  final GoogleGenerativeAI _genAI;

  Future<VisualDetectionResult> detect(String imagePath) async {
    // 1. 图片预处理
    final imageBytes = await preprocessImage(File(imagePath));
    final base64Image = base64.encode(imageBytes);

    // 2. 调用 Gemini
    final model = _genAI.getGenerativeModel(
      model: 'gemini-2.5-flash',  // 或 gemini-robotics-er-1.6-preview
      generationConfig: GenerationConfig(
        temperature: 0.5,          // 参照 sync 默认值
        responseMimeType: 'application/json',
      ),
    );

    final response = await model.generateContent([
      Content.multi([
        DataPart('image/png', base64Image),
        TextPart(VisualVocabularyPrompt.buildJapaneseLearningPrompt()),
      ]),
    ]);

    // 3. 容错解析（参照 sync 的 jsonrepair 策略）
    String rawJson = response.text ?? '';
    
    // 清理 markdown 包裹
    if (rawJson.contains('```json')) {
      rawJson = rawJson.split('```json')[1].split('```')[0];
    }
    
    // 尝试解析，失败则尝试修复
    List<dynamic> items;
    try {
      items = json.decode(rawJson) as List<dynamic>;
    } catch (_) {
      // 尝试提取数组（参照 sync 的多格式回退）
      items = _extractArray(rawJson);
    }

    // 4. 转换为领域模型（参照 sync formattedBoxes）
    final results = <DetectedItem>[];
    for (final item in items) {
      final box2d = _extractBox2d(item);
      if (box2d == null) continue;
      
      results.add(DetectedItem(
        label: item['label'] ?? 'unknown',
        type: item['type'] ?? 'text',
        boundingBox: Box2DConverter.fromBox2d(box2d),
      ));
    }

    return VisualDetectionResult(
      items: results,
      originalImagePath: imagePath,
    );
  }

  /// 多字段名回退提取 box_2d（参照 sync 的 hasBoxes 检测逻辑）
  List<int>? _extractBox2d(dynamic item) {
    final candidates = [
      item['box_2d'], item['box_2D'], item['box'],
      item['bounding_box'], item['bounding_box_2d'],
    ];
    for (final c in candidates) {
      if (c is List && c.length == 4) {
        return c.map((e) => (e as num).toInt()).toList();
      }
    }
    return null;
  }

  /// 尝试从畸形 JSON 中提取数组
  List<dynamic> _extractArray(String raw) {
    // 尝试各种包裹键名
    final decoded = json.decode(raw);
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['items', 'boxes', 'results', 'objects', 'texts']) {
        if (decoded[key] is List) return decoded[key];
      }
      // 找第一个数组值
      for (final v in decoded.values) {
        if (v is List) return v;
      }
    }
    throw FormatException('Cannot extract array from response');
  }
}
```

#### 5.8.7 数据模型

```dart
class DetectedItem {
  final String label;          // 文字内容 或 物体日语标签
  final String type;           // 'text' | 'object'
  final Rect boundingBox;      // 归一化矩形 (0.0-1.0)
}

class VisualDetectionResult {
  final List<DetectedItem> items;
  final String originalImagePath;
}
```

#### 5.8.8 Flutter UI 实现

参照 sync [Content.tsx](https://github.com/Hanekawa-00/sync/blob/main/src/Content.tsx) 的渲染方式（百分比定位）：

```
┌─────────────────────────────────┐
│  📸 拍照识词                     │
│  ┌─────────────────────────┐   │
│  │  [图片]                  │   │
│  │  ┌──────────┐           │   │
│  │  │ ラーメン │ ← 文字框  │   │
│  │  └──────────┘           │   │
│  │       ┌────────┐        │   │
│  │       │ 自転車  │ ← 物体 │   │
│  │       └────────┘        │   │
│  └─────────────────────────┘   │
│  文字/物体列表                  │
│  🏷️ ラーメン → 📖              │
│  🏷️ 自転車   → 📖              │
│  [📷 拍照] [🖼️ 相册]           │
└─────────────────────────────────┘
```

**核心实现 —— 参照 sync 的 Stack + 百分比定位 + GestureDetector 模式：**

```dart
class VisualVocabularyViewer extends ConsumerStatefulWidget {
  final String imagePath;
  final VisualDetectionResult? result;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // 底层：图片
      Image.file(File(imagePath), fit: BoxFit.contain),

      // 中层：边界框叠层（参照 sync Content.tsx 的百分比定位）
      if (result != null)
        ...result!.items.map((item) => Positioned(
          // 参照 sync: top: box.y * 100%, left: box.x * 100%
          top: item.boundingBox.top * 100 + '%',     // ymin/1000 * 100
          left: item.boundingBox.left * 100 + '%',    // xmin/1000 * 100
          width: item.boundingBox.width * 100 + '%',
          height: item.boundingBox.height * 100 + '%',
          child: GestureDetector(
            onTap: () => context.push('/dictionary/${item.label}'),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: item.type == 'text' ? Colors.blue : Colors.green,
                  width: 2,
                ),
                color: (item.type == 'text' ? Colors.blue : Colors.green)
                    .withAlpha(50),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  color: item.type == 'text' ? Colors.blue : Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(item.label, style: TextStyle(
                    color: Colors.white, fontSize: 12,
                  )),
                ),
              ),
            ),
          ),
        )),
    ]);
  }
}
```

#### 5.8.9 完整数据流

```
用户拍照/选图 (image_picker)
    │
    ▼
图片文件 (JPEG/PNG)
    │
    ▼
preprocessImage() — 缩放到 max 640px（参照 sync）
    │
    ▼
VisualVocabularyService.detect(imagePath)
    ├── 图片 → base64 编码
    ├── Gemini API 请求
    │   ├── model: gemini-2.5-flash 或 gemini-robotics-er-1.6-preview
    │   ├── contents: [{inlineData: base64}, {text: prompt}]
    │   └── config: {temperature: 0.5, responseMimeType: 'application/json'}
    │
    ▼
JSON 容错解析（参照 sync jsonrepair 策略）
    ├── 清理 markdown 包裹
    ├── 多字段名回退 (box_2d / box / bounding_box)
    └── 提取数组 (items / boxes / results / objects)
    │
    ▼
VisualDetectionResult
    └── items: [{label, type, boundingBox}, ...]
    │
    ▼
坐标转换：box_2d [ymin,xmin,ymax,xmax] → Rect (0.0-1.0)
    │
    ▼
UI 渲染：Stack + Positioned 百分比定位（参照 sync Content.tsx）
    │
    ▼
用户点击框 → GoRouter.push('/dictionary/:label') → MDict 查询
```

---

## 6. 项目目录结构

> **标注说明：** ✅ = 已实现 | 🆕 = 计划新增

```
kotoba_kit/                         # 实际项目名（设计文档中称为 japanese_learning_app）
├── android/                        # ✅ flutter-template 已有
├── ios/                            # ✅ flutter-template 已有
├── web/                            # ✅ flutter-template 已有
├── windows/                        # ✅ flutter-template 已有
├── macos/                          # ✅ flutter-template 已有
├── linux/                          # ✅ flutter-template 已有
├── assets/
│   ├── grammar/
│   │   └── jlpt_grammar_full.json  # 🆕 语法库（来自 Japanese-Sentence-Pratice）
│   └── mecab/
│       └── ipadic/                 # 🆕 MeCab 词典
├── lib/
│   ├── l10n/                       # ✅ 已有
│   │   ├── app_en.arb
│   │   └── app_zh.arb
│   ├── main.dart                   # ✅ 已有
│   ├── main_development.dart       # ✅ 已有
│   ├── main_production.dart        # ✅ 已有
│   ├── main_staging.dart           # ✅ 已有
│   └── src/
│       ├── app/                    # ✅ 应用入口
│       │   ├── app_runner.dart
│       │   └── bootstrap.dart
│       ├── core/                   # ✅ 基础设施
│       │   ├── config/             #   环境配置
│       │   ├── errors/             #   错误处理
│       │   ├── routing/            #   GoRouter
│       │   ├── theme/              #   主题系统 (Material 3)
│       │   ├── settings/           #   设置持久化 (SharedPreferences)
│       │   ├── network/            #   Dio HTTP 客户端
│       │   ├── storage/            #   Hive CE
│       │   ├── cache/              #   JsonCacheStore (TTL)
│       │   ├── platform/           #   平台服务封装
│       │   ├── logging/            #   AppLogger
│       │   ├── windowing/          #   桌面窗口管理
│       │   └── localization/       #   gen-l10n 生成代码
│       ├── data/                   # 数据层
│       │   ├── models/             # ✅ 已实现
│       │   │   ├── dictionary_config.dart     # DictionaryConfig
│       │   │   └── dictionary_entry.dart      # DictionaryEntry / DictionarySearchResult / DictionaryImportResult
│       │   ├── repositories/       # ✅ 字典仓库已实现
│       │   │   └── dictionary_repository.dart # DictionaryRepository 抽象 + LocalDictionaryRepository
│       │   └── services/           # ✅ 字典服务已实现
│       │       ├── dictionary_service.dart        # 条件导出 (IO / stub)
│       │       ├── dictionary_service_io.dart     # 原生平台: dict_reader + 资源修复 + WebView 渲染
│       │       └── dictionary_service_stub.dart   # Web 平台: 返回 isSupported=false
│       ├── features/
│       │   ├── home/                # ✅ 已有
│       │   ├── settings/            # ✅ 已有
│       │   ├── components/          # ✅ 已有
│       │   ├── about/               # ✅ 已有
│       │   ├── dictionary/          # ✅ 字典功能（当前主要功能）
│       │   │   ├── dictionary_page.dart         # 搜索 + 词典管理 + WebView 渲染（单文件 ~843 行）
│       │   │   ├── dictionary_providers.dart    # DictionaryController (AsyncNotifier) + DictionaryState
│       │   │   └── README.md
│       │   ├── practice/            # 🆕 造句练习（计划中）
│       │   ├── grammar/             # 🆕 语法库（计划中）
│       │   ├── history/             # 🆕 练习历史（计划中）
│       │   └── visual_vocabulary/   # 🆕 拍照识词（计划中）
│       └── shared/                  # ✅ 已有
│           ├── widgets/             # AppShell, PageFrame, SectionCard, AppStateViews, ConfirmActionDialog 等
│           └── services/            # AppMessenger
├── test/
│   ├── widget_test.dart             # App 启动 + 导航 + 响应式布局
│   └── core/                        # cache/network 单元测试
└── pubspec.yaml
```

---

## 7. 数据流与状态管理

### 7.1 当前实现（字典模块）

```
┌──────────────────────────────────────────────────┐
│                  DictionaryPage                   │
│  (ConsumerStatefulWidget — ref.listen + 回调)      │
└──────────────────┬───────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │ DictionaryController │  (AsyncNotifier)
        │   + DictionaryState  │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────────┐
        │ DictionaryRepository    │  (抽象接口)
        │ LocalDictionaryRepository│  (SharedPreferences + Service)
        └──────────┬──────────────┘
                   │
        ┌──────────▼──────────┐
        │ DictionaryService   │  (条件导出: IO / stub)
        │  ├─ dict_reader      │  (MDX/MDD 解析)
        │  ├─ 惰性 Reader 缓存 │
        │  ├─ HTML 资源修复    │
        │  └─ 重定向解析       │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │ InAppWebView        │  (渲染 + JS bridge)
        │  ├─ safe_mdict_search_word │
        │  ├─ mdict_play_sound│
        │  └─ lunaResize      │
        └─────────────────────┘
```

数据流：
1. 用户输入查询 → `search()` → 遍历已启用词典 → `DictReader.locateAll(query)` 精确匹配
2. 无匹配时 → `DictReader.search(query, limit: 8)` 收集前缀建议（最多 12 条）
3. 每条匹配 → `_readResolvedEntries()` 递归解析 `@@@LINK=` 重定向（深度 ≤ 8，循环检测）
4. 最终记录 → `_repairMdictHtml()` 修复 `entry://`、`sound://`、图片/CSS/字体引用 → data URI 内联
5. 修复后 HTML → `DictionaryEntry.definitionHtml` → WebView 渲染

### 7.2 计划扩展（后续 Phase）

```
                   ┌──────────────────────┐
                   │   appConfigProvider   │  (环境配置)
                   └──────────┬───────────┘
                              │
         ┌────────────────────┼────────────────────────┐
         │                    │                        │
   ┌─────▼─────┐      ┌──────▼──────┐          ┌─────▼──────┐
   │ llmProvider│      │ttsProvider  │          │tokenizer   │
   │ (LangChain)│      │(三级降级)   │          │Provider    │
   └─────┬─────┘      └──────┬──────┘          └─────┬──────┘
         │                   │                       │
   ┌─────▼─────┐      ┌──────▼──────┐          ┌─────▼──────┐
   │ practice  │      │  audio      │          │dictionary  │
   │ repository│      │  service    │          │providers   │
   └─────┬─────┘      └─────────────┘          └─────┬──────┘
         │                                           │
   ┌─────▼──────┐                             ┌─────▼──────┐
   │practicePage│                             │  dictPage  │
   │  Provider  │                             │  Provider  │
   └────────────┘                             └────────────┘

                   ┌──────────────────────┐
                   │ visualVocabProvider  │  (多模态检测)
                   └──────────┬───────────┘
                              │
                   ┌──────────▼───────────┐
                   │ VisualVocabularyPage │
                   │ → 点击框 → dictPage  │
                   └──────────────────────┘
```

### 7.2 离线检测

```dart
// 使用 connectivity_plus 监听网络状态
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
});
```

---

## 8. 路由设计

### 8.1 当前路由（已实现）

使用 `go_router` + `StatefulShellRoute.indexedStack`，四个顶层分支：

```dart
// lib/src/core/routing/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/dictionary',    // 字典页为默认首页
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        // 首页
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
        ]),
        // 字典（无子路由 — 通过 WebView JS bridge 实现词间跳转）
        StatefulShellBranch(routes: [
          GoRoute(path: '/dictionary', builder: (_, __) => const DictionaryPage()),
        ]),
        // 设置 + 关于
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage(), routes: [
            GoRoute(path: 'about', builder: (_, __) => const AboutPage()),
          ]),
        ]),
        // 组件展示
        StatefulShellBranch(routes: [
          GoRoute(path: '/components', builder: (_, __) => const ComponentsPage()),
        ]),
      ],
    ),
  ],
);
```

注意：字典路由没有 `:word` 子路由。词间跳转通过 WebView 内的 JavaScript bridge 调用 `dictionaryControllerProvider` 重新搜索，而非导航到新路由。

### 8.2 计划路由（后续 Phase）

```dart
// 🆕 造句练习
GoRoute(path: '/practice', ...),
// 🆕 拍照识词
GoRoute(path: '/visual', ...),
// 🆕 语法库
GoRoute(path: '/grammar', ...),
// 🆕 练习历史
GoRoute(path: '/history', ...),
```

---

## 9. 实施路线图

### Phase 1：项目初始化 + 离线字典 MVP ✅ 已完成

| 任务 | 说明 | 状态 |
|---|---|---|
| Fork [flutter-template](https://github.com/Hanekawa-00/flutter-template) | 重命名为 kotoba_kit | ✅ |
| 集成 [dict_reader](https://pub.dev/packages/dict_reader) | DictionaryService 封装（IO + stub 条件导出） | ✅ |
| 词典管理 UI | 导入 .mdx（自动检测同名 .mdd）/ 启用禁用 / 删除 | ✅ |
| 字典查询页面 | 精确匹配 + 前缀建议 + WebView 渲染 | ✅ |
| @@@LINK= 重定向解析 | 递归解析（深度 ≤ 8，循环检测） | ✅ |
| HTML 资源修复 | entry:// sound:// → JS 回调；图片/CSS/字体 → data: URI 内联 | ✅ |
| WebView 渲染 | InAppWebView + LunaTranslator 风格 JS bridge | ✅ |
| 配置持久化 | SharedPreferences JSON 序列化 | ✅ |
| 集成 [mecab_for_dart](https://pub.dev/packages/mecab_for_dart) | 封装 TokenizerService | ⏳ 未开始 |
| 分词二次查询 | 点击分词 Chip → 跳转查词 | ⏳ 未开始 |

**交付物：** 可独立使用的离线字典 App（字典核心功能已完成，分词联动推迟到 Phase 2）

### Phase 2：造句练习 + LLM + TTS（第 3-4 周）

| 任务 | 说明 |
|---|---|
| 集成 [langchain](https://pub.dev/packages/langchain) 生态 | 封装 LLMService + Provider 切换 |
| 翻译造句模式 | Prompt 模板 + 流式评估（参考 [geminiService.ts](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice/blob/main/services/geminiService.ts)） |
| 语法库集成 | [jlpt_grammar_full.json](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice) → Hive 缓存 |
| TTS 三级降级 | Gemini TTS → [cloud_text_to_speech](https://pub.dev/packages/cloud_text_to_speech) → [flutter_tts](https://pub.dev/packages/flutter_tts) |
| 字典 × 造句联动 | 反馈页分词查词 |

**交付物：** 完整的 AI 辅助造句练习功能

### Phase 3：拍照识词 + 选择题 + 历史（第 5-6 周）

| 任务 | 说明 |
|---|---|
| 📸 拍照识词 | Gemini 2.5 Flash 多模态检测（OCR + 物体定位） |
| 📸 边界框 UI | CustomPainter 叠层 + 点击查词联动 |
| 📸 图片选择 | [image_picker](https://pub.dev/packages/image_picker) 集成（相机/相册） |
| 选择题模式 | LLM 生成选项 + 干扰项 |
| 自由造句检查模式 | 无中文提示，纯语法检查 |
| 练习历史 | Hive CE 持久化 + 统计 |

**交付物：** 功能完整的日语学习应用

### Phase 4：发布准备（第 7-8 周）

| 任务 | 说明 |
|---|---|
| 性能优化 | 大词典加载分页、Hive 索引 |
| 暗色主题适配 | Theme 扩展 |
| 测试覆盖 | 单元测试 + Widget 测试 |
| 打包发布 | App Store / Google Play / 桌面版 |

---

## 10. 完整依赖清单

> **标注：** ✅ = 已安装使用 | 🔲 = 计划引入

### 10.1 当前 pubspec.yaml（kotoba_kit）

```yaml
name: kotoba_kit
description: Offline-first Japanese dictionary and learning toolkit.
version: 1.0.0+1

environment:
  sdk: ^3.11.4

dependencies:
  flutter:
    sdk: flutter

  # === ✅ 基础框架（来自 flutter-template）===
  flutter_riverpod: ^3.3.1         # 状态管理
  go_router: ^17.2.3              # 路由导航
  dio: ^5.9.2                     # HTTP 客户端
  hive_ce: ^2.19.3                # 本地 NoSQL 存储
  hive_ce_flutter: ^2.3.4         # Hive Flutter 适配
  shared_preferences: ^2.5.5      # KV 配置
  window_manager: ^0.5.1          # 桌面窗口管理
  package_info_plus: ^10.1.0      # 应用信息
  cupertino_icons: ^1.0.8         # iOS 风格图标

  # === ✅ 离线字典 ===
  dict_reader: ^1.6.0             # MDict (.mdx/.mdd) 解析
  flutter_inappwebview: 6.1.5     # WebView 渲染字典条目
  file_selector: ^1.1.0           # 原生文件选择器
  path_provider: ^2.1.5           # 文件路径

  flutter_localizations:          # i18n
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### 10.2 计划新增依赖（后续 Phase）

```yaml
  # === 🔲 日语分词 ===
  mecab_for_dart: ^0.2.0          # MeCab FFI 绑定

  # === 🔲 LLM 多模型 (LangChain.dart) ===
  langchain: ^0.8.1
  langchain_openai: ^0.8.1+1
  langchain_google: ^0.3.2
  langchain_anthropic: ^0.3.1
  langchain_ollama: ^0.4.1

  # === 🔲 TTS 语音（三级降级）===
  google_generative_ai: ^0.4.0
  cloud_text_to_speech: ^1.1.0
  flutter_tts: ^4.2.5
  just_audio: ^0.9.40

  # === 🔲 拍照识词 ===
  image_picker: ^1.1.0
  image: ^4.0.0

  # === 🔲 工具 ===
  connectivity_plus: ^6.0.0

dev_dependencies:
  hive_ce_generator: ^1.0.0       # 🔲 Hive TypeAdapter 代码生成
  build_runner: ^2.4.0            # 🔲
  mockito: ^5.4.0                 # 🔲 单元测试 Mock
```

### 10.2 关键包说明

| 包名 | 版本 | 用途 | 离线 | Pub |
|---|---|---|---|---|
| `dict_reader` | 1.6.0 | 解析 .mdx/.mdd 词典文件 | ✅ | [链接](https://pub.dev/packages/dict_reader) |
| `mecab_for_dart` | 0.2.0 | 日语形态素分析 | ✅ | [链接](https://pub.dev/packages/mecab_for_dart) |
| `langchain` | 0.8.1 | LLM 统一抽象层 | ❌ | [链接](https://pub.dev/packages/langchain) |
| `langchain_openai` | 0.8.1+1 | GPT-4o/5 集成 | ❌ | [链接](https://pub.dev/packages/langchain_openai) |
| `langchain_google` | 0.3.2 | Gemini 集成 | ❌ | [链接](https://pub.dev/packages/langchain_google) |
| `langchain_anthropic` | 0.3.1 | Claude 集成 | ❌ | [链接](https://pub.dev/packages/langchain_anthropic) |
| `langchain_ollama` | 0.4.1 | 本地模型集成 | ✅* | [链接](https://pub.dev/packages/langchain_ollama) |
| `google_generative_ai` | 0.4.0 | Gemini TTS + 多模态 | ❌ | [链接](https://pub.dev/packages/google_generative_ai) |
| `cloud_text_to_speech` | 1.1.0 | 云 TTS | ❌ | [链接](https://pub.dev/packages/cloud_text_to_speech) |
| `flutter_tts` | 4.2.5 | 本地 TTS（离线兜底） | ✅ | [链接](https://pub.dev/packages/flutter_tts) |
| `just_audio` | 0.9.40 | 音频播放 | ✅ | [链接](https://pub.dev/packages/just_audio) |
| `image_picker` | 1.1.0 | 相机/相册（拍照识词） | ✅ | [链接](https://pub.dev/packages/image_picker) |
| `image` | 4.0.0 | 图片缩放预处理（640px） | ✅ | [链接](https://pub.dev/packages/image) |
| `connectivity_plus` | 6.0.0 | 网络状态检测 | ✅ | [链接](https://pub.dev/packages/connectivity_plus) |

> \* Ollama 需要用户自行部署本地服务

---

## 11. 附录

### 11.1 参考仓库汇总

| 仓库 | 用途 | 许可 |
|---|---|---|
| [Hanekawa-00/flutter-template](https://github.com/Hanekawa-00/flutter-template) | 项目基座框架 | MIT |
| [HIllya51/LunaTranslator](https://github.com/HIllya51/LunaTranslator) | 字典架构 + 分词参考 | GPL-3.0 ⚠️ |
| [Hanekawa-00/Japanese-Sentence-Pratice](https://github.com/Hanekawa-00/Japanese-Sentence-Pratice) | 造句练习参考 | — |
| [Hanekawa-00/sync](https://github.com/Hanekawa-00/sync) | 物体检测 + 空间理解参考 | MIT |

### 11.2 MDict 词典资源推荐

用户自行获取以下日语 MDict 词典文件：

| 词典名称 | 类型 | 说明 |
|---|---|---|
| 新明解国语辞典 | 日日 | 权威日语原版词典 |
| 大辞林 | 日日 | 收录广泛，释义详细 |
| NHK 日本語発音アクセント辞典 | 发音 | 标准日语声调 |
| 小学館中日・日中辞典 | 日汉/汉日 | 双向查询 |

> ⚠️ 词典版权归原作者所有，请用户自行获取合法授权。

### 11.3 MeCab 词典说明

| 词典 | 大小 | 特点 |
|---|---|---|
| IPADIC | ~50MB | 标准词典，适合通用场景（推荐默认） |
| UniDic | ~200MB | 形态素解析精度更高 |
| NEologd | ~500MB+ | 收录大量新词/网络用语 |

### 11.4 离线能力总览

```
┌─────────────────────────────────────────────────┐
│                离线可用功能（当前）                 │
│  ✅ 字典查询 (MDict .mdx/.mdd)                     │
│  ✅ 应用设置 (SharedPreferences)                   │
│  ✅ 配置持久化 (JSON)                              │
│  -------------------------------------------------  │
│                计划新增（离线）                     │
│  🔲 日语分词 (MeCab)                              │
│  🔲 语法库浏览 (JSON)                             │
│  🔲 练习历史 (Hive CE)                            │
│  🔲 本地 TTS (flutter_tts)                        │
│  -------------------------------------------------  │
│                计划新增（需网络）                   │
│  🔲 LLM 造句反馈                                  │
│  🔲 在线 TTS (Gemini / Cloud)                     │
│  🔲 拍照识词                                      │
└─────────────────────────────────────────────────┘
```

---

> **文档维护者：** Hermes Agent  
> **最后更新：** 2026-05-03  
> **下次评审：** Phase 1 完成后
