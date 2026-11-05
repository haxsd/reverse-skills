---
name: android-apk
description: Android APK/XAPK/JAR/AAR 静态逆向：指纹、反编译、结构、API 提取与调用链。Use for authorized offline APK reverse engineering, jadx decompile, Retrofit/OkHttp/Ktor/Apollo surface mapping, and call-flow tracing — not for unauthorized device attacks.
---

# Android / APK 逆向

## ACTION REQUIRED

1. 确认 `work/<case>/scope.md`：`auth.status=granted`（本地样本可用 `offline-sample` 预设）。
2. 对样本算哈希并记录（`observed:`）。
3. **Phase 0 指纹**：若为 Flutter / RN / Cordova / Xamarin / Unity 等，STOP 并切换轨道（本模块不深挖）。
4. 校验工具：`jadx` 必需；`apktool` / `java` 建议。缺失则诚实降级，不编造输出。
5. 按 Phase 1→6 推进；产物落到 `work/<case>/android/stepN/`。
6. 动态 Hook / 真机 / 重打包安装另需明确授权与 `network_profile`；默认只做静态。

契约字段见 `../core/phase-contracts.json`。证据标签见 `../core/evidence-labels.md`。

## 授权边界

| 动作 | 要求 |
|---|---|
| 本地解包 / jadx / 读 Manifest / 字符串与 API 面梳理 | `granted` + 通常 `offline` |
| adb / Frida / 安装重打包包 / 打真实服务器 | `granted` + 非 offline 的明确网络档 + in_scope 覆盖 |

禁止：未授权对第三方应用商店账号、用户设备或生产 API 的攻击性操作；本模块不提供 exploit 构造。

## 输出布局

```text
work/<case>/android/
  step0/fingerprint.md
  step1/deps.md
  step2/decompile_notes.md
  step3/manifest_summary.md
  step3/packages.md
  step4/api_inventory.md
  step5/callflow.md
  step6/report.md
  step6/findings.json
  _logs/
```

## Phase 0 — 指纹（先于反编译）

反编译 Java 对 Flutter / RN / Cordova / Xamarin / Unity **往往无意义**。先看归档内容：

```bash
unzip -l "$APK" | head -200
unzip -l "$APK" | grep -Ei 'lib/|assets/|classes|AndroidManifest'
sha256sum "$APK"   # macOS: shasum -a 256
file "$APK"
```

```powershell
Get-FileHash $env:APK -Algorithm SHA256
# 列表可用 tar/Expand-Archive 或 .NET ZipFile；缺工具就说明并停
```

| Framework | 强特征 | 动作 |
|---|---|---|
| Flutter | `libflutter.so`, `libapp.so`, `flutter_assets/` | STOP → 换 Flutter/Dart 轨道 |
| React Native | `libhermes.so`, `index.android.bundle` | STOP → JS bundle 轨道 |
| Cordova/Capacitor | `assets/www/`, `cordova.js` | STOP → WebView/hybrid |
| Xamarin/MAUI | `assemblies/*.dll`, `libmonodroid.so` | STOP → .NET |
| Unity | `libunity.so`, `libil2cpp.so` | STOP → 游戏引擎轨道 |
| 纯 Java/Kotlin（可含 JNI） | `classes*.dex`，无上述壳层 | **继续本流水线**；记录 `.so` 供后续 JNI 备注 |

把判定与证据写入 `step0/fingerprint.md`（标签 `observed:`）。

## Phase 1 — 依赖

必需：`java`（17+ 建议）、`jadx`。可选：`apktool`、Vineflower/Fernflower、`dex2jar`。

```bash
command -v jadx && jadx --version
command -v apktool && apktool --version
command -v java && java -version
```

```powershell
Get-Command jadx, apktool, java -ErrorAction SilentlyContinue
```

缺失 `jadx`：说明安装来源（发行版包 / GitHub releases），**不要**假装已反编译。写入 `step1/deps.md`。

## Phase 2 — 反编译

优先 `jadx`；复杂 Java 可再比 Fernflower/Vineflower。XAPK：先解出内部 APK 再逐个处理。若外层是「薄包装」且几乎无 Java、内含 `base.apk`，对 `base.apk` 再反编译。

```bash
mkdir -p work/<case>/android/step2/jadx-out
jadx -d work/<case>/android/step2/jadx-out --deobf "$APK"
# 只要代码、加快：
# jadx -d ... --no-res "$APK"
```

```powershell
New-Item -ItemType Directory -Force -Path work\<case>\android\step2\jadx-out | Out-Null
jadx -d work\<case>\android\step2\jadx-out --deobf $env:APK
```

记录命令、退出码、输出路径与告警摘要到 `step2/decompile_notes.md`。

## Phase 3 — 结构

1. 读 `resources/AndroidManifest.xml`（或 apktool 解码结果）：launcher Activity、四大组件、权限、`application@android:name`。
2. 浏览 `sources/` 包结构：区分应用包与第三方库；留意 `api` / `network` / `repository` / `retrofit` / `http` 等包名。
3. 若大量单字母包名：注明 R8/ProGuard；Kotlin 元数据有助于恢复部分类名（概念步骤，不强制专用脚本）。

写出 `step3/manifest_summary.md` 与 `step3/packages.md`。

## Phase 4 — API 面（概念搜索）

在反编译树中搜索（示例模式，按命中记录 `observed:` 文件:行）：

| 栈 | 搜索线索 |
|---|---|
| Retrofit | `@GET` `@POST` `@PUT` `@DELETE` `@PATCH`、`Retrofit.Builder`、`@Url` |
| OkHttp | `OkHttpClient`、`Request.Builder`、`Interceptor`、`CertificatePinner` |
| Ktor | `HttpClient`、`install(`、路由 DSL |
| Apollo/GraphQL | `apollo`、`.graphql`、`ApolloClient` |
| 通用 | `https://`、`http://`、`/api/`、`Authorization`、`Bearer`、HMAC/签名函数名 |

产出表格：`method | path/url | headers/auth hints | 源位置 | evidence label` → `step4/api_inventory.md`。  
**只做测绘与理解**；不对未授权主机发请求。

## Phase 5 — 调用链

从 launcher / 登录相关 Activity 或 Fragment 向下追到 ViewModel / UseCase / Repository / HTTP 调用。用简短序列或列表写清：UI → 业务 → 网络。无法静态连通处标 `inferred:` 或 `TBD`。写入 `step5/callflow.md`。

## Phase 6 — 报告

`step6/report.md` 建议结构：

1. 样本哈希与指纹结论  
2. 技术栈与混淆情况  
3. 组件与权限摘要  
4. API 面摘要（高价值端点）  
5. 调用链要点  
6. JNI / `.so` 备注（若有）  
7. 未知与下一步（其它模块 / 人工）  
8. Findings 列表：每条带 severity（info 亦可）与 evidence ids  

`step6/findings.json` 可用简易数组：`[{id,title,severity,evidence,location}]`。

## 缺工具降级

| 缺失 | 可做 | 不可做 |
|---|---|---|
| `jadx` | `file`/哈希/`unzip -l`/strings 级指纹 | 伪称已反编译 |
| `apktool` | 仅 jadx 资源树 | 编造 smali 路径 |
| `adb`/`frida` | 纯静态 | 假装已动态验证 |

## Attribution

剧本形态改编自 SimoneAvogadro/android-reverse-engineering-skill（Apache-2.0）与 Fausto-404/ai-mobile-reverse-skills（MIT）的阶段门控思路；未 vendor 上游脚本。详见根目录 `ATTRIBUTION.md` 与 `NOTICE`。
