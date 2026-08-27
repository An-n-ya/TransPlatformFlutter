# trans_platform

A new Flutter project.

## 分支说明

- **`main`** — 生产分支，不含语音通话（chatroom）功能，依赖更少、构建更简单、包体积更小。
- **`chatroom`** — 语音通话实验分支，依赖 `agora_rtc_engine`，并在底部导航中带有
  "活动" tab（`lib/ui/activites/activities_page.dart`）。该功能尚未达到生产级别。

将 chatroom 的改动合并回 `main` 时，需要一并带回：
`pubspec.yaml` 依赖、`lib/ui/activites/`、`lib/ui/home/app_shell.dart` 中的活动 tab、
`fix_agora_aar.sh` / `fix_agora_spm.sh`，以及 CI（`.github/workflows/build_armv8_apk.yml`、
`ios/ci_scripts/ci_post_clone.sh`）中对应的 Agora 步骤。

## Flavors（prod / dev）

项目支持 `prod` 与 `dev` 两种构建 flavor，不同点：

|              | prod                                     | dev                                   |
|--------------|------------------------------------------|---------------------------------------|
| 后端地址      | `https://trans.annya.work`               | `http://10.0.2.2:8081`（Android 模拟器） |
| Android applicationId | `com.example.trans_platform`     | `com.example.trans_platform.dev`      |
| Android 应用名 | `YX`                                   | `YX Dev`                              |
| Android ABI  | 仅 `arm64-v8a`（减小安装包体积）          | 全部 ABI                              |

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

### 入口文件

- `lib/main.dart`（默认）— 按 flavor 自动连对应后端
- `lib/main_local.dart` — 本地 mock 数据，不连后端（纯 UI 开发）
- `lib/main_remote.dart` — 等价于 `main.dart`（远程模式）

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
