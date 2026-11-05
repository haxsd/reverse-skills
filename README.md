# reverse-skills

**逆向工程 agent 技能包（精简）**：授权门禁 + 路由 + 分诊 + Android/APK 一条打通。

[![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![version](https://img.shields.io/badge/version-0.1.0-informational)](VERSION)

与 [toolkit-map](https://github.com/haxsd/toolkit-map) 一样独立维护；[agent-skills](https://github.com/haxsd/agent-skills) 里的 `reverse-skill` 只做路由入口，链到本仓。

## 安装

```bash
git clone https://github.com/haxsd/reverse-skills.git "$HOME/tools/reverse-skills"
export REVERSE_SKILL_ROOT="$HOME/tools/reverse-skills"
```

```powershell
git clone https://github.com/haxsd/reverse-skills.git "$env:USERPROFILE\tools\reverse-skills"
$env:REVERSE_SKILL_ROOT = "$env:USERPROFILE\tools\reverse-skills"
```

## 热路径

1. 读 `RULES_zh.md` / `RULES.md`（授权硬门）
2. 路由：`skills/MASTER-ROUTING.md` 或 `skills/scripts/master-route.*`
3. 建案：`skills/scripts/case-init.*`（`auth.status=granted` 或 `offline-sample` 预设）
4. 打开 PRIMARY：`skills/triage/` 或 `skills/android-apk/`

## 第一批模块

| id | 用途 |
|---|---|
| `triage` | 通用文件/二进制分诊决策树 |
| `android-apk` | APK/XAPK/JAR/AAR 指纹→反编译→API/调用链 |

第二批才加 JS / 通用二进制深度模块。不含 pentest payload、EDR 绕过。

## 许可证

MIT（本仓）。Apache-2.0 改编来源见 `NOTICE` 与 `ATTRIBUTION.md`。
