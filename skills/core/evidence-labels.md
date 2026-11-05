# Evidence labels

每条结论必须带标签。灵感来自 PyModel/reverse-engineering-skill 的证据约定，本仓改写并与授权门禁并用。

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
