---
name: js-reverse
description: 授权范围内的前端/Node JS 逆向：混淆分档、静态美化与 AST、动态 Hook 边界、签名与加密参数定位决策树。Use for authorized JS deobfuscation, signing/crypto-param recovery, and webpack/bundle analysis — not unauthorized bypass or payload dumps.
---

# JS 逆向（解混淆 / 签名与参数链）

## ACTION REQUIRED

1. 确认 `work/<case>/scope.md`：`auth.status=granted`（本地样本可用 `offline-sample`）。
2. 对输入脚本/bundle 算哈希并记录（`observed:`）。
3. **Phase 0 分档**：判定混淆层级与输入形态，再选静态或动态路径。
4. 校验工具：`node` 建议；美化/AST 工具按表探测。缺失则诚实降级，不编造还原结果。
5. 按 Phase 1→5 推进；产物落到 `work/<case>/js/`。
6. 浏览器 Hook / 对真实站点采样另需明确授权与 `network_profile`；默认优先离线静态。

契约见 `../core/phase-contracts.json`。证据标签见 `../core/evidence-labels.md`。授权总则见仓根 `RULES.md` / `RULES_zh.md`。

## 授权边界

| 动作 | 要求 |
|---|---|
| 本地读脚本、美化、AST 变换、字符串数组还原、bundle 拆分 | `granted` + 通常 `offline` |
| 对授权目标页做 DevTools/CDP 观察、最小化 Hook、抓发起链 | `granted` + 非 offline 的明确网络档 + in_scope 覆盖 |
| 对未授权站点批量探测、绕过风控/登录、投递利用载荷 | **禁止** |

本模块产出**决策树与证据化步骤**，不提供 payload 字典、未授权绕过脚本或 EDR 规避。

## 输出布局

```text
work/<case>/js/
  step0/tier.md
  step1/deps.md
  step2/static_notes.md
  step3/ast_notes.md
  step4/dynamic_boundary.md
  step5/param_chain.md
  step5/report.md
  _logs/
```

## Phase 0 — 混淆分档与输入形态

先判定「拿的是什么」和「乱到什么程度」，再选工具。

### 0.1 输入形态

| 形态 | 线索（`observed:`） | 下一步 |
|---|---|---|
| 单文件混淆脚本 | `_0x` 标识、大字符串数组 + decoder、packer `eval(function(p,a,c,k…))` | 静态美化 → AST |
| Webpack/Browserify/Rollup bundle | `webpackJsonp` / `__webpack_modules__` / sourceMappingURL | 拆模块后再逐个处理 |
| 压缩但未混淆 | 单行、短名，但控制流可读 | 美化即可，勿过度 AST |
| Sourcemap 可用 | `.map` 旁路或 `sourceMappingURL` | **优先**还原源；再谈去混淆 |
| JSVMP / 自定义字节码 | 大 switch 分发、opcode 表、解释器循环 | STOP 本流水线深度；记录证据，另开 VMP 轨道（本批不深挖） |
| 页面内联 + 多 chunk | HTML 引用多个 script | 先建依赖图，再定主链 |

### 0.2 混淆层级（由浅到深）

| 档 | 特征 | 首选策略 |
|---|---|---|
| L0 仅 minify | 空白压缩、短名 | beautify |
| L1 字符串数组 / 常量折叠 | 数组 + rotator/decoder、常量表达式 | AST：解数组、折常量 |
| L2 控制流平坦化 | dispatcher 状态机、大量 `while/switch` | AST deflatten；失败再考虑动态采样 |
| L3 编码串 + 反调试 | base64/RC4 类 decoder、debugger 陷阱 | **仅**在隔离沙箱跑 decoder 片段；整程序不瞎跑 |
| L4 虚拟机化 | 自研 opcode | 本模块只做识别与边界说明 |

写入 `step0/tier.md`：形态、档位、证据片段（命令输出或文件:行）。

## Phase 1 — 依赖

建议：`node`（≥18）、文本美化（如 `js-beautify` / prettier，有则用）、AST 去混淆（如 webcrack / 等价工具，有则用）。可选：`sourcemap` CLI。

