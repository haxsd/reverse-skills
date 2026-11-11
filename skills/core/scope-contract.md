# Scope contract

ACT 前必须在分析项目下落地 `work/<case>/scope.md`。无 scope → 只读文档/路由。

## 最小字段

```markdown
# Case Scope

## meta
- case_id:
- created:
- primary_skill:
- project_root:

## auth
- status: granted | pending | denied
- basis: written_contract | bug_bounty_scope | ctf_public | own_system | lab_only
- evidence_of_auth:
- MUST NOT proceed if status != granted

## in_scope
- assets: []
- surfaces: []
- activities: []

## out_of_scope
- assets: []
- activities: []

## network_profile
- mode: offline | lab_only | authorized_target_only
- notes:

## deliverables
- report: true
- timeline: true
- questions: true
```

## 预设

- `offline-sample`：本地文件静态分析 → `auth.status=granted`，`basis=own_system`，`network_profile.mode=offline`，样本路径进入 `in_scope.assets`。默认活动仍是静态检查与报告。
- `ctf-public`：公开 CTF → `granted` + 题目 URL/文件；仍禁止越界攻击他人设施。

`-Force` 不能把 `pending`/`denied` 变成可 ACT。

## 授权粒度（不削弱硬门）

`auth.status=granted` 只覆盖 `in_scope` 里**写明**的资产与活动。获准检查一份样本，并不自动等于获准：

- 运行该样本（启动进程、安装、重打包后再装）
- 抓取其网络或拦截流量
- 附加到正在运行的进程，或打开远程调试口
- 触碰设备、账号、会话或他人系统

要把某项做进范围，必须把它写进 `in_scope.activities`；只要动作会离开本地文件，还需要非 `offline` 的 `network_profile`。`offline-sample` 预设只覆盖对本地样本的静态阅读与解包，不含上面四类动作。

静态分析的结果不能写成「已观察到执行」。
