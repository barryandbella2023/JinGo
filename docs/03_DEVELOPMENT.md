# JinGo VPN - 开发指南

## 开发环境

### 推荐 IDE

**Qt Creator** (推荐) - 提供最佳的 Qt/QML 开发体验

### Qt Creator 配置

1. 打开项目: `File → Open File or Project → CMakeLists.txt`
2. 选择 Kit:
   - Android: Android Qt 6.x Clang arm64-v8a
   - macOS: Desktop Qt 6.x clang 64bit
   - iOS: iOS Qt 6.x
   - Linux: Desktop Qt 6.x GCC 64bit

## 项目结构

```
JinGo/
├── src/
│   ├── main.cpp              # 应用入口
│   └── platform/             # 平台特定代码
├── qml/
│   ├── Main.qml              # 主界面
│   ├── pages/                # 页面
│   │   ├── HomePage.qml
│   │   ├── ServerListPage.qml
│   │   ├── SettingsPage.qml
│   │   └── ProfilePage.qml
│   └── components/           # 组件
│       ├── ServerItem.qml
│       ├── ConnectionButton.qml
│       └── ...
├── resources/
│   ├── icons/                # 图标
│   └── translations/         # 翻译文件
└── third_party/              # 预编译依赖库
```

## QML 开发

### QML 与 C++ 交互

核心类通过 `main.cpp` 注册到 QML 上下文：

```cpp
// main.cpp
rootContext->setContextProperty("vpnManager", &VPNManager::instance());
rootContext->setContextProperty("authManager", &AuthManager::instance());
```

### 在 QML 中使用

```qml
// HomePage.qml
import QtQuick

Item {
    Connections {
        target: vpnManager

        function onConnected() {
            console.log("VPN 已连接")
        }
    }

    Button {
        text: vpnManager.isConnected ? "断开" : "连接"
        onClicked: {
            if (vpnManager.isConnected) {
                vpnManager.disconnect()
            } else {
                vpnManager.connect()
            }
        }
    }
}
```

### 常用 QML 属性

```qml
// VPNManager
vpnManager.isConnected       // bool: 是否已连接
vpnManager.state             // enum: 连接状态
vpnManager.currentServer     // Server: 当前服务器
vpnManager.uploadSpeed       // qint64: 上传速度
vpnManager.downloadSpeed     // qint64: 下载速度

// AuthManager
authManager.isAuthenticated  // bool: 是否已登录
authManager.currentUser      // User: 当前用户
```

## 多语言支持

### 添加新翻译

1. 在 QML 中使用 `qsTr()` 包裹文本：
```qml
Text {
    text: qsTr("Connect")
}
```

2. 生成/更新翻译文件：
```bash
lupdate qml/ -ts resources/translations/jingo_new_LANG.ts
```

3. 使用 Qt Linguist 翻译

4. 编译翻译：
```bash
lrelease resources/translations/*.ts
```

## 调试

### 启用详细日志

```bash
# Linux/macOS
QT_LOGGING_RULES="*.debug=true" ./JinGo

# Android
adb logcat -s JinGo:V
```

### QML 调试

```qml
console.log("变量值:", someVariable)
console.warn("警告信息")
console.error("错误信息")
```

### Android 远程调试

```bash
# 查看日志
adb logcat | grep -E "JinGo|SuperRay|Qt"

# 部署并运行
./scripts/build/build-android.sh --debug --install
```

## 代码风格

### C++ 风格

```cpp
// 类名: PascalCase
class VPNManager {
public:
    // 方法名: camelCase
    void connectToServer(const Server& server);

    // 成员变量: m_ 前缀
    QString m_serverAddress;
};
```

### QML 风格

```qml
// 文件名: PascalCase.qml
Item {
    id: root

    // 属性声明在前
    property string title: ""

    // 信号声明
    signal clicked()

    // 子组件
    Rectangle { id: background }

    // 函数在后
    function doSomething() { }
}
```

## 常见开发任务

### 添加新页面

1. 创建 QML 文件: `qml/pages/NewPage.qml`
2. 在 `CMakeLists.txt` 添加到 QML 模块
3. 在 `Main.qml` 添加导航

### 添加新设置项

1. 在 `SettingsPage.qml` 添加 UI 控件
2. 绑定到 ConfigManager 属性

## 发布检查清单

- [ ] 更新版本号 (CMakeLists.txt)
- [ ] 更新翻译
- [ ] Release 模式编译
- [ ] 测试所有平台

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [架构说明](01_ARCHITECTURE.md)
