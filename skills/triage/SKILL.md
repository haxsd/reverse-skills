---
name: triage
description: 通用文件/二进制分诊——先判定容器、架构、工具链、加壳与符号面，再选择分析路径。/ General file & binary triage — determine container, arch, toolchain, packing and symbol surface before choosing an analysis path.
---

# 分诊 / Triage

## ACTION REQUIRED（先读，再动手）

本 SKILL 在执行任何 `file`、读取、哈希、反编译或联网检索之前，必须先满足以下**硬性前置条件**，否则停在此页：

- `auth.status == granted`（已获得对目标的明确授权，并记录依据），**或**
- 已用 `offline-sample` 预设建案（脚本写入 `auth.status=granted` + `network_profile=offline` + 样本入 in_scope）。

未满足时：

1. 不做任何目标侧操作（不扫描、不连接、不触发、不上传）。
2. 只输出占位结论：`auth.status=missing → 未执行任何分析`。
3. 提示用户补齐授权或改为提供离线样本。

同时遵守：
- 禁止对未授权目标做网络探测或批量枚举。
- 禁止编写/输出规避终端防护、提权、载荷投递类内容。
- 分诊只产出**结构与证据**，不产出利用代码。

---

## 0. 证据标签（Evidence labels）

所有结论必须带标签，细则见 [`../core/evidence-labels.md`](../core/evidence-labels.md)。

| 标签 | 含义 | 必备附带信息 |
|---|---|---|
| `observed:` | 直接从产物读到的字节/字段/指令/字符串 | 文件偏移、指令地址、命令输出片段 |
| `inferred:` | 由 observed 推导 | 推导链（依据哪几条 observed） |
| `proposed:` | 我们提出的命名/假设，非产物自带 | 明确标注“非目标内建” |
| `web:` | 来自外部检索 | URL + 置信度（高/中/低） |

规则：
- `inferred:` 不得单独成结论，必须能回指到 `observed:`。
- 本地证据与 `web:` 冲突时，以本地为准，冲突保留在报告里。
- 无法证实的字段写 `TBD (unverified)`，不要猜。

---

## 1. 决策树（container → arch → toolchain → packing → symbols → entry → hypotheses）

按顺序推进，**上一层没定就不跳层**，避免工具链误判导致后续全部错误。

### 1.1 container（容器/文件类型）
- 读 magic（前 4–64 字节）+ `file` 结果。
- 常见：ELF / PE / Mach-O (+fat) / `.class` / DEX / WASM / ASAR / zip 类归档 / pyc / PyInstaller 包。
- 归档/容器（zip、jar、apk、asar、ipa）→ **先解包到工作目录**，再对内部成员递归分诊。
- 脚本（`#!`）→ 直接读源码，不走二进制路径。

> 出口条件：容器类型 + 内部成员清单已记录（`observed:`）。

### 1.2 arch（架构与字节序）
- 从头部字段取：ELF `e_machine`/`EI_DATA`；PE `Machine`；Mach-O `cputype`/`cpusubtype`。
- 托管/字节码（MSIL、JVM、WASM）单列，架构记为运行时。
- 记录：位宽（32/64）、端序、指令集。

> 出口条件：`Arch:` 字段可填，且与容器自洽。

### 1.3 toolchain（工具链/运行时）
- 找编译器指纹：栈保护符号、CFI 标记、异常/panic 机制、mangling 风格、构建元数据段（`.comment`、buildinfo、PDB 路径、版本串）。
- 判运行时：libc 版本、托管运行时版本、解释器版本。
- 只做**家族级**判定（GCC/Clang/MSVC/Rust/Go/…），版本号能取则取，取不到写 `TBD`。

> 出口条件：`Toolchain:` 与 `Runtime:` 有值或明确 `TBD (unverified)`。

### 1.4 packing（加壳/混淆状态）
- 依据：分段熵分布、段名异常、导入表贫瘠、代码段过小、入口 stub 形态、可写可执行段。
- 区分三态：`none` / `packed`（壳）/ `obfuscated in-place`（原地混淆：控制流平坦化、字符串加密、不透明谓词）。
- 只**判定状态并记录证据**，不在此阶段做脱壳或去混淆；脱壳策略留给后续 SKILL。

> 出口条件：`Packing:` 与 `Obfuscation:` 有值，并附熵表/段名证据。

### 1.5 symbols（符号与导入/导出面）
- 导出、导入、动态解析点、RTTI/vtable 线索、残留调试符号、字符串分组。
- 记录数量与代表性条目（各取几条即可，不铺全量）。

> 出口条件：`Symbols:`（full / partial / stripped）+ `Surface:` 计数。

### 1.6 entry（入口与初始化）
- 取程序入口、初始化数组/构造器、TLS 回调、模块初始化函数。
- 注意：加壳样本的入口常指向壳 stub，真正 main 在解包后才可达——标注“入口可疑”。

> 出口条件：`Entry:` 有地址，并注明初始化/TLS 是否存在。

### 1.7 hypotheses（首选假设）
- 基于以上六层，给 2–3 条“这个程序大概做什么”的可证伪假设。
- 每条假设写明：支撑证据（observed）、验证方式（下一步看什么）。

