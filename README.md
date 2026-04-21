<div align="center">

## OpenTune – AI 智能修音软件
<img width="512" alt="1" src="https://github.com/user-attachments/assets/5f018b53-e78c-4eec-a2da-e71b0724bc9b" />


保留共振峰，移调不失真


OpenTune 是一款基于神经声码器的开源修音工具。与传统 DSP 算法直接移调不同，它使用 NSF-HiFiGAN 声码器在保留原始共振峰的前提下重新生成人声，即使进行极端音高调整，也能保持自然、扎实的音质。

</div>

<div align="center">

## ✨ 亮点特性

<img width="512" alt="2" src="https://github.com/user-attachments/assets/55f7136e-fc8b-4576-af0b-2cbeea3c2f6e" />




共振峰不变：改变音高时不影响声音的底色，告别"鸭子叫"或"换人唱"的失真感


大范围移调：支持夸张的音高修正与转调，音质依然清晰稳定


AI 重合成：基于深度学习的声码器，而非传统移调




<img width="512" alt="3" src="https://github.com/user-attachments/assets/d99c088a-46f6-4177-a761-0af737416b41" />




类Auto-Tune工作流：手绘、音符、锚点工具一应俱全，助你快速进入心流状态



<img width="512" alt="4" src="https://github.com/user-attachments/assets/c95636d1-2eb8-4cad-8c2c-61b208adb961" />




内置类Auto-Key自动检测调式：上手即修，不修也准，修了更准



开源免费：永久免费，社区驱动，持续迭代



</div>



## 🖥️ 当前状态
平台：Windows（Standalone 独立运行版本）

即将推出：VST3 插件、ARA2 支持（可直接在 DAW 中运行）

性能提示：目前 CPU/内存有一定占用，建议配备独立显卡以获得更流畅体验


## 🧪 测试版说明
这是早期测试版本，可能存在少量 bug，性能也尚未完全优化。欢迎下载试用，并通过 Issues 或 Discussion 提出宝贵意见、功能需求或使用中遇到的问题。我们会根据反馈积极改进。


## 🧠 项目理念
AI 的存在是为了帮助人，以人为本，带来更好的创作体验。

在 AI 已经深度介入音乐制作的今天，混音和音频编辑却仍常受限于录音质量，耗费大量时间。OpenTune 希望通过开放的技术，让每一位创作者都能更自由地处理人声，把精力放回音乐本身。


## 🙏 鸣谢
特别感谢 DiffSinger 开源社区及所有贡献者。正是他们在神经声码器与歌声合成领域的持续探索，才为传统音乐制作带来了这份礼物。


## 📥 下载与使用
请前往 Releases 页面下载最新 Windows 独立运行包。
解压后直接运行 .exe 文件，加载音频并设置目标音高即可开始处理。


## 🛠️ 构建说明

### 环境要求

- **CMake** 3.22+
- **C++17 编译器**（Windows 推荐 MSVC 2022）
- **Visual Studio 2022**（带"使用 C++ 的桌面开发"工作负载）
- **PowerShell 7+**（用于初始化脚本）
- **Git**（用于拉取代码）

### 快速开始（推荐）

使用一键初始化脚本自动下载并配置所有依赖：

```powershell
# 克隆仓库
git clone https://github.com/drunkenQCat/OpenTune.git
cd OpenTune

# 运行初始化脚本（自动下载 JUCE、ASIO SDK、ONNX Runtime）
.\scripts\init-dev.ps1

# 构建项目
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64 -DOPENTUNE_FORMATS=Standalone
cmake --build . --config Release
```

构建完成后，可执行文件位于：
```
build/OpenTune_artefacts/Release/Standalone/OpenTune.exe
```

### 手动配置依赖

如果不想使用初始化脚本，也可以手动下载以下依赖：

| 依赖 | 版本 | 下载地址 |
|------|------|----------|
| **JUCE 框架** | 8.0.12 | https://github.com/juce-framework/JUCE/archive/refs/tags/8.0.12.zip |
| **ASIO SDK** | latest | https://github.com/audiosdk/asio |
| **ONNX Runtime CPU** | 1.24.4 | https://github.com/microsoft/onnxruntime/releases/download/v1.24.4/onnxruntime-win-x64-1.24.4.zip |
| **ONNX Runtime DirectML** | 1.24.4 | https://api.nuget.org/v3-flatcontainer/microsoft.ml.onnxruntime.directml/1.24.4/microsoft.ml.onnxruntime.directml.1.24.4.nupkg |

下载后按以下结构放置：

```
OpenTune/
├── JUCE-master/                    # JUCE 框架
├── onnxruntime-win-x64-1.24.4/    # ONNX Runtime CPU
├── onnxruntime-dml-1.24.4/        # ONNX Runtime DirectML (NuGet 包解压)
├── JUCE-master\modules\juce_audio_devices\native\asio\  # ASIO SDK 头文件
├── models/                         # AI 模型文件（Git LFS）
└── pc_nsf_hifigan_44.1k_ONNX/     # 声码器模型
```

### CI/CD 构建

项目使用 GitHub Actions 进行持续集成：

- **`publish` 分支**：完整构建（Standalone + VST3 + CLAP），自动发布 Release
- **`dev` 分支**：仅构建 Standalone，用于日常开发测试

开发者可以通过以下方式获取最新构建产物：

1. 访问 [Actions](https://github.com/drunkenQCat/OpenTune/actions) 页面
2. 点击最新的运行记录
3. 下载 Artifacts（`OpenTune-standalone-exe` 仅包含 exe 文件，适合增量更新）


## 🤝 参与贡献
欢迎提交 PR、翻译文档、报告 bug 或提出新功能建议。让我们一起把 OpenTune 打磨得更好。


## 🙏 致谢

- **[OpenVPI 团队 / Diffsinger 社区声码器](https://github.com/openvpi/vocoders)** - 高质量的声码器实现，本项目的核心部分。
- **[yxlllc / RMVPE](https://github.com/yxlllc/RMVPE)** - 使用了大佬训练的 RMVPE 权重，显著提升了音高提取的准确性与鲁棒性。
- **[吃土大佬 (CNChTu) / FCPE](https://github.com/CNChTu/FCPE)** - 参考了 FCPE ，可能后续会尝试实装。
- **[JUCE 框架](https://github.com/juce-framework/JUCE)** - 
- **[avaneev / r8brain-free-src](https://github.com/avaneev/r8brain-free-src)** - 高效的重采样算法。
各项目均遵循其自身的开源许可协议。
感谢以上项目作者与团队的开放共享精神，他们的工作让本项目的实现成为可能。


## License
AGPL v3.0

