# Test

## Step
1. `dnf remove -y weston`（如已安装）
2. `dnf install -y labwc fonts-dejavu xkeyboard-config foot seatd libgbm-devel mesa-gl`
3. 创建 `~/.config/labwc/rc.xml`（键盘/鼠标/主题配置，参考测试手册）
4. 启动 `seatd &` 与 `labwc`

## Expect
桌面正常启动并进入，右键可调出菜单。
