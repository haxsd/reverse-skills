---
name: binary-reverse
description: 授权范围内的通用 ELF/PE/Mach-O 深度逆向：格式确认后的字符串/导入面、反汇编工具选择与缺工具诚实降级。Use after triage for deep native binary analysis with radare2/rizin/ghidra/IDA when present — not exploits or unauthorized targets.
---

# 通用二进制深度逆向（ELF / PE / Mach-O）

## ACTION REQUIRED

1. 确认 `work/<case>/scope.md`：`auth.status=granted`（本地样本可用 `offline-sample`）。获准检查这份二进制，不等于获准运行它、抓流量、附加调试器或触碰设备/账号。
2. 若手头已有同一软件的**完整源码仓**，且问题不是针对这份发运产物，先读源码，不要一上来走本模块。
3. **先完成或复核 `triage`**：容器、架构、加壳/混淆态、符号面，以及打包运行时的**真正应用层**未定时，不要跳进反编译。
4. 对样本算哈希并记录（`observed:`）。
5. 按 Phase 0→5 推进；产物落到 `work/<case>/binary/`。
6. 工具链按「有什么用什么」；缺失则诚实降级，不编造伪代码。
7. 动态调试 / 仿真执行另需明确授权；默认静态。静态阅读不能写成「已观察到执行」。

契约见 `../core/phase-contracts.json`。证据标签见 `../core/evidence-labels.md`。授权总则见仓根 `RULES.md` / `RULES_zh.md`。

## 授权边界

| 动作 | 要求 |
|---|---|
| 本地静态：读头、strings、导入导出、反汇编/反编译、只读查看打包归档 | `granted` + 通常 `offline` |
| 调试器附加、用户态仿真、运行样本、抓流量、对远程主机投递 | `granted` + 明确网络/调试档 + `in_scope.activities` 写明对应动作 |
| 未授权目标上的利用编写、提权、防护绕过 | **禁止** |

本模块是**分析剧本**，不是 exploit 手册；不收 EDR 绕过或 payload 模块。

## 输出布局

```text
work/<case>/binary/
  step0/format.md
  step1/surface.md
  step2/tool_choice.md
  step3/disasm_notes.md
  step4/semantics.md
  step5/report.md
  _logs/
```

## Phase 0 — 格式确认（承接 triage）

若尚无 triage 产物，先跑 `skills/triage/` 的决策树。本阶段只**固化**格式结论：

| 格式 | Magic / 信号 | 记录字段 |
|---|---|---|
| ELF | `7F 45 4C 46` | class、endian、`e_machine`、ET_REL/EXEC/DYN |
| PE | `MZ` + PE 签名 | Machine、子系统、.NET（`BSJB`）否 |
| Mach-O | `CF FA ED FE` 等 / Fat `CA FE BA BE` | cputype、是否 universal（先拆 slice） |
| 其它 | DEX/WASM/归档… | **不要**硬走本模块；回 triage 或对应领域 |

加壳态为 `packed`：本模块先做表面与入口 stub 记录，脱壳策略单列；未脱壳前的「业务伪代码」标 `proposed:` 且置信度低。

### 0.1 打包运行时：不要对着外壳做业务分析

若 triage 已标出打包形态，先确认应用层，再决定是否继续在本模块做原生深度。

| 形态 | 不要当成产品代码的部分 | 应该分析的部分 | 注意 |
|---|---|---|---|
| PyInstaller | 引导程序（原生前缀） | **CArchive** 及其中的 PYZ/字节码与资源 | 抽出后对内部成员重新分诊；Python 字节码不是本模块的原生深度对象 |
| Bun `--compile` | Bun 运行时前缀 | 嵌入的**模块图**（JS） | 抽出后转 `js-reverse` |
| Deno `compile` | Deno 运行时前缀 | 嵌入的**虚拟文件系统** | 抽出后对其中的 JS 转 `js-reverse`。不要靠擅自运行可执行文件来导出文件树 |
| .NET NativeAOT | 「按普通托管程序集打开」这条路 | 映像里的**原生机器码** | 普通 CIL 反编译器还原不了方法体；元数据恢复有限，还原的类型/伪代码不是原始 C# 源码。按本模块原生路径推进 |
| Go 二进制 | — | 仍是这份原生映像 | 先读 buildinfo / 模块元数据（有 `go` 可用 `go version -m`）。**元数据缺失不能证明它不是 Go**，只能记「未观察到 buildinfo」。随后按常规原生分析 |

写入 `step0/format.md`（可粘贴 triage 摘要 + 哈希 + App layer）。

## Phase 1 — 字符串与导入/导出面

目标：用低成本表面约束后续反汇编范围。

```bash
# 按平台选用存在的工具；没有就跳过并标注
file "$BIN"
sha256sum "$BIN"    # macOS: shasum -a 256
strings -n 6 "$BIN" | head -200
# ELF
readelf -hWs "$BIN" 2>/dev/null | head -100
# 通用
objdump -T "$BIN" 2>/dev/null | head -80
llvm-nm -g "$BIN" 2>/dev/null | head -80
```

