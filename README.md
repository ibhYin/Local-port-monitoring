# ports — 本地端口监控与管理

macOS 上的一站式本地端口管理：**看清现状、快速释放、固定分配、排查冲突**。

单文件 Python3（仅标准库），launchd 常驻守护 + 秒读 CLI，常开占用极低。

```
$ ports
守护在线，快照 1s 前
状态  端口   进程             PID    来源                       备注
🟢    3080   node             34152  项目:workspace
🟢    3306   OrbStack Helper  17267  docker/interview-mysql     数据库
🟢    8000   python3.10       50912  项目:my-rag
🟢    5000   ControlCenter    388    系统服务
🆕    39902  Python           27786  项目:tmp
⚪    3001   -                -      预留                       another-app

共 38 个监听端口 · 3 个未知 · 1 个预留
```

- 🟢 运行中（已识别来源）　🆕 刚出现（60s 内）　⚠️ 未知进程　⚪ 已登记未运行
- 来源自动识别：**Docker 容器名**（OrbStack/Docker Desktop）、**SSH 隧道**（`ssh -L/-D`）、**系统服务**、**应用**（.app）、**项目**（进程工作目录）

## 安装

```bash
git clone git@github.com:ibhYin/Local-port-monitoring.git
cd Local-port-monitoring
./install.sh --add-path   # 装 CLI + launchd 常驻守护
```

- `--no-daemon` 只装 CLI；`--add-path` 把 `~/.local/bin` 写入 `~/.zshrc` 的 PATH
- 安装是**拷贝**（`~/.local/bin/ports`），仓库放移动硬盘也不影响使用；更新代码后重跑 `./install.sh` 即可

## 网页面板（不想记命令？用这个）

守护进程内置一个**仅限本机访问**的网页面板，打开方式任选：

- 双击 `~/Applications/端口面板.command`（安装时自动创建）
- 命令 `ports ui`（守护不在会自动装好再打开浏览器）
- 浏览器直接访问面板地址（`ports daemon status` 会显示，默认 <http://127.0.0.1:7877>）

面板能力：实时表格自动刷新（2s）、搜索过滤、点「停止」结束进程（带确认）、
点「详情」看命令行/工作目录/父进程、点「备注」行内登记、领端口（结果一键复制）、
事件流水、点「打开」直接访问该端口上的服务、点端口号复制。

安全：服务只绑定 `127.0.0.1`；每次守护启动生成随机 token，页面自带；
所有 API 要求 token 且不响应跨域预检，其它网页无法跨站调用。

## 命令

| 命令 | 作用 |
|------|------|
| `ports` / `ports ls` | 实时端口表（读守护快照，毫秒级返回） |
| `ports watch` | 全屏实时视图，2s 原地刷新，Ctrl+C 退出 |
| `ports who <端口>` | 排查：命令行、工作目录、父进程、运行时长 |
| `ports check <端口>` | 是否空闲（脚本友好：空闲退出码 0） |
| `ports kill <端口>...` | 结束占用进程（默认确认；`-y` 跳过；`--force` 允许 <1024/root） |
| `ports alloc <名字>` | 领一个空闲且未登记的端口并登记（同名自动复用，输出末行是端口号） |
| `ports label <端口> <备注>` | 手工登记/加备注 |
| `ports forget <端口>` | 取消登记 |
| `ports events [-n N]` | 端口出现/消失/分配/结束流水 |
| `ports ui` | 打开网页面板 |
| `ports edit` | 用 `$EDITOR` 手工编辑登记表 |
| `ports daemon install/status/restart/uninstall` | 管理常驻守护 |

## 常驻守护与性能

守护由 **launchd 用户级托管**（开机自启、崩溃自动拉起，无需 sudo），每 3s 用
`netstat -anv` 廉价校验一次端口集合，有变化或每 30s 才做一次全量扫描（lsof/docker/ps）。

实测（M 系列芯片，38 个监听端口）：

| 指标 | 数值 |
|------|------|
| 空闲 CPU | ≈0%（ps 显示 0.0%，单次轮询 burst <1.5% × 35ms） |
| 内存 RSS | 5~7 MB |
| 快照新鲜度 | ≤3s（端口出现/消失、进程重启都在一个周期内被发现） |

不想要常驻：`ports daemon uninstall`，CLI 回落直扫模式，功能不减、零常驻成本。

## 数据目录

`~/.config/ports/`（在内盘，与仓库位置无关）：

- `registry.json` 登记表　`state.json` 实时快照　`events.log` 流水　`daemon.log` 守护日志

## 安全设计

- `kill` 拒绝 launchd/内核等系统关键进程；root 进程与 <1024 端口需 `--force`
- `alloc` 只在 3000~49151 分配（避开 macOS 临时端口区与面板端口段），跳过已登记端口
  与**知名服务默认端口**（MySQL 3306、PostgreSQL 5432、Redis 6379、MongoDB 27017、
  AirPlay 5000/7000 等，刻意不含 3000/8000/8080 开发惯例端口），并对候选逐一做
  **真实绑定测试**（IPv4/IPv6），未监听但被占用/TIME_WAIT 的端口一律不发
- 避开名单可在 `ports edit` 里自定义：登记表加 `"reserved": [整数数组]` 字段，
  缺省用内置名单（见 bin/ports 的 DEFAULT_RESERVED_PORTS）
- 所有写操作原子落盘 + 文件锁，与守护并发安全

## License

MIT
