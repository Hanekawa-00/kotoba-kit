# Flutter Template

一个跨平台 Flutter 应用模板，当前只包含通用能力：

- Material 3 主题系统：系统/浅色/深色、种子色、OLED 深色增强、紧凑密度
- go_router 路由骨架：移动端底部导航，宽屏 NavigationRail
- Riverpod 状态入口：设置控制器和依赖注入示例
- shared_preferences 设置持久化
- `core`、`features`、`shared` 分层目录

## 结构

```text
lib/
  main.dart
  src/
    app/              # 应用启动与 MaterialApp
    core/             # 路由、主题、设置等基础设施
    features/         # 首页、设置、关于等功能入口
    shared/widgets/   # 可复用 UI 组件
```

## 运行

```bash
flutter pub get
flutter run
```

Windows 上使用插件时需要开启 Developer Mode，否则 Flutter 可能无法创建插件
symlink。
