# MASTER-ROUTING — PRIMARY 快路径

> 平台只改变入口脚本，不改变路由语义。机器可读清单见 `registry.json`。

## 执行契约

```text
1. 先路由后动手
2. 输出 PRIMARY 路径 + 一句话依据
3. case-init / scope.md — auth 未 granted 禁止对目标 ACT
4. 立即打开 PRIMARY 的 SKILL.md → ACTION REQUIRED
5. 工具：command -v / Get-Command；缺失则诚实降级
6. 结论带 evidence 标签；追加 timeline
```

补充（不改上面的顺序，也不削弱授权门）：

- 手头已有同一软件的**完整源码仓**，且问题不是「这份发运产物里到底打了什么」时：先用普通方式读源码，不要一上来就走逆向模块。
- 获准检查样本 ≠ 获准运行、抓流量、附加进程或触碰设备/账号。
- 覆盖多个功能的任务：先写 `work/<case>/questions.md`，收尾逐条标 `answered` / `partially-answered` / `unresolved`。

### 脚本入口

先设 `REVERSE_SKILL_ROOT`（可选；未设则脚本按自身路径回退到本仓根）。bash / pwsh 输出键对齐：`ROOT` / `PRIMARY` / `CASE_DIR` / `auth.status` / `ready_for_act` / `DEGRADED`。

```bash
export REVERSE_SKILL_ROOT="$HOME/tools/reverse-skills"   # 可选
bash "$REVERSE_SKILL_ROOT/skills/scripts/master-route.sh" --hint "<任务>"
bash "$REVERSE_SKILL_ROOT/skills/scripts/case-init.sh" --hint "<任务>" --case-name my-case
bash "$REVERSE_SKILL_ROOT/skills/scripts/case-init.sh" --hint "offline apk" --case-name my-sample \
  --preset offline-sample --sample ./app.apk
bash "$REVERSE_SKILL_ROOT/skills/scripts/check-tools.sh" --skill android-apk
python3 "$REVERSE_SKILL_ROOT/skills/case-review/scripts/review_case.py" work/<case>
```

```powershell
$env:REVERSE_SKILL_ROOT = "$env:USERPROFILE\tools\reverse-skills"  # 可选
pwsh -NoProfile -File "$env:REVERSE_SKILL_ROOT\skills\scripts\master-route.ps1" -Hint "<任务>"
pwsh -NoProfile -File "$env:REVERSE_SKILL_ROOT\skills\scripts\case-init.ps1" -Hint "<任务>" -CaseName my-case
pwsh -NoProfile -File "$env:REVERSE_SKILL_ROOT\skills\scripts\case-init.ps1" -Hint "offline apk" -CaseName my-sample `
  -Preset offline-sample -Sample .\app.apk
pwsh -NoProfile -File "$env:REVERSE_SKILL_ROOT\skills\scripts\check-tools.ps1" -Skill android-apk
python "$env:REVERSE_SKILL_ROOT\skills\case-review\scripts\review_case.py" work/<case>
```

`check-tools` 读 `skills/registry.json`：缺**必需**工具时 exit 1 并打印 `MISSING_REQUIRED=` / `DEGRADED=true`（不 silent）；可选工具缺失只标 `DEGRADE_OPTIONAL=`。

## 路由表

| 条件（命中任一） | PRIMARY |
|---|---|
| APK / XAPK / AAR / Android / jadx / smali / Manifest / Retrofit / 安卓逆向 | `skills/android-apk/` |
| JS / JavaScript / webpack / obfuscator / sourcemap / 解混淆 / 前端签名 / 加密参数 / bundle / Electron / ASAR / `app.asar` / 桌面 Electron | `skills/js-reverse/` |
| 明确深度原生逆向：ghidra / ida / radare / rizin / 反汇编 / 反编译 ELF\|PE\|Mach-O / 「分析这个 so/dll/exe」/ NativeAOT / Go 二进制（已确认要走原生深度） | `skills/binary-reverse/` |
| 打包运行时、但还没找到真正应用层：PyInstaller / `bun --compile` / `deno compile` | 先 `skills/triage/`，抽出应用层后再转入 `js-reverse` 或 `binary-reverse` |
| 未知文件类型 / 先分诊 / 仅 magic/「这是什么文件」 | `skills/triage/` |
| 仅授权/建案/规则问题 | 停在 RULES + case-init，不选领域模块 |

多条件同时命中时优先级：

1. 明确是 Android 包文件 → `android-apk`
2. 明确是 JS/bundle/前端参数链，或桌面 Electron/ASAR → `js-reverse`
3. 明确是 PyInstaller / Bun `--compile` / Deno `compile` 打包体，且尚未分出应用层 → 先 `triage`（不要因为文件后缀是 `.exe`/ELF 就直接进 `binary-reverse`）
4. 明确是已分诊后的原生二进制深度（含 .NET NativeAOT、已确认的 Go 二进制） → `binary-reverse`
5. 否则先 `triage`，再按分诊结果进入领域

`binary-reverse` 假定 triage 结论已有或可在开局快速复核；纯「未知blob」仍先 `triage`。

## 可选执行后端（REA）

本仓不内嵌、不强制依赖 [REA](https://github.com/morluto/rea)（Reverse Engineer Anything，MIT）。若本机**已经**装好它的 CLI 或 MCP（常见入口：`npx rea-agents`），可以把与当前 PRIMARY 路线相匹配的分析交给它执行；没装就按本仓自己的方法和本机已有工具走，缺工具则诚实降级。不要把 REA 的命令名写进必经步骤，也不要为了用它去改客户端全局配置（除非用户批准了具体改动）。

## 明确不路由

协议深度专项、CTF/pwn 利用编写、固件文件系统专项、EDR 绕过、渗透 payload —— **不收**；告知范围外，可做最小静态说明，不假装有模块。
