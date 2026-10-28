# Test

## Step
1. `dnf remove -y labwc`（如已安装）
2. `dnf install -y sddm openruyi-desktop-setup-labwc`
3. `systemctl enable --now sddm`

## Expect
桌面开机自启并正常进入。参考 https://openruyi.cn/zh-Hans/docs/guide/desktop-environments/labwc。
