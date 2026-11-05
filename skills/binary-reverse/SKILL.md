---
name: binary-reverse
description: 授权范围内的通用 ELF/PE/Mach-O 深度逆向：格式确认后的字符串/导入面、反汇编工具选择与缺工具诚实降级。Use after triage for deep native binary analysis with radare2/rizin/ghidra/IDA when present — not exploits or unauthorized targets.
---

# 通用二进制深度逆向（ELF / PE / Mach-O）

## ACTION REQUIRED

1. 确认 `work/<case>/scope.md`：`auth.status=granted`（本地样本可用 `offline-sample`）。
2. **先完成或复核 `triage`**：容器、架构、加壳/混淆态、符号面未定时，不要跳进反编译。
3. 对样本算哈希并记录（`observed:`）。
4. 按 Phase 0→5 推进；产物落到 `work/<case>/binary/`。
5. 工具链按「有什么用什么」；缺失则诚实降级，不编造伪代码。
6. 动态调试 / 仿真执行另需明确授权；默认静态。

契约见 `../core/phase-contracts.json`。证据标签见 `../core/evidence-labels.md`。授权总则见仓根 `RULES.md` / `RULES_zh.md`。

## 授权边界

| 动作 | 要求 |
|---|---|
| 本地静态：读头、strings、导入导出、反汇编/反编译 | `granted` + 通常 `offline` |
| 调试器附加、用户态仿真、对远程主机投递 | `granted` + 明确网络/调试档 + in_scope |
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

写入 `step0/format.md`（可粘贴 triage 摘要 + 哈希）。

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
| .NET/PE 当原生深挖 | 转托管工具链（本模块仅点到为止） |

## 与其它模块

- 入口：`triage` → 本模块；Android 包 → `android-apk`；JS/bundle → `js-reverse`。
- APK 内 `.so`：Java 面在 `android-apk`，原生库可对本模块对单个 `.so` 建子案或同案 `binary/` 子目录。
