# TODO

## multi_run.sh 測試場景

已通過的場景（2026-03-28）：

| # | 場景 | 說明 | 結果 |
|---|------|------|------|
| 1 | 不同 ws、同 docker repo | `~/robot_a_ws/docker_ros_noetic` + `~/robot_b_ws/docker_ros_noetic` | PASS |
| 2 | 同 ws、不同 docker repo | `~/ws/osrf_ros_noetic` + `~/ws/osrf_ros2_humble` | PASS |
| 3 | 不同 ws、不同 docker repo | `~/ws_a/osrf_ros_noetic` + `~/ws_b/ros2_humble` | PASS |

待測試場景：

| # | 場景 | 說明 | 挑戰 |
|---|------|------|------|
| 4 | 同 ws、同 repo（兩個 instance） | 路徑完全相同 → hash 相同 → service name 撞 | 需加計數器 |
| 5 | GPU 分配 | 兩個容器都要 GPU | 共用 GPU 可行，分配特定 GPU 需指定 device ID |
| 6 | Port 衝突（ROS master） | 兩個 ROS master 都用 11311 | `network_mode: host` 下衝突；隔離 network 可解 |
| 7 | Volume 衝突 | 兩個容器掛同一個 WS_PATH | 可能有檔案鎖，ROS 開發通常沒問題 |
| 8 | Network 隔離 | 不同容器組需要隔離網路 | multi_run.sh 可自動建 bridge network |
| 9 | 跨機器（不同 host） | Docker context 或 SSH | 超出 compose 範圍，需 Docker Swarm/K8s |

## Planned

### Network 隔離支援

multi_run.sh 目前使用 `network_mode: host`（繼承自各 repo compose.yaml）。未來若需要容器間 network 隔離，可在 generate 時自動建立 bridge network：

```yaml
# 自動產生
networks:
  multi_net:
    driver: bridge

services:
  ros_noetic_2a8b:
    network_mode: bridge  # 覆蓋 host
    networks:
      - multi_net
```

**何時實施**：當需要 ROS master port 隔離或安全隔離時。

### compose include 方案（已驗證不可行）

~~方案 B：使用 Docker Compose `include` 合併多個 compose.yaml。~~

**結論**：compose include 會合併同名 service（YAML key 層面），`-p` project name 無法解決。改用 `docker compose config` 展開 + Python 重命名 service 的方式已實作並通過測試。

## v3.0.0 BREAKING CHANGE 待辦

### docker_template → template 改名
- 所有 consumer repo subtree prefix `docker_template/` → `template/`
- 腳本路徑引用全部更新
- CLAUDE.md、README、CI workflows 更新

### setup.sh 移至 script/
- `docker_template/setup.sh` → `docker_template/script/setup.sh`
- build.sh/run.sh 呼叫路徑更新
- 15 個 consumer repo Dockerfile CONFIG_SRC 路徑更新

### config/ 移至 script/
- 如果 config/ 也不是 user 直接使用的，一併移入 script/

### Consumer repo Makefile
- 在 docker_template 提供 Makefile 模板（build/run/test/stop/exec）
- Consumer repo 透過 symlink 或 subtree 取得