```powershell
Get-FileHash $env:BIN -Algorithm SHA256
# strings / dumpbin / llvm-nm 若在 PATH 则用；否则注明缺失
```

整理：

- 有趣字符串分组：URL、路径、错误信息、协议关键字、许可证/版本（`observed:`）。
- 导入面：加密、网络、文件、进程相关 API 各举代表项（不刷全表）。
- 导出面与可见符号：`full` / `partial` / `stripped`。
- 动态解析点线索：`dlsym` / `GetProcAddress` / 手写 hash 解析（只记录位置假设）。

写入 `step1/surface.md`。

## Phase 2 — 反汇编 / 反编译工具选择

**原则：平台只改命令，不改分析顺序。有什么用什么；没有就降级。**

| 优先级 | 工具 | 适合 | 探测 |
|---|---|---|---|
| 1 | `r2` / `rizin`（或 `rz-bin`） | 快速静态、脚本化 | `command -v r2 rizin` |
| 2 | `ghidra`（headless 若可用） | 反编译伪 C、交叉引用 | `command -v ghidra ghidraRun analyzeHeadless` |
| 3 | `ida` / `idat`（若已授权安装） | 深度交互/已有 IDB | `command -v ida idat ida64` |
| 4 | `objdump` / `llvm-objdump` | 最小反汇编 | 几乎总有其一 |
| 5 | 仅 `xxd` + 手册解码 | 最后手段 | 说明无法产出可靠伪 C |

选择记录到 `step2/tool_choice.md`：选中工具、版本、**未选原因**（缺失/过重）。

### 诚实降级矩阵

| 缺失 | 可做 | 不可做 |
|---|---|---|
| 无 r2/ghidra/ida | `objdump -d` 入口附近 + strings/导入结论 | 声称「完整反编译」 |
| 无任何反汇编器 | 头字段 + strings + 导入（若可读） | 编造指令序列 |
| 仅有 GUI 无 headless | 说明需人工在 GUI 完成的步骤清单 | 假装已在 CI 里跑完 |

## Phase 3 — 反汇编工作流

1. 定位真实入口（注意 TLS / `init_array` / 壳 stub）。
2. 从入口与导入敏感点建 xref 候选列表（网络、加解密、配置加载）。
3. 对短名单函数反编译/反汇编；交叉验证：伪 C 与原始指令不一致时以指令为准（`observed:`）。
4. 命名：产物自带符号用原名；恢复名标 `proposed:`。
5. 发现明显加壳/VM 保护：停深度业务推断，回到表面证据与「需脱壳」阻塞项。

写入 `step3/disasm_notes.md`（命令、地址、关键片段）。

## Phase 4 — 语义假设（可证伪）

给出 2–4 条「程序在做什么」的假设，每条包含：

- 支撑 `observed:`（字符串/导入/指令址）
- 验证方式（看哪条路径、对比哪次运行——若允许动态）
- 当前标签：`inferred:` 或 `proposed:`

不做：利用链编写、未授权目标的 PoC、防护绕过步骤。

写入 `step4/semantics.md`。

## Phase 5 — 报告

`step5/report.md` 最少包含：格式与架构、工具与降级说明、表面摘要、已确认行为、未决 `TBD`、授权引用。结论全部带证据标签。

## 常见坑

| 坑 | 正确做法 |
|---|---|
| 跳过 triage 直接 Ghidra | 先固化格式/加壳态 |
| 单工具伪 C 当真理 | 与原始反汇编对读 |
| 壳样本当已还原业务 | 标明 stub / 需脱壳 |
| 缺工具仍输出完整算法 | 降级 + `TBD` |
| Fat Mach-O 未拆 slice | 先选对架构切片 |
| .NET/PE 当原生深挖 | 先区分普通托管程序集与 NativeAOT；前者转托管工具链，后者按原生路径并写明元数据限制 |
| 把 PyInstaller/Bun/Deno 的运行时前缀当成产品 | 先回到应用层（CArchive / 模块图 / 嵌入式虚拟文件系统） |
| 没看到 Go buildinfo 就断言「不是 Go」 | 记「未观察到元数据」，不能当成否定证明 |
| 把静态反编译写成已观察到的运行行为 | 运行/附加须另有授权，并单独取证 |

## 与其它模块

- 入口：`triage` → 本模块；Android 包 → `android-apk`；JS/bundle、Electron/ASAR、以及从 Bun/Deno 抽出的 JS → `js-reverse`。
- APK 内 `.so`：Java 面在 `android-apk`，原生库可对本模块对单个 `.so` 建子案或同案 `binary/` 子目录。
- 大任务维护 `work/<case>/questions.md`；有界检索的否定结论不得写成「不存在」。

## 归属说明 / Attribution

「先找真正应用层」、Go 元数据缺失不能直接否定、NativeAOT 按原生分析且元数据有限等思路，改写自 morluto/rea（MIT，钉住提交见 [`ATTRIBUTION.md`](../../ATTRIBUTION.md)）。本文件为改写，不绑定其工具名。
