# OpenTune ARA2 集成计划

## 背景

JUCE 8.0.12 原生支持 ARA，但需要额外下载 ARA SDK 2.2.0。目标是在 OpenTune 插件中启用 ARA 支持，创建独立 CI 流程仅构建 VST3 格式。

## 目标

1. 创建独立分支 `feature/ara2-integration`
2. 下载并配置 ARA SDK 2.2.0
3. 在 CMakeLists.txt 中启用 ARA 支持
4. 创建独立的 CI 工作流，仅构建 VST3 格式
5. 每次修改后推送到远端触发 CI，逐步完成整合

## 实施步骤

### Phase 1: 分支创建与 ARA SDK 下载

#### 1.1 创建新分支
```bash
git checkout -b feature/ara2-integration
```

#### 1.2 下载 ARA SDK 2.2.0
- 递归克隆到项目根目录 `ARA_SDK/`：
  ```bash
  git clone --recursive --branch releases/2.2.0 https://github.com/Celemony/ARA_SDK.git ARA_SDK
  ```
- 将 `ARA_SDK/` 加入 `.gitignore`（不提交到仓库，CI 中单独下载）

### Phase 2: CMakeLists.txt ARA2 适配

#### 2.1 配置 ARA SDK 路径
在 `CMakeLists.txt` 中，`juce_add_subdirectory()` 之后添加：
```cmake
if(DEFINED OPENTUNE_ARA_SDK_PATH)
    juce_set_ara_sdk_path(${OPENTUNE_ARA_SDK_PATH})
endif()
```

CI 中通过 `-DOPENTUNE_ARA_SDK_PATH=${{ github.workspace }}/ARA_SDK` 传入。

#### 2.2 启用 ARA 插件支持
找到 `juce_add_plugin(OpenTune ...)` 调用，添加：
```cmake
IS_ARA_EFFECT TRUE
```

**注意**：ARA 是 VST3/AU 的扩展，必须同时启用 VST3 构建。

#### 2.3 添加编译定义
确保以下定义已启用：
```cmake
target_compile_definitions(OpenTune PRIVATE
    JUCE_PLUGINHOST_ARA=1
    # ... 其他定义保持不变
)
```

#### 2.4 实现 ARA 工厂函数
在 `PluginProcessor.cpp/h` 中：
- 继承 `juce::ARADocumentControllerSpecialisation`
- 实现 `createARAFactory()` 函数
- 参考 JUCE 的 `ARAPluginDemo` 示例

### Phase 3: 创建 ARA2 专用 CI 工作流

#### 3.1 创建 `ara2-build.yml`
文件位置：`.github/workflows/ara2-build.yml`

**触发条件**：
- 仅响应 `feature/ara2-integration` 分支的推送
- 手动触发（`workflow_dispatch`）

**构建内容**：
- 仅构建 **VST3** 格式（`-DOPENTUNE_FORMATS=VST3`）
- Windows x64 + MSVC 2022

**步骤**：
1. Checkout 代码
2. 克隆 ARA SDK：`git clone --recursive --branch releases/2.2.0 https://github.com/Celemony/ARA_SDK.git ARA_SDK`
3. 下载 ONNX Runtime（与现有 CI 相同）
4. CMake 配置：
   ```
   cmake .. -G "Visual Studio 17 2022" -A x64 
     -DOPENTUNE_FORMATS=VST3 
     -DOPENTUNE_ARA_SDK_PATH=${{ github.workspace }}/ARA_SDK
   ```
5. MSVC 构建 Release
6. 上传 VST3 artifact（保留 30 天）

**缓存策略**：
- 独立缓存键：`ara2-deps-${{ runner.os }}-onnx1.24.4`
- 缓存 ONNX Runtime
- 缓存 CMake 构建目录

#### 3.2 工作流示例（核心部分）
```yaml
name: ARA2 VST3 Build

on:
  push:
    branches: [ feature/ara2-integration ]
  workflow_dispatch:

jobs:
  build-vst3:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Clone ARA SDK
        run: git clone --recursive --branch releases/2.2.0 https://github.com/Celemony/ARA_SDK.git ARA_SDK
      
      # ... ONNX Runtime download, CMake configure/build ...
```

### Phase 4: CI 验证与迭代

#### 4.1 首次推送验证
- 推送 Phase 1-3 的更改到远端
- 触发 `ara2-build.yml` 工作流
- 检查 CI 日志：
  - ARA SDK 是否正确克隆
  - CMake 配置是否成功（`juce_set_ara_sdk_path`）
  - 编译是否通过
  - VST3 产物是否生成

#### 4.2 问题修复迭代
- 根据 CI 失败日志修复问题
- 常见预期问题：
  - ARA SDK 递归子模块缺失
  - `juce_set_ara_sdk_path` 路径错误
  - `createARAFactory()` 未实现导致链接错误
  - VST3 输出格式配置不完整
- 每次修复后推送，观察 CI 结果

#### 4.3 构建产物验证
- 下载 CI 生成的 VST3 artifact
- 本地验证插件是否可加载
- 检查 ARA 功能是否可用

### Phase 5: 文档与收尾

#### 5.1 更新文档
- 在 `README.md` 中添加 ARA2 构建说明
- 在 `AGENTS.md` / `QWEN.md` 中记录 ARA2 分支信息

#### 5.2 提交总结
- 整理所有提交信息
- 确保提交历史清晰可追溯

## 时间线与里程碑

| 阶段 | 里程碑 | 验证方式 |
|------|--------|----------|
| Phase 1 | 分支创建 + ARA SDK 下载 | `ARA_SDK/` 目录存在 |
| Phase 2 | CMakeLists.txt 适配 | 本地 CMake 配置成功 |
| Phase 3 | CI 工作流创建 | 手动触发可运行 |
| Phase 4 | CI 全绿通过 | VST3 artifact 生成 |
| Phase 5 | 文档更新 | README 可指导构建 |

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| ARA SDK 子模块克隆失败 | CI 失败 | 使用 `--recursive` 标志 |
| `juce_set_ara_sdk_path` 调用时机错误 | CMake 配置失败 | 在 `juce_add_subdirectory(JUCE)` 之后调用 |
| `createARAFactory()` 实现不完整 | 链接错误 | 参考 JUCE `ARAPluginDemo` 示例 |
| CI 构建时间过长 | 迭代慢 | 仅构建 VST3，使用缓存 |

## 关键决策

1. **继续使用 JUCE 8.0.12**：不需要替换或 fork
2. **ARA SDK 不提交到仓库**：加入 `.gitignore`，CI 中单独下载
3. **独立 CI 工作流**：不影响现有 Standalone/VST3/CLAP 构建
4. **仅构建 VST3**：ARA 是 VST3/AU 扩展，Standalone 不需要
5. **隔离分支策略**：所有 ARA 相关更改限制在 `feature/ara2-integration` 分支

## 下一步

1. 审核并批准此计划
2. 开始 Phase 1 实施
