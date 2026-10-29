#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "fetch ruapu source"
        TMPDIR="$(mktemp -d)"
        rlRun "git clone --depth=1 https://github.com/nihui/ruapu '$TMPDIR/ruapu'" 0 "download ruapu source"
    rlPhaseEnd

    rlPhaseStartTest "gcc compile hello.c"
        rlRun "printf '#include <stdio.h>\nint main(){printf(\"hello\\n\");return 0;}\n' > '$TMPDIR/hello.c'" 0 "create hello.c"
        rlRun "gcc '$TMPDIR/hello.c' -o '$TMPDIR/hello'" 0 "gcc compile hello.c"
        rlRun "'$TMPDIR/hello'" 0 "run hello"
        rlRun "file '$TMPDIR/hello' | grep -i elf" 0 "check output is ELF"
    rlPhaseEnd

    rlPhaseStartTest "gcc build ruapu"
        rlRun "cd '$TMPDIR/ruapu' && gcc main.c -o ruapu" 0 "gcc compile"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "run ruapu (gcc)"
    rlPhaseEnd

    rlPhaseStartTest "gxx build ruapu"
        rlRun "cd '$TMPDIR/ruapu' && g++ main.c -o ruapu" 0 "g++ compile"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "run ruapu (g++)"
    rlPhaseEnd

    rlPhaseStartTest "clang build ruapu"
        rlRun "cd '$TMPDIR/ruapu' && clang main.c -o ruapu" 0 "clang compile"
        rlRun "cd '$TMPDIR/ruapu' && ./ruapu" 0 "run ruapu (clang)"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm -rf '$TMPDIR'" 0 "clean up temp dir"
    rlPhaseEnd
rlJournalEnd
