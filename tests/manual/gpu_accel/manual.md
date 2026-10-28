# Test

## Step
1. `dnf install -y glmark2`
2. `glmark2-es2-wayland`

## Expect
渲染器显示 AMD GPU（硬件加速生效），而非 llvmpipe 软渲染。
