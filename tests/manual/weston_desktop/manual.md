# Test

## Step
1. `dnf install -y weston seatd mesa-dril libgbm-devel mesa-gl`
2. 启动 `seatd &` 与 `weston --backend=drm-backend.so`
3. 打开 `weston-terminal` 与 `weston-tablet`

## Expect
桌面正常启动并进入；weston-terminal 能打开终端窗口并正常使用；weston-tablet 能打开触摸/平板演示窗口，无报错。
