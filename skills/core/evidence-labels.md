# Evidence labels

每条结论必须带标签。灵感来自 PyModel/reverse-engineering-skill 的证据约定，本仓改写并与授权门禁并用。问题清单与有界否定检索的写法参考 morluto/rea（MIT，钉在 `ATTRIBUTION.md` 所记提交），本文件为改写，未搬其工具绑定。

| Label | Meaning | Required extras |
|---|---|---|
| `observed:` | Read directly from sample/command output | offset, addr, command excerpt, or file:line |
| `inferred:` | Deduced from observed facts | citation chain back to observed |
| `proposed:` | Name/hypothesis for readability, not in the target | mark clearly as analyst-invented |
| `web:` | From external docs/search | URL + confidence (high/medium/low) |

Rules:

- No unlabeled claims in deliverables.
- `inferred:` alone is not enough for a finding — need ≥1 `observed:`.
- On conflict, **local observed wins** over `web:`; record the conflict.
- Unknown → `TBD (unverified)`, do not invent.
- **Static is not execution.** Reading bytes, headers, strings, or decompiler output may be `observed:` as *file/static facts*. Do not phrase those facts as if the program was run. Runtime behavior needs an authorized run, attach, or capture, and must cite that evidence.
- **Bounded negatives stay bounded.** “Not found in scope X” (name the files, tools, and coverage) is not “does not exist.” An empty page, a truncated search, or a missing metadata record is an unknown or a scoped miss, not global absence.

## Question checklist (broad work)

When a request spans several features or subsystems, start by listing questions and the evidence each one needs in `work/<case>/questions.md` (create or complete this file after case-init). Follow the evidence trail; do not declare the investigation complete while required questions are still open.

At finish, mark every question with exactly one of:

| status | meaning |
|---|---|
| `answered` | 已回答：所需证据已经拿到，结论可回指 |
| `partially-answered` | 部分回答：有证据，但覆盖不全或关键缺口仍在 |
| `unresolved` | 未解决：没有足够证据，或还没查 |

收尾或走 `skills/case-review/` 时，核对每条是否都带了上述状态；有界否定必须保持有界。
