<img src="./images/openRuyi.svg" alt="avatar" width="60" />

<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

版权所有 © 2026 openRuyi 社区
您对“本文档”的复制、使用、修改及分发受知识共享(Creative Commons)署名—相同方式共享4.0国际公共许可协议(以下简称“CC BY-SA 4.0”)的约束。为了方便用户理解，您可以通过访问 https://creativecommons.org/licenses/by-sa/4.0/ 了解CC BY-SA 4.0的概要(但不是替代)。CC BY-SA 4.0的完整协议内容您可以访问如下网址获取：https://creativecommons.org/licenses/by-sa/4.0/legalcode

# user-data 测试手册

本文档列出 user-data（cloud-init NoCloud 数据源）测试的执行过程与预期结果，用于验证 openRuyi 系统的 user-data 注入机制。本文以 2026/06 滚动版本的 QEMU 镜像为例，其他版本请替换对应的镜像与固件下载地址。

**背景说明：** user-data 是 cloud-init 的 NoCloud 数据源配置。通过在 seed.img（卷标 `cidata`）中提供 `user-data` 与 `meta-data` 两个文件，openRuyi 系统在首次启动时由 cloud-init 自动读取并执行，实现无人值守初始化：设置默认密码、创建用户、执行自定义命令（runcmd）、启用服务、注入主机名等。

其中：
- **user-data**：用户配置（YAML，设置密码 / 用户 / runcmd 等）。
- **meta-data**：实例元数据（instance-id、hostname）。

**实验环境：** 宿主机为 RVA23 硬件并运行 openRuyi（RISC-V）系统，支持 KVM 虚拟化，因此后续启动命令使用 `-enable-kvm` 加速。

**优先级：** P1

## 1. 下载镜像和固件

**测试说明：** 下载 openRuyi cloud 镜像与 QEMU UEFI 固件，并对镜像扩容。

**执行过程：**

```bash
wget https://releases.openruyi.cn/creek/2026.06/rva23/openRuyi-2026.06-Server-cloud.qcow2
wget https://releases.openruyi.cn/creek/2026.06/rva23/RISCV_VIRT_CODE.fd
wget https://releases.openruyi.cn/creek/2026.06/rva23/RISCV_VIRT_VARS.fd

# QEMU 镜像扩容
dnf install qemu-img qemu-system
qemu-img resize openRuyi-2026.06-Server-cloud.qcow2 +20G
ln -s openRuyi-2026.06-Server-cloud.qcow2 openruyi-virt_riscv64.qcow2
```

**预期结果：** 镜像、固件下载完成，镜像扩容成功。

## 2. 创建 seed.img

**测试说明：** 编写 cloud-init 的 user-data 与 meta-data，并用 xorriso 生成卷标为 `cidata` 的 seed.img。

**执行过程：**

```bash
# 创建 cloud-init 配置目录
mkdir -p seed

# 编写 user-data（cloud-init 配置）
cat > seed/user-data << 'EOF'
#cloud-config
password: openruyi
chpasswd:
  expire: false
users:
  - name: cloud-user
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel
    shell: /bin/bash
    lock_passwd: false

# 也可以写入 runcmd 等模块测试
runcmd:
  - echo "cloud-init test passed" > /tmp/cloud-init-test.log
  - systemctl enable --now sshd
EOF

# 编写 meta-data（实例元数据）
cat > seed/meta-data << 'EOF'
instance-id: test-vm-001
local-hostname: test-openruyi
EOF

# 生成 seed.img
dnf install xorriso
xorriso -as mkisofs -o seed.img -V cidata -J -r seed/

# 验证卷标为 cidata
blkid | grep cidata
```

**预期结果：** `seed.img` 生成成功，卷标为 `cidata`。

## 3. 启动 QEMU 虚拟机

**测试说明：** 以 rva23s64 配置启动 QEMU，并挂载 seed.img 作为 NoCloud 数据源。

**执行过程：**

