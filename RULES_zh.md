# reverse-skills 行为规则（中文）

> 版本见根目录 `VERSION`。本文件是行为链真源；路由表见 `skills/MASTER-ROUTING.md` 与 `skills/registry.json`。

## 激活与同意

- **读仓库 ≠ 授权执行。** 查看、总结、对比保持只读。
- 运行脚本、建案、对目标 ACT 前，先披露将执行的命令与预期副作用，获得用户明确同意。
- 客户端全局配置（规则/钩子/MCP）不得擅自写入。

## 目标授权硬门（ACT 前）

对具体目标做任何主动动作（解包以外的动态 Hook、设备交互、联网请求、重打包安装等）前，案例目录 `work/<case>/scope.md` 必须满足：

1. `auth.status=granted`
2. 有效的 `network_profile`（`offline` | `lab_only` | `authorized_target_only`）
3. `in_scope.assets` 覆盖当前样本/目标

**本地离线样本**可用预设 `offline-sample`：脚本会写入 `auth.status=granted`、`network_profile=offline`、并把样本路径列入 in_scope。提及目标名 ≠ 已授权。`-Force` / `--force` **不能**绕过本门。

未满足时：只允许读文档、路由、通用说明；禁止对目标 ACT。

## 证据标签

结论必须带标签（详见 `skills/core/evidence-labels.md`）：

| 标签 | 含义 |
|---|---|
| `observed` | 直接从样本/命令输出读到 |
| `inferred` | 由 observed 推导，需写推导链 |
| `proposed` | 为可读性起的名字/假设，非目标内建 |
| `web` | 外部资料，附 URL 与置信度 |

本地证据与 web 冲突时以本地为准。

## 缺工具诚实降级

用 `command -v` / `Get-Command` 确认工具。未检测到就如实说明，**不要**编造调用方式或假装已分析。可选工具缺失时跳过该步并记录。

## 第一批范围

仅：`triage`、`android-apk`，以及路由/授权/case-init/证据标签骨架。

**不收 / 不做：** JS 深度模块、通用二进制深度模块（第二批）、pentest payload 字典、EDR/AV 绕过、未授权利用构造、对未授权目标的扫描/入侵/凭据窃取/持久化。

## 热路径

```text
1. 读本 RULES
2. master-route（PRIMARY）
3. case-init → scope.md 就绪
4. 打开 PRIMARY 的 SKILL.md → ACTION REQUIRED
5. 工具仅用本机已验证存在者；结论写证据链
```