```bash
command -v node && node --version
command -v js-beautify; command -v prettier
command -v npx
```

```powershell
Get-Command node, npx, js-beautify, prettier -ErrorAction SilentlyContinue
```

缺失 `node`：只能做文本级阅读与手工标注，**不要**声称已 AST 还原。写入 `step1/deps.md`。

## Phase 2 — 静态美化与表面整理

1. 复制样本到工作区，保留原件哈希。
2. 美化缩进与基础结构（不改变语义）。
3. 提取：URL、路径、`crypto`/`SubtleCrypto`、明显的 `sign`/`token`/`nonce` 标识符、XHR/fetch 封装名。
4. 若存在 sourcemap：优先映射回源文件树，后续在源上分析。

记录命令与产物路径到 `step2/static_notes.md`。

## Phase 3 — AST 决策树

按档推进，**能浅则不深**：

```text
L0 → 停在美化
L1 → 解字符串数组 / 常量折叠 → 再读业务
L2 → 在 L1 后尝试控制流还原
L3 → 仅沙箱执行 decoder；记录沙箱约束；禁止无隔离整包 eval
L4 → 识别后 STOP，列证据，不假装已还原
```

原则：

- 变换前后做抽样 diff / 关键字符串对照（`observed:`）。
- 工具缺失 → 手工标出 decoder/dispatcher 位置，标 `TBD (tool-missing)`，不编造明文。
- 不把「看起来像签名」写成已还原算法，除非有输入输出对照（`observed:` 样例）。

写入 `step3/ast_notes.md`。

## Phase 4 — 动态 Hook 边界（可选）

仅当静态不足以定位参数链，且 scope 允许对目标页观察时：

| 允许（需授权） | 不允许 |
|---|---|
| 观察网络发起栈、只读打印函数入参/返回值、断在已知 XHR 包装器 | 未授权撞库、绕过验证码/登录、批量刷接口、投递利用代码 |
| 在**用户自有**或书面授权环境用 CDP/DevTools | 对第三方生产用户会话做持久化劫持 |

顺序建议：**Observe（找请求与 initiator）→ 最小 Capture（单次采样）→ 回静态验证**。Breakpoint 作最后手段。动态结论必须能在静态文件中回指位置。

写入 `step4/dynamic_boundary.md`（含授权引用与是否执行）。

## Phase 5 — 签名 / 加密参数链

目标：画出「哪些字段、在哪个函数、用什么材料、以何顺序拼出」——**证据化**，不是猜。

1. 从目标请求字段名反查脚本引用（`observed:` 文件:行）。
2. 向上追调用者，直到稳定的「组参函数」。
3. 区分：时间戳/nonce、设备或会话材料、HMAC/摘要、自定义拼串。
4. 每条假设写验证方式（改输入看输出 / 对照两次抓包）；未验证标 `proposed:`。
5. 本地复现（若需要）必须基于已观测 API 与材料，禁止空想补全 `window`/`document` 后宣称一致。

交付 `step5/param_chain.md` + `step5/report.md`（结论全部带标签）。

## 常见坑

| 坑 | 正确做法 |
|---|---|
| 一上来整包 `eval` / 无沙箱跑混淆器 | 先分档；decoder 才考虑隔离执行 |
| 把 minify 当 L2/L3 | 美化后若控制流清晰，停在 L0/L1 |
| 有 sourcemap 却硬去混淆 | 先吃 map |
| 动态 Hook 后不回静态核对 | 每个运行时地址映射回文件 |
| 缺工具仍输出「已还原算法」 | `TBD (tool-missing)` + 已见证据 |
| 把本模块当渗透 payload 库 | 拒绝；回 `RULES` |

## 与其它模块

- 未知文件先 `triage`；确认是 JS/bundle 再进本模块。
- APK 内 `index.android.bundle` / Hermes：Android 指纹后可转来，但 Hermes 字节码需另轨（本批只处理可读 JS 文本）。
- 原生 `.so` / PE 内嵌脚本：脚本走本模块，原生壳走 `binary-reverse`。
