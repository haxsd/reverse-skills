# Attribution / 上游说明

本仓方法论**改写自**多家上游，不是整仓 vendor。许可证以各上游为准；本仓代码与文档默认 MIT（见 `LICENSE`），Apache-2.0 来源见 `NOTICE`。

| 上游 | SPDX | 钉住引用 | 我们借了什么 | 我们没搬什么 |
|---|---|---|---|---|
| [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) | MIT | `cab634bd855fc287f6e420c1f36fd1a6b9245960` (v1.0.1 附近) | 路由热路径、授权/scope 门禁形态、case-init 预设（offline-sample）；JS 作业「观察→采样→本地验证」阶段划分思路 | pentest-tools、EDR 绕过、payload 字典、MCP 工具名绑定、整包模块 |
| [Fausto-404/ai-mobile-reverse-skills](https://github.com/Fausto-404/ai-mobile-reverse-skills) | MIT | `51fceafb06f742c17f4ed6f500f73e54fb9c9d8b` | 六阶段门控与 phase-contracts 输入/输出/阻塞项 | 具体 agent 全文、MCP 绑定实现、Frida bypass 模板 |
| [PyModel/reverse-engineering-skill](https://github.com/PyModel/reverse-engineering-skill) | MIT | `d531c4fdfec68171f0b9f0da7a3db2710fcd9a6a` | 分诊决策树、`observed`/`inferred`/`proposed`/`web` 证据标签；二进制深度阶段衔接 | 「No legal / no consent」立场（本仓改为硬授权门）；Frida/unpin 模板原文 |
| [batteryshark/rekit](https://github.com/batteryshark/rekit) | Apache-2.0 | `a52bf1a4ae745528fbf2e3fae3c21ed3cb9702f8` | registry 清单、safety tier、缺工具诚实降级；JS 去混淆「静态优先 / decoder 沙箱」与原生反编译工具降级思路 | 工具二进制、各 skill 脚本与 node_modules |
| [SimoneAvogadro/android-reverse-engineering-skill](https://github.com/SimoneAvogadro/android-reverse-engineering-skill) | Apache-2.0 | `0c7cf89830993df7dfc178498f69952262808bea` | APK 指纹→反编译→API 提取→调用链剧本 | 其 `scripts/*` 本体（不 vendor） |
| [morluto/rea](https://github.com/morluto/rea) | MIT | `e2585aa7ce31c37866ca46991ec656fdffaa3b90` | 改写后的方法：桌面 Electron 先查熔断再谈 `--inspect`；打包运行时先找真正应用层（PyInstaller CArchive、Bun 模块图、Deno 嵌入式虚拟文件系统、.NET NativeAOT、Go buildinfo）；有完整源码仓则先读源码；大任务先列问题清单、收尾按已回答/部分回答/未解决回看；有界否定检索不得写成「不存在」；检查样本的权限不等于运行、抓流量、附加进程或触碰设备/账号；静态分析不能当成已观察到执行。另加可选入口：本机已装 REA 时可作为匹配路线的执行后端 | 除可选入口外的工具名/MCP 绑定；AgentEnv / 强化学习环境搭建；固件、信号、EVM、报文捕获等本仓不收录的方向；其命令、脚本或引擎 |

当前范围（v0.3.0）：**骨架 + 通用分诊 + Android/APK + JS 逆向（含桌面 Electron/ASAR）+ 通用二进制深度（含打包运行时分层）**。协议/CTF/固件专项仍不收录。

核对日期：2026-11-11（Asia/Shanghai）。
