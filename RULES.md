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

### Scope is not a blanket

This gate is not weakened. Grant to **inspect** a listed artifact does not, by itself, grant permission to **run** it, capture its traffic, attach to a live process, or touch devices or accounts. Each of those needs its own listed `in_scope.activities` (and a non-offline `network_profile` when it leaves the local file). Static reading of bytes is never “observed execution.”

## Source first

If a **complete source repository** for the same software is already available, analyze that tree with ordinary repo tools. Do not reach for reverse-engineering tooling first. Use the shipped artifact only when the question is about the build itself (what was packed, whether it matches the tree, and so on).

## Evidence labels

Every claim uses `observed` | `inferred` | `proposed` | `web` (see `skills/core/evidence-labels.md`). Local evidence wins over web on conflict.

Broad investigations start with a question checklist (`work/<case>/questions.md`) and the evidence each question needs. At finish, mark each question `answered`, `partially-answered`, or `unresolved`. A miss inside a bounded search is “not found in scope X,” never “does not exist.”

## Missing-tool honest degrade

Check with `command -v` / `Get-Command`. If missing, say so — do not invent invocations.

## Pack scope (v0.3)

Includes `triage`, `android-apk`, `js-reverse` (including desktop Electron/ASAR), `binary-reverse` (including packaged-runtime layering), plus routing/auth/case-init/evidence skeleton.

**Out of scope:** deep protocol playbooks, CTF/pwn exploit authoring, firmware specialty packs, pentest payload dictionaries, EDR/AV bypass, unauthorized exploit construct, unauthorized scanning/intrusion/credential theft/persistence.

## Hot path

```text
1. Read these RULES
2. master-route → PRIMARY
3. case-init → scope.md ready
4. Open PRIMARY SKILL.md → ACTION REQUIRED
5. Tools only if verified present; keep evidence chain
```