```bash
qemu-system-riscv64 -enable-kvm \
  -nographic -machine virt,pflash0=pflash0,pflash1=pflash1,acpi=off \
  -smp 4 -m 12G \
  -cpu rva23s64 \
  -blockdev node-name=pflash0,driver=file,read-only=on,filename="RISCV_VIRT_CODE.fd" \
  -blockdev node-name=pflash1,driver=file,filename="RISCV_VIRT_VARS.fd" \
  -drive file="openruyi-virt_riscv64.qcow2",format=qcow2,id=hd0,if=none,cache=writeback,aio=threads \
  -drive file="seed.img",format=raw,if=virtio \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-device,rng=rng0 \
  -device virtio-blk-device,drive=hd0 \
  -device virtio-net-device,netdev=usernet \
  -netdev user,id=usernet,hostfwd=tcp::12060-:22
```

**预期结果：** 系统正常启动，cloud-init 识别 NoCloud 数据源并执行配置。

## 4. 进入系统后验证

**测试说明：** 登录系统后验证 user-data 各模块是否生效。

**执行过程：**

```bash
cloud-init status --wait       # 查看状态
cat /var/log/cloud-init.log    # 查看日志
cat /tmp/cloud-init-test.log   # 验证 runcmd 效果
cloud-init query userdata      # 查看解析的 user-data
# 查看 cloud-init 日志
cat /var/log/cloud-init-output.log
cat /var/log/cloud-init.log

# 验证 meta-data 注入（主机名 / instance-id）
hostname                            # 主机名应为 test-openruyi
hostnamectl                         # 查看静态主机名
ls /var/lib/cloud/instances/        # 目录名即 instance-id
cat /var/lib/cloud/data/instance-id # 查看 instance-id

# 验证 sshd 服务已启用
systemctl status sshd               # active (running)
```

**预期结果：**

- `cloud-init status` 显示完成，无报错；
- `/tmp/cloud-init-test.log` 内容为 `cloud-init test passed`；
- `cloud-user` 用户已创建，加入 wheel 组，具备免密 sudo（未配置密码，不验证 ssh 登录）；
- sshd 服务已启用（`systemctl status sshd` 为 active）；
- 主机名为 `test-openruyi`（meta-data 的 `local-hostname` 生效）；
- instance-id 为 `test-vm-001`（`/var/lib/cloud/instances/` 下存在 `test-vm-001` 目录）。

## 5. ssh 远程登录

**测试说明：** 从宿主机通过端口转发 ssh 登录虚拟机，验证 sshd 服务与密码注入生效（默认用户 openruyi）。

**执行过程：**

```bash
# 宿主机执行（QEMU 已将宿主 12060 端口转发到虚拟机 22 端口）
ssh openruyi@localhost -p 12060
```

**预期结果：** 使用密码 `openruyi` 成功登录（默认用户 openruyi；root 不支持 ssh 登录）。

## 6. 常见问题

**测试说明：** 记录测试中可能遇到的问题及排查方法。

**问题 1：首次启动没有 `/tmp/cloud-init-test.log` 文件**

排查：`cloud-init status --long` 查看数据源状态；`lsblk -f | grep cidata` 或 `blkid | grep cidata` 检查卷标为 `cidata` 的设备是否存在。QEMU 中该盘可能显示为 `/dev/vdb`，可手动挂载验证：

```bash
mkdir /mnt/cidata
mount /dev/vdb /mnt/cidata
cat /mnt/cidata/user-data
cat /mnt/cidata/meta-data
```

原因：cloud-init 默认只在首次启动执行，后续启动不会重新执行。需要重置：

```bash
cloud-init clean --logs --reboot
```

或手动删除状态后重启：

```bash
rm -rf /var/lib/cloud/instances/*
rm -rf /var/log/cloud-init*
reboot
```

**预期结果：** 重置重启后即可看到 `/tmp/cloud-init-test.log` 生成。
