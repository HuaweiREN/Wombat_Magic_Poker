# Wombat Poker 魔术扑克 App

这是一个通过**触摸滑动**或**语音指令**来“变出”扑克牌的魔术工具 App。灵感来源于 Bilibili 上一位 up 主的创意视频。

## ✨ 功能与效果

项目包含三种核心交互模式，通过 `CardSelector` 接口轻松切换：

*   **🎩 经典魔术模式 (GridSwipeCardSelector)**
    *   **核心玩法**：在待机全黑屏幕下，通过单指在特定区域点按（确定牌面数字）并滑动（确定花色），屏幕便会显示对应的扑克牌图片。
    *   **交互设计**：屏幕被分为 3x5 的虚拟网格，分别对应 A, 2-10, J, Q, K, 小王, 大王。
    *   **视觉呈现**：扑克牌以高清图片展示，适合用于魔术表演或趣味互动。

*   **🎲 随机演示模式 (RandomTapCardSelector)**
    *   **核心玩法**：点击屏幕任意位置，随机展示一张牌。长按返回待机。适用于快速演示或测试。

*   **🗣️ 语音指令模式 (VoiceCommandCardSelector)**
    *   **核心玩法**：说出“红桃5”、“黑桃A”、“大王”等指令，识别成功后**点击屏幕**，即可显示对应的扑克牌。
    *   **技术实现**：基于 `sherpa-onnx` 实现**完全离线**的语音识别，所有处理均在设备端完成，无需联网。
    *   **识别优化**：通过 `_matchRank` 和 `suits` 映射，支持对中文、英文、数字以及常见口语化表达的模糊匹配，识别更自然。

*如下为操作演示*
### 经典魔术模式
#### 直板机

#### 折叠屏

### 语音指令模式


## 📱 直接体验

如果您只想使用这个工具，无需配置任何开发环境，可以直接下载编译好的 APK 文件（适用于鸿蒙、安卓系统手机）。

> **⚠️ 注意**：下载的文件名可能以 `.apk.1` 结尾，请在手机文件管理器中将其重命名为 `.apk` 后再进行安装。

👉 **[点击此处下载最新版 APK - 经典魔术模式](https://github.com/HuaweiREN/Wombat_Magic_Poker/releases/download/v1.0.0/app-arm64-v8a-release.apk)**
👉 **[点击此处下载最新版 APK - 语音指令模式](https://github.com/HuaweiREN/Wombat_Magic_Poker/releases/download/1.1.0/Wombat_Poker_Voice_Control.apk)**

*如果您是开发者或希望进行二次开发，请继续阅读以下内容。*

## 🛠️ 开发指南

### 环境依赖
在开始之前，请确保您的开发环境已安装以下工具：
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (版本 >= 3.11.0)
*   [Android Studio](https://developer.android.com/studio) 或 [VS Code](https://code.visualstudio.com/) (用于编译和运行)
*   Git (用于版本管理)

### 快速开始
1.  **克隆本仓库**：
    ```bash
    git clone https://github.com/HuaweiREN/Wombat_Magic_Poker.git
    ```
2.  **进入项目目录**：
    ```bash
    cd Wombat_Magic_Poker
    ```
3.  **获取依赖**：
    ```bash
    flutter pub get
    ```
4.  **运行应用**：
    ```bash
    flutter run
    ```

### 核心依赖说明
以下是项目中用到的主要依赖包及其作用，方便您理解或进行二次开发：
*   `sherpa_onnx`：**核心语音识别引擎**，实现完全离线的中文语音指令解析。
*   `flutter_sound` & `permission_handler`：用于音频录制和权限处理（与语音识别模式强相关）。
*   `path_provider`：用于管理设备上的文件路径（如语音模型文件的存放）。
*   `flutter_launcher_icons`：用于自动生成不同分辨率的应用图标。
*   *(其他依赖请参考 `pubspec.yaml`)*

> **二次开发提示**：项目通过 `CardSelector` 接口将交互逻辑与UI展示解耦。您只需实现该接口，即可轻松替换或新增牌面选择方式（例如，实现一个基于摇一摇、NFC或特定手势的选择器）。

### 运行与构建
*   **在连接的真机或模拟器上运行调试版**：
    ```bash
    flutter run
    ```
*   **生成发布版 APK**：
    ```bash
    flutter build apk --release --split-per-abi
    ```
    生成的 APK 文件位于 `build/app/outputs/flutter-apk/` 目录下，您可以根据手机架构（如 `arm64-v8a`）选择安装。

## 🙏 致谢

*   **核心灵感**：本项目开发的灵感来源于 Bilibili 知名 up 主 [**barry巴里里**](https://space.bilibili.com/你的UID) 的视频创意。感谢他的精彩分享为这个项目播下了种子。原视频链接：[【BV1cjcvzpEBG】](https://www.bilibili.com/video/BV1cjcvzpEBG/)
*   **扑克牌素材**：感谢所有为本项目提供精美扑克牌图片素材的设计师与创作者。本项目使用了来自 [GitCode](https://gitcode.com/open-source-toolkit/77d38/) 的高清扑克牌资源，为应用带来了出色的视觉体验。

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE) 进行开源。您可以自由使用、修改和分发本代码，但请保留原始的版权和许可声明。