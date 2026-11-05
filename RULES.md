# reverse-skills rules (English)

> See `VERSION`. Behavior source of truth; routing lives in `skills/MASTER-ROUTING.md` and `skills/registry.json`.

## Activation and consent

- Reading this repository is **not** authorization to execute it.
- Before scripts, case creation, or target ACT: disclose commands and side effects; get explicit approval.
- Do not write client-global rules/hooks/MCP config unless the user approves the exact change.

## Hard target-auth gate (before ACT)

Before active work on a concrete target (device hooks, network to target, rebuild-install, etc.), `work/<case>/scope.md` must have:

1. `auth.status=granted`
2. A valid `network_profile` (`offline` | `lab_only` | `authorized_target_only`)
3. `in_scope.assets` covering the sample/target

**Offline local samples** may use preset `offline-sample` (sets granted + offline + sample path). Naming a target is not grant. `-Force` / `--force` never bypasses this gate.

If not ready: docs/routing only — no target ACT.

## Evidence labels

Every claim uses `observed` | `inferred` | `proposed` | `web` (see `skills/core/evidence-labels.md`). Local evidence wins over web on conflict.

## Missing-tool honest degrade

Check with `command -v` / `Get-Command`. If missing, say so — do not invent invocations.

## First-batch scope

Only `triage`, `android-apk`, plus routing/auth/case-init/evidence skeleton.

**Out of scope:** JS / deep-binary domain modules (batch 2), pentest payload dictionaries, EDR/AV bypass, unauthorized exploit construct, unauthorized scanning/intrusion/credential theft/persistence.

## Hot path

```text
1. Read these RULES
2. master-route → PRIMARY
3. case-init → scope.md ready
4. Open PRIMARY SKILL.md → ACTION REQUIRED
5. Tools only if verified present; keep evidence chain
```
