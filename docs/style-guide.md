# 样式与主题开发规范（Style Guide）

本文档是 `YXing`（TransPlatformFlutter）项目的样式/主题开发手册。目标是让颜色、字型、度量与组件风格的来源单一化，确保浅色/深色主题的正确切换以及后续样式变更的低成本维护。

## 1. 颜色（Colors）

- **禁止硬编码颜色字面量**：代码中不允许直接写出 `Color(0xFF...)`、`Colors.xxx` 等字面量颜色。请一律通过当前主题的 `ColorScheme` 获取。
- **取色方式**：在 `build` / 方法顶部获取一次引用再复用：

  ```dart
  final cs = Theme.of(context).colorScheme;
  ```
- **语义映射参考**

  | 用途 | 使用 `colorScheme` token |
  |---|---|
  | 主色 / 强调 | `primary` |
  | 主色容器（圆角图标底） | `primaryContainer` |
  | 次要容器（次按钮） | `secondaryContainer` |
  | 页面背景 | `surface` |
  | 图片占位 / 浅灰底 | `surfaceContainerHighest` |
  | 正文文字 | `onSurface` |
  | 次级文字 / 图标 | `onSurfaceVariant` |
  | 边框 / 分隔线 | `outline` / `outlineVariant` |
  | 错误 / 删除 / 危险 | `error` |
  | 前景覆盖（主按钮文字） | `onPrimary` |
  | 深色遮罩 | `scrim.withValues(alpha: ...)` |
  | 禁用态 | `xxx.withValues(alpha: 0.38)` |

- **例外**：仅当颜色**没有**任何 `ColorScheme` 语义位时（如产品专属强调色、图片上的白字、状态色），才允许使用 `lib/theme/app_palette.dart` 中的品牌 token 或保留 `Colors.white` 覆盖在图片上。新增品牌 token 必须写入 `app_palette.dart`。
- 半透明用法必须用 `.withValues(alpha: x)`，不要新建 8 位十六进制字面量。

## 2. 字型（Typography）

- 优先使用 `Theme.of(context).textTheme.xxx`。
- 表单/按钮等固定字号小样式，可使用 `lib/theme/app_text_styles.dart` 提供的 helper。
- 不要在页面里反复手写 `fontSize: 14, fontWeight: FontWeight.w500` 之类——若高频出现，先在 `app_text_styles.dart` 或组件中收敛。

## 3. 度量（Spacing / Radius）

- 间距、圆角、边框宽度一律使用 `lib/theme/app_spacing.dart` 中的 `AppSpacing.*` 常量，不要散落的魔法数字 `16`、`4`、`100` 等。
- 新增度量前先检查 `AppSpacing` 是否已有可用值。

## 4. 组件复用（Components）

- 复用型的 UI 元素必须抽成组件并放在 `lib/ui/widgets/`，不要在多个页面重复粘贴实现。
- 已封装的高频组件：
  - `AuthScaffold`：引导/登录页脚手架（背景、透明 AppBar、步骤指示器、居中布局）。
  - `AuthTextField`：56 高圆角输入框（含 error/focus 态）。
  - `PrimaryActionButton`：胶囊主/次按钮 + loading。
  - `AppHeaderLogo`：圆角 Logo + 标题 + 副标题。
  - `LabeledDivider`：带文字分隔线。
  - `ErrorBanner`：表单元错误提示。
- 新组件内部同样只从 `Theme` 取样式，禁止硬编码；这样后续改主题只需动主题层即可全局生效。

## 5. 主题（Theme）

- 应用主题统一由 `lib/theme/app_theme.dart`（`buildLightTheme` / `buildDarkTheme`）、`lib/theme/color_schemes.dart` 驱动。
- 全局主题入口在 `lib/main.dart` 的 `MaterialApp`（`theme` / `darkTheme` / `themeMode`）。
- 主题模式由 `lib/theme/theme_provider.dart` 的 `ThemeProvider` 管理并持久化。
- 修改品牌色调：只改 `lib/theme/color_schemes.dart` 的 seed 或 `app_palette.dart`，无需改动业务页面。

## 6. 验收 / 检查

- 提交前运行：`dart format <改动文件>` 与 `dart analyze`，确保无新增 error / warning。
- 用 `grep -rE "Color\(0x|Colors\." lib` 自查是否残留新的硬编码颜色（例外写在 `app_palette.dart` 内的合法 token 除外）。
- 切换 浅色 / 深色 / 跟随系统 三种模式后，检查关键页面对比度可读。