<div align="center">

<img src="assets/images/logoTP_Transparent.png" width="120" height="120" alt="YX Logo" />

# YX · 银杏叶社区

**专为跨性别（Trans）社区打造的社交媒体平台**

一个包容、开放的社区 App —— 支持图文动态、评论互动、话题、好友关注与资源信息流转，
为社区成员提供一个安全、温暖的私域空间。

</div>

> ⚠️ **项目状态：早期开发阶段**（当前版本 `0.0.1`）。
> 功能与架构仍在快速迭代，欢迎通过 Issue / PR 参与共建。

---

## 目录

- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [架构说明](#架构说明)
- [快速开始](#快速开始)
- [Flavors（prod / dev）](#flavorsprod--dev)
- [入口文件](#入口文件)
- [分支说明](#分支说明)
- [测试](#测试)
- [CI / CD](#ci--cd)
- [部署](#部署)
- [贡献指南](#贡献指南)
- [开源许可](#开源许可)

---

## 项目简介

YX 是一个面向跨性别（Trans）社群的移动社交应用。它围绕两个核心目标构建：

- **打造包容开放的社区氛围** —— 提供一个对跨儿友好的安全社交空间（信息流、图文动态、
  评论互动、话题、好友关注等），让每一位成员都能无顾虑地表达与连接。
- **提供及时的资源周转** —— 社区内支持资源/信息的流转与互助，帮助成员高效获取所需支持。

本项目为该应用的 **Flutter 客户端**，配套后端 API 独立部署于
[`https://yx.annya.work`](https://yx.annya.work)（生产环境）。

## 功能特性

**内容与互动**

- 三个信息流：**广场**（全站）、**关注**（关注用户动态）、**附近**（按地理位置过滤）
- 发布图文动态：多图选择（最多 **9 张**）、自动定位标记城市
- 评论与**多层回复**，支持点击回复、@ 通知跳转
- 点赞 / 收藏 / **帖子置顶**（管理员）
- 帖子详情、图片**全屏预览**、无限滚动加载

**社交关系**

- 关注 / 好友、关注者与被关注列表
- 个人主页：头像、bio、背景图、动态 / 点赞 / 收藏 Tab
- 话题功能（如“一起玩游戏”等社区话题）

**搜索与通知**

- 用户 / 话题搜索（含搜索历史）
- 通知中心：点赞、评论、回复、关注等，点击直达对应帖子

**账号与安全**

- 邀请码注册、用户名可用性实时校验
- 邮箱验证码服务（Resend）、登录 / 注册 / 找回密码 / 修改密码 / 更换邮箱
- JWT Token 安全存储（`flutter_secure_storage`），会话自动恢复

**体验**

- 浅色 / 深色 / 跟随系统 三种主题
- 响应式布局、下拉刷新、缓存加速

## 技术栈

| 类别 | 选型 |
|---|---|
| 框架 | Flutter（stable channel）+ Dart SDK `^3.12` |
| 状态管理 | `provider`（全局配置）+ `flutter_riverpod`（数据层，`riverpod_annotation` 代码生成） |
| 网络 | `http`（自定义 `ApiClient` 统一封装 JWT / 分页 / 统一响应解析） |
| 本地存储 | `flutter_secure_storage`（JWT Token）、`shared_preferences`（搜索历史 / 主题偏好） |
| 图片 | `image_picker`（相册选择）、`easy_image_viewer`（全屏预览） |
| 定位 | `location`（获取用户位置，后端逆地理编码为城市） |
| 代码生成 / 检查 | `build_runner`、`riverpod_generator`、`riverpod_lint`、`custom_lint`、`flutter_lints` |
| 应用图标 | `flutter_launcher_icons` |

## 项目结构

```
lib/
├── main.dart                  # 默认入口：按 flavor 自动连接对应后端
├── main_local.dart            # 本地 mock 数据入口（纯 UI 开发，不连后端）
├── main_remote.dart           # 远程模式入口（等价 main.dart）
│
├── config/
│   ├── env.dart               # 环境配置（appFlavor、后端地址，--dart-define 注入）
│   └── dependencies.dart      # 依赖注入（Provider 树：local / remote 两套仓库实现）
│
├── domain/models/             # 数据模型（Post / User / Comment / Topic / …）
│
├── data/
│   ├── repositories/          # 仓库层：auth / post / user / location /
│   │                          #           notification / search / topic
│   │                          #   每个仓库含 *_local（mock）与 *_remote（HTTP）实现
│   ├── services/
│   │   ├── api/api_client.dart          # HTTP 客户端封装（JWT、分页、统一响应）
│   │   ├── token_storage_service.dart   # Token 安全存储
│   │   ├── current_user_provider.dart   # 当前登录用户全局状态
│   │   └── global_config_provider.dart  # 全局配置（debug / baseUrl）
│   └── cache/                 # SSOT 内存缓存（post / user / comment，Riverpod keepAlive）
│
├── providers/                 # Riverpod 状态层
│   ├── repository_providers.dart       # 仓库 Provider
│   ├── feed_pagination_provider.dart   # 信息流游标分页
│   ├── post_providers.dart             # 贴文加载 / 缓存
│   └── *_mutation_providers.dart       # 乐观更新（点赞 / 收藏 / 关注 / 评论）
│
├── theme/                     # 主题系统（详见 docs/style-guide.md）
│   ├── color_schemes.dart     # 浅 / 深色 ColorScheme（从品牌 seed 生成）
│   ├── app_palette.dart       # 品牌色 token（无 ColorScheme 语义时的唯一来源）
│   ├── app_theme.dart         # ThemeData 构建
│   ├── app_spacing.dart       # 间距 / 圆角 / 边框统一常量
│   ├── app_text_styles.dart   # 文本样式 helper
│   └── theme_provider.dart    # 主题模式（system / light / dark）持久化
│
├── ui/                        # 页面层
│   ├── auth/                  # 登录 / 注册 / 找回与重置密码 / Splash
│   ├── welcome/               # 欢迎与首次设置向导
│   ├── home/                  # 首页（信息流 Tab、搜索）
│   ├── posts/                 # 贴文卡片 / 详情 / 发布 / 话题 / 评论
│   ├── notification/          # 通知中心
│   ├── settings/              # 设置 / 个人资料 / 外观 / 关于 / 调试
│   ├── user/                  # 个人主页 / 关注列表
│   └── widgets/               # 可复用组件（AuthScaffold、图片网格等）
│
├── utils/                     # 工具（Result 类型、时间、图片 URL 解析）
├── docs/style-guide.md        # 样式与主题开发规范（新增代码前必读）
└── test/                      # 单元 / 组件测试
```

## 架构说明

项目采用**分层架构**，遵循单一数据源（SSOT）原则：

```
UI (lib/ui)
   │  通过 Provider / Riverpod 消费状态
   ▼
Providers (lib/providers)          ← 状态管理、乐观更新、分页逻辑
   │  调用仓库接口
   ▼
Repositories (lib/data/repositories) ← 抽象仓库，Local / Remote 双实现可切换
   │  Remote 实现经由 ApiClient
   ▼
ApiClient (lib/data/services/api)   ← HTTP 封装：JWT 认证、统一响应、游标分页
   │
   ▼
后端 API（https://yx.annya.work）
```

- **仓库双实现**：`*RepositoryLocal`（内存 mock 数据）用于纯 UI 开发与测试，
  `*RepositoryRemote`（HTTP）用于连接真实后端，由 `lib/config/dependencies.dart`
  通过 Provider 注入切换。
- **SSOT 缓存**：`post_cache` / `user_cache` / `comment_cache` 作为贴文、用户、
  评论的单一数据源，所有读写都经缓存进行；mutation 先乐观更新、失败回滚。
- **主题规范**：颜色、字型、度量统一收敛到主题层（`ColorScheme` + `AppPalette` +
  `AppSpacing`），页面内禁止硬编码颜色。开发新页面**请先阅读
  [`docs/style-guide.md`](docs/style-guide.md)**。

## 快速开始

### 环境要求

- Flutter **stable** channel（≥ 3.27，兼容 Dart SDK `^3.12`）
- Android Studio / Xcode（按目标平台）

### 安装依赖

```bash
flutter pub get
```

> Riverpod 相关代码使用代码生成：修改 `*.dart` 中带注解的 Provider 后，运行
> `dart run build_runner build --delete-conflicting-outputs` 重新生成 `*.g.dart`。

### 运行

```bash
# ① 连开发后端（默认 dev flavor）
flutter run --flavor dev

# ② 纯 UI 开发（本地 mock 数据，不需要后端）
flutter run --target lib/main_local.dart

# ③ 连生产后端
flutter run --flavor prod --dart-define=appFlavor=prod
```

### 测试

```bash
flutter test
```

## Flavors（prod / dev）

项目支持 `prod` 与 `dev` 两种构建 flavor，不同点：

|              | prod                                       | dev                                    |
|--------------|--------------------------------------------|----------------------------------------|
| 后端地址      | `https://yx.annya.work`                    | `http://10.0.2.2:8081`（Android 模拟器） |
| Android applicationId | `com.example.trans_platform`       | `com.example.trans_platform.dev`       |
| Android 应用名 | `YX`                                     | `YX Dev`                               |
| Android ABI  | 仅 `arm64-v8a`（减小安装包体积）            | 全部 ABI                               |

后端地址由 [lib/config/env.dart](lib/config/env.dart) 中的 `appFlavor`
（`--dart-define` 注入，默认 `dev`）决定。

### 构建 / 运行命令

```bash
# 开发（连开发后端）
flutter run --flavor dev

# 生产（连生产后端）
flutter run --flavor prod --dart-define=appFlavor=prod

# 开发 release APK
flutter build apk --release --flavor dev

# 生产 release APK（只出 arm64-v8a）
flutter build apk --release --flavor prod --dart-define=appFlavor=prod \
  --target-platform android-arm64
```

> ⚠️ 注意：`appFlavor` 与 `--flavor` 是两个独立的开关。Android 原生差异
> （ABI、applicationId）由 `--flavor dev|prod` 控制，Dart 侧后端地址由
> `--dart-define=appFlavor=prod` 控制（不传则默认 `dev`）。
>
> iOS 未配置原生 flavor（scheme），如需区分后端只需传 `--dart-define`：
> `flutter build ios --release --dart-define=appFlavor=prod`。
>
> Xcode Cloud 的 `ios/ci_scripts/ci_post_clone.sh` 已固定注入
> `--dart-define=appFlavor=prod`，iOS CI 归档默认构建生产包。

## 入口文件

| 入口 | 说明 | 适用场景 |
|---|---|---|
| `lib/main.dart`（默认） | 按 flavor 自动连对应后端 | 日常开发 / 生产 |
| `lib/main_local.dart` | 本地 mock 数据，不连后端 | 纯 UI 开发、无后端环境 |
| `lib/main_remote.dart` | 等价于 `main.dart`（远程模式） | CI 构建（明确指定远程） |

## 分支说明

- **`main`** — 生产分支，不含语音通话（chatroom）功能，依赖更少、构建更简单、包体积更小。
- **`chatroom`** — 语音通话实验分支，依赖 `agora_rtc_engine`，并在底部导航中带有
  "活动" tab（`lib/ui/activites/activities_page.dart`）。该功能尚未达到生产级别。

将 chatroom 的改动合并回 `main` 时，需要一并带回：
`pubspec.yaml` 依赖、`lib/ui/activites/`、`lib/ui/home/app_shell.dart` 中的活动 tab、
`fix_agora_aar.sh` / `fix_agora_spm.sh`，以及 CI（`.github/workflows/build_armv8_apk.yml`、
`ios/ci_scripts/ci_post_clone.sh`）中对应的 Agora 步骤。

## CI / CD

- **Android**：`.github/workflows/build_armv8_apk.yml` —— 推送到 `main` 时，
  构建 **prod flavor、release 签名** 的 arm64-v8a APK，验证 keystore 凭据后
  上传至 GitHub Artifacts 并发布到 **PGYER**。
- **iOS**：Xcode Cloud —— `ios/ci_scripts/ci_post_clone.sh` 预生成 SPM / Pods
  产物，并以 `--dart-define=appFlavor=prod` 构建生产归档包。
- **签名**：`android/key.properties`（本地，已被 `.gitignore` 忽略）与 GitHub
  Actions Secrets（`KEYSTORE_BASE64` / `KEYSTORE_STORE_PASSWORD` /
  `KEYSTORE_KEY_PASSWORD` / `KEYSTORE_KEY_ALIAS`）二选一；凭据缺失时构建会**显式报错**，
  避免静默产出 debug 签名包。


## 贡献指南

1. **先阅读规范**：[`docs/style-guide.md`](docs/style-guide.md)（主题与样式开发规范）。
2. **提 Issue** 描述需求或 BUG，或直接提 PR（fork → 功能分支 → PR 到 `main`）。
3. 提交前本地检查：

```bash
dart format <改动文件>
dart analyze
flutter test
```

4. 新功能请同步补充 `TODO.md` 对应项的状态。

## 开源许可

本项目基于 **Apache License 2.0** 开源，详见 [LICENSE](LICENSE)。

---

**给社区的一句话：** 这里是你的安全空间。无论你是谁，都欢迎你在 YX 找到归属。