> 出口条件：分诊模板填满，方可进入深度分析阶段。

---

## 2. 缺工具时的诚实降级（honest degrade）

**原则：工具缺失不是编造结论的理由。** 先探测，再决定降级路径。

### 2.1 探测可用性

bash：
```bash
command -v file xxd sha256sum strings readelf objdump nm 2>/dev/null
```

PowerShell：
```powershell
Get-Command file,Format-Hex,Get-FileHash,strings,objdump -ErrorAction SilentlyContinue |
  Select-Object Name,Source
```

### 2.2 降级矩阵

| 缺失工具 | 降级方案 | 标注要求 |
|---|---|---|
| `file` | 用 `xxd`/`Format-Hex` 读 magic，人工比对已知魔数表 | `inferred:` + 魔数字节 |
| `sha256sum` | `shasum -a 256` / `openssl dgst -sha256` / `Get-FileHash -Algorithm SHA256` | 注明所用命令 |
| `strings` | `grep -a` 抓可打印串 / 自写小脚本 / PowerShell 正则提取 | 注明替代方法与最小长度阈值 |
| `readelf`/`objdump` | 手工解析头部字段，或改用脚本读取 | `inferred:`，并说明字段偏移 |
| 全部工具缺失 | 只输出 magic + 大小 + 哈希（若可算），其余写 `TBD (blocked: <tool>)` | 明确写阻塞原因 |

禁止：用“看起来像”替代实测；用记忆中的格式细节冒充 `observed:`。

---

## 3. 基础命令对（bash / pwsh）

### 3.1 file（类型与摘要）

bash：
```bash
file -k "$T"; stat -c '%s bytes' "$T"
```

pwsh：
```powershell
Get-Item $T | Select-Object FullName,Length,LastWriteTime
Format-Hex -Path $T -Count 64
```

### 3.2 hash（完整性指纹）

bash：
```bash
sha256sum "$T"; md5sum "$T"
```

pwsh：
```powershell
Get-FileHash -Path $T -Algorithm SHA256
Get-FileHash -Path $T -Algorithm MD5
```

> 记录哈希用于：样本去重、跨会话引用、报告中复现。`observed:` 需附完整哈希值。

### 3.3 strings（字符串面）

bash：
```bash
strings -n 6 "$T" | head -200
strings -n 6 -e l "$T" | head -100     # 16-bit LE，Windows 常见
```

pwsh：
```powershell
# 无 strings 时的等价提取（最小长度 6 的可打印 ASCII 串）
$bytes = [IO.File]::ReadAllBytes($T)
$sb = New-Object Text.StringBuilder
$out = New-Object Collections.Generic.List[string]
foreach ($b in $bytes) {
  if ($b -ge 32 -and $b -lt 127) { [void]$sb.Append([char]$b) }
  else { if ($sb.Length -ge 6) { $out.Add($sb.ToString()) }; [void]$sb.Clear() }
}
if ($sb.Length -ge 6) { $out.Add($sb.ToString()) }
$out | Select-Object -First 200
```

字符串分组建议（供 hypotheses 使用）：路径、URL/域名、协议关键字、错误/日志模板、资源名、许可/版本标记。

---

## 4. 分诊输出模板（Triage output template）

分析开始前必须产出此表；未填满不得进入深度阶段。

```
Auth:         granted / offline-sample        (授权方/文书号：…)
Container:    ELF64 / PE64 / Mach-O / Jar / .NET / ASAR / pyc / WASM / other
Arch:         x86_64 / ARM64 / MIPS / RISC-V / MSIL / JVM / WASM
Toolchain:    <family + version 或 TBD (unverified)>
Runtime:      <libc / .NET / Node / Android 版本 或 TBD>
Packing:      none / packed / obfuscated-in-place     (熵表：…)
Obfuscation:  none / 平坦化 / 字符串加密 / 反调试      [observed|inferred]
Symbols:      full / partial / stripped               (残留：…)
Entry:        0x…                                     (init/TLS：有/无)
Surface:      <N> exports, <N> imports, <M> notable strings
First hypotheses:
  - H1: …（依据 observed: …；验证方式：…）
  - H2: …（依据 observed: …；验证方式：…）
  - H3: …（可选）
Blocked:      <缺失工具或不可读区域，写 TBD (blocked: …)>
```

填写约束：
- 每一行若为推断，追加 `inferred:` 及推导链。
- 外部检索补充的信息追加 `web:` + URL + 置信度。
- 新增的命名一律标 `proposed:`。

---

## 5. 与相邻 SKILL 的衔接

- 证据标签定义：[`../core/evidence-labels.md`](../core/evidence-labels.md)
- 本 SKILL 只输出“是什么”，**不输出**脱壳步骤、补丁字节、利用路径。
- 分诊表完成后，按 `Packing` / `Toolchain` 字段选择后续路径；选择理由写进报告。

---

## 归属说明 / Attribution

本 SKILL 的方法论结构参考并改写了 PyModel 项目的分诊流程，该项目以 MIT 许可证发布；本文件为改写版本，未逐字复制原文。完整归属与许可证信息见仓库根目录 [`ATTRIBUTION.md`](../../ATTRIBUTION.md)。
