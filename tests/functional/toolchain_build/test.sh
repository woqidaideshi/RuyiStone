#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "准备临时目录并获取源码"
        TMPDIR="$(mktemp -d)"
        rlRun "git clone --depth=1 https://github.com/nihui/ruapu '$TMPDIR/ruapu'" 0 "下载 ruapu 源码"
    rlPhaseEnd

    rlPhaseStartTest "gcc 基础编译 hello.c"
        rlRun "printf '#include <stdio.h>\nint main(){printf(\"hello\\n\");return 0;}\n' > '$TMPDIR/hello.c'" 0 "创建 hello.c"
        rlRun "gcc '$TMPDIR/hello.c' -o '$TMPDIR/hello'" 0 "gcc 编译 hello.c"
        rlRun "'$TMPDIR/hello'" 0 "运行 hello"
        rlRun "file '$TMPDIR/hello' | grep -i elf" 0 "测试产物为 ELF"
    rlPhaseEnd

    rlPhaseStartTest "gcc 编译并运行 ruapu"
        rlRun "cd '$TMPDIR/ruapu' && gcc main.c -o ruapu" 0 "gcc 编译"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "运行 ruapu (gcc)"
    rlPhaseEnd

    rlPhaseStartTest "g++ 编译并运行 ruapu"
        rlRun "cd '$TMPDIR/ruapu' && g++ main.c -o ruapu" 0 "g++ 编译"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "运行 ruapu (g++)"
    rlPhaseEnd

    rlPhaseStartTest "clang 编译并运行 ruapu"
        rlRun "cd '$TMPDIR/ruapu' && clang main.c -o ruapu" 0 "clang 编译"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "运行 ruapu (clang)"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm -rf '$TMPDIR'" 0 "清理临时目录"
    rlPhaseEnd
rlJournalEnd
