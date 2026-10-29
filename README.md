# openRuyi 自动化测试（tmt 版）

基于 **Fedora tmt + fmf** 重构的 openRuyi 版本测试工程，把《测试手册》中可自动化的条目固化为自动化用例，并落地上一版工程（`openruyi-autotest-cmake-new`）中缺失的 tmt 核心特性。

## 目录结构

```
openruyi-autotest-final/
├── .fmf/version                 # fmf 元数据树根
├── topology.env                 # 环境变量（plan 通过 environment-file 加载）
├── plans/
│   ├── main.fmf                 # 公共 plan 设置（provision/report，继承节点）
│   ├── smoke.fmf                # P0 冒烟测试（tag:smoke, tier 0）
│   ├── functional.fmf           # P1/P2 功能测试（tag:functional, tier 1）
│   └── feature.fmf              # 特性测试（tag:feature, tier 1，TR-010）
└── tests/
    ├── main.fmf                 # 公共测试元数据（framework: beakerlib）
    ├── lib/common.sh            # 唯一的共享库（收敛了原来 174 个重复 lib.sh）
    ├── smoke/                   # P0 冒烟测试（tag: smoke, tier 0）
    │   ├── main.fmf             # 公共 tag/tier（子用例继承）
    │   └── system_info/ base_pkgs/ clock_sync/ disk_expand/ user_mgmt/
    ├── functional/              # P1/P2 功能测试（tag: functional, tier 1）
    │   ├── main.fmf
    │   ├── pkgs/                # 包级测试：一包一目录，目录名=包名
    │   │   ├── main.fmf
    │   │   └── tmux/ podman/ linux-lts/
    │   └── scenario/            # 跨包场景测试（ssh 登录 / 工具链构建）
    │       ├── main.fmf
    │       └── ssh_login/ toolchain_build/
    ├── security/                # 安全测试（tag: security, tier 1，TR-006，空骨架）
    ├── compatibility/           # 兼容性测试（tag: compatibility, tier 2，TR-007，空骨架）
    ├── performance/             # 性能测试（tag: performance, tier 2，TR-008，空骨架）
    ├── reliability/             # 可靠性测试（tag: reliability, tier 2，TR-009，空骨架）
    ├── feature/                 # 特性测试（tag: feature, tier 1，TR-010，空骨架）
    └── manual/<7 个手动用例>/     # manual: true + manual.md
```

## 用到的 tmt 特性

| 特性 | 位置 | 说明 |
|------|------|------|
| `framework: beakerlib` | `tests/main.fmf` | tmt 自动安装 beakerlib、按 `TestResults` 解析结果 |
| 元数据继承 | `tests/main.fmf`、`tests/smoke/main.fmf`、`tests/functional/main.fmf`、`tests/functional/pkgs/main.fmf`、`tests/functional/scenario/main.fmf`、`tests/manual/main.fmf` | 公共 `framework/duration/contact` 与 `tag/tier` 下推子节点 |
| `require` 自动装依赖 | `tests/smoke/{system_info,disk_expand}`、`tests/functional/pkgs/{tmux,podman,linux-lts}`、`tests/functional/scenario/{ssh_login,toolchain_build}` | 前置包由 tmt prepare 阶段自动安装 |
| 安装日志告警检查 | `tests/lib/common.sh`（`assertDnfInstall`，`tests/smoke/base_pkgs` 用） | dnf 安装时检查 warning/error，有则提醒/报错，日志存 `TMT_TEST_DATA` |
| `prepare: how: install` | `plans/smoke.fmf`、`plans/functional.fmf` | plan 级统一安装依赖 |
| `adjust` 条件调整 | `tests/functional/scenario/toolchain_build/main.fmf` | RISC-V 上自动延长 `duration` |
| `environment-file` / `environment` | `plans/*.fmf` + `topology.env` | 注入 RVA 变体、ssh、OCI 镜像等参数 |
| `manual: true` | `tests/manual/` | 不可自动化条目用 Markdown 登记步骤与预期 |
| `tier` / `tag` / `duration` | 各测试 | 分级、过滤、超时控制 |
| `report: how: junit` | `plans/main.fmf` | 生成 CI 可解析的 JUnit 报告 |

## tag 词汇表

保持词汇表小而可复用，避免为单个用例发明新 tag；分级用 `tier`，不用 tag。

| tag | 含义 | 用于 |
|-----|------|------|
| `smoke` | 冒烟 / P0 | `plans/smoke.fmf` 过滤 |
| `functional` | 功能 / P1P2 | `plans/functional.fmf` 过滤 |
| `security` | 安全测试 | `tests/security/`（TR-006） |
| `compatibility` | 兼容性测试 | `tests/compatibility/`（TR-007） |
| `performance` | 性能测试 | `tests/performance/`（TR-008） |
| `reliability` | 可靠性测试 | `tests/reliability/`（TR-009） |
| `feature` | 特性测试 | `plans/feature.fmf` 过滤（TR-010） |
| `manual` | 手动用例 | `tests/manual/` |
| `pkg` | 软件包类测试 | `tests/smoke/base_pkgs`（基础软件安装验证） |
| `requires-network` | 需要外网（如 git clone github） | `tests/functional/scenario/toolchain_build` |

