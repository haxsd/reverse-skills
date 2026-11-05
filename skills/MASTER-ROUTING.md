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
| JS / JavaScript / webpack / obfuscator / sourcemap / 解混淆 / 前端签名 / 加密参数 / bundle | `skills/js-reverse/` |
| 明确深度原生逆向：ghidra / ida / radare / rizin / 反汇编 / 反编译 ELF\|PE\|Mach-O / 「分析这个 so/dll/exe」 | `skills/binary-reverse/` |
| 未知文件类型 / 先分诊 / 仅 magic/「这是什么文件」 | `skills/triage/` |
| 仅授权/建案/规则问题 | 停在 RULES + case-init，不选领域模块 |

多条件同时命中时优先级：

1. 明确是 Android 包文件 → `android-apk`
2. 明确是 JS/bundle/前端参数链 → `js-reverse`
3. 明确是已分诊后的原生二进制深度 → `binary-reverse`
4. 否则先 `triage`，再按分诊结果进入领域

`binary-reverse` 假定 triage 结论已有或可在开局快速复核；纯「未知blob」仍先 `triage`。

## 明确不路由

协议深度专项、CTF/pwn 利用编写、固件文件系统专项、EDR 绕过、渗透 payload —— **不收**；告知范围外，可做最小静态说明，不假装有模块。
