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
```

## 预设

- `offline-sample`：本地文件静态分析 → `auth.status=granted`，`basis=own_system`，`network_profile.mode=offline`，样本路径进入 `in_scope.assets`。
- `ctf-public`：公开 CTF → `granted` + 题目 URL/文件；仍禁止越界攻击他人设施。

`-Force` 不能把 `pending`/`denied` 变成可 ACT。