## 需求映射（《测试手册》17 项）

| # | 测试项 | 自动化 | 用例 | tag / tier |
|---|--------|--------|------|------------|
| 1 | 修改软件源 | ❌ 手动 | `/tests/manual/software_repo` | manual |
| 2 | ISO 安装系统 | ❌ 手动 | `/tests/manual/iso_install` | manual |
| 3 | 查看系统信息 | ✅ | `/tests/smoke/system_info` | smoke / 0 |
| 4 | 基础软件安装 | ✅ | `/tests/smoke/base_pkgs`（整体安装 + 告警/报错检查，含 tmux/podman/linux-lts） | smoke + pkg / 0 |
| 5 | 时钟同步 | ✅ | `/tests/smoke/clock_sync` | smoke / 0 |
| 6 | 扩容检查 | ✅ | `/tests/smoke/disk_expand` | smoke / 0 |
| 7 | 用户管理 | ✅ | `/tests/smoke/user_mgmt` | smoke / 0 |
| 8 | tmux 使用 | ✅ | `/tests/functional/pkgs/tmux` | functional / 1 |
| 9 | ssh 远程登录 | ⚠️ 部分 | `/tests/functional/scenario/ssh_login` | functional / 1 |
| 10 | gcc/llvm 构建 ruapu | ✅ | `/tests/functional/scenario/toolchain_build` | functional + requires-network / 1 |
| 11 | podman 容器 | ⚠️ 部分 | `/tests/functional/pkgs/podman` | functional / 1 |
| 12 | weston 桌面 | ❌ 手动 | `/tests/manual/weston_desktop` | manual |
| 13 | labwc 桌面 | ❌ 手动 | `/tests/manual/labwc_desktop` | manual |
| 14 | sddm 桌面 | ❌ 手动 | `/tests/manual/sddm_desktop` | manual |
| 15 | GPU 加速验证 | ❌ 手动 | `/tests/manual/gpu_accel` | manual |
| 16 | linux-lts 内核切换 | ⚠️ 部分 | `/tests/functional/pkgs/linux-lts`（require 安装 + 启动项，重启选内核需手动） | functional / 1 |
| 17 | user-data 测试 | ❌ 手动 | `/tests/manual/user_data` | manual |

> ✅ 全自动；⚠️ 部分自动（依赖外部条件，未配置时优雅跳过）；❌ 需人工/图形环境，登记为手动用例。

## 运行方法（在 openRuyi 设备上）

```bash
# 安装 tmt
sudo dnf install -y tmt

# 查看发现到的测试 / 计划
tmt tests ls
tmt plans ls

# 校验元数据
tmt lint

# 运行冒烟测试（P0）
tmt --feeling-safe run --all --verbose plan --name /plans/smoke

# 运行功能测试（P1/P2）
tmt --feeling-safe run --all --verbose plan --name /plans/functional

# 只跑单个测试
tmt --feeling-safe run --all --verbose plan --name /plans/functional test --name /tests/functional/pkgs/tmux
```

> 本地运行（`provision: how: local`）会直接在设备上执行，需 root 或免密 sudo。更安全的做法是改用 `provision --how container` 或 `--how virtual`。

## 环境变量

编辑 `topology.env`（plan 通过 `environment-file` 加载）：

| 变量 | 默认 | 用途 |
|------|------|------|
| `OPENRUYI_RVA_VARIANT` | `rva23` | RVA 变体，决定软件源 baseurl |
| `OPENRUYI_REPO_BASEURL` | 对应 rva23 地址 | 覆盖软件源地址 |
| `SSH_TEST_USER/HOST/PASSWORD/KEY` | 见 `topology.env` | ssh 登录实测目标，HOST 留空默认 localhost；密码/密钥留空则跳过登录实测 |
| `OPENRUYI_OCI_IMAGE_URL` | 空 | podman 镜像导入实测，留空则跳过 |

## 与原工程（openruyi-autotest-cmake-new）的对比

- `lib.sh`：从 **174 个重复文件** 收敛为 **1 个** `tests/lib/common.sh`；
- 依赖校验：从「flag 文件 + 引用计数」改为 tmt 的 `require` / `prepare`（并发安全、无竞态）；
- 安装告警：dnf 安装时捕获日志并检查 warning/error（原工程用 `2>/dev/null` 吞掉了错误输出）；
- 测试框架：显式声明 `framework: beakerlib`，结果可被 tmt 正确解析为 `results.yaml`；
- 元数据：公共 `tag/tier/duration` 上移父 `main.fmf`，子用例只保留差异；
- 环境适配：rva20/rva23 走 `environment-file`，RISC-V 慢编译走 `adjust`；
- 报告：增加 JUnit 输出，便于 CI 集成。
