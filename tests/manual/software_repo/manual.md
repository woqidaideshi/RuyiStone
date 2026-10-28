# 修改软件源

## Step
根据实际需要，将软件源切换到对应架构（rva20/rva23）的仓库：

```bash
# rva20 设备
sed -i 's|baseurl=.*|baseurl=https://repo.build.openruyi.cn/openruyi/rva20/|' /etc/yum.repos.d/openruyi.repo

# rva23 设备
sed -i 's|baseurl=.*|baseurl=https://repo.build.openruyi.cn/openruyi/riscv64/|' /etc/yum.repos.d/openruyi.repo
```

## Expect
软件源修改成功，安装时可正常获取软件；installiso 无需修改。
