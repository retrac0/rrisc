#!/bin/env bash
# bash shell that tests the assembler and simulator

# -- assembler error tests --
# Each err-*.s is expected to fail; stderr must match the .err.expect file.

err_count=0
for test in tests/err-*.s; do
    base=$(basename $test .s)
    echo -n "testing $base..."
    python asm.py tests/$base.s 2>tests/$base.err
    if [ $? -eq 0 ]; then
        echo "FAIL: expected assembler error but assembly succeeded"
        exit 1
    fi
    if cmp -s tests/$base.err tests/$base.err.expect; then
        echo "PASS"
        err_count=$((err_count + 1))
    else
        echo "FAIL: error output does not match expected"
        diff tests/$base.err tests/$base.err.expect
        exit 1
    fi
done
echo "assembler error tests: $err_count passed"

# -- assembler + simulator tests --
# Each numbered *.s is assembled, binary compared, then simulated and output compared.

SIM2_MAXCYCLE=200000

sim_count=0
for test in tests/[0-9]*.s; do
    base=$(basename $test .s)
    echo -n "testing $base..."
    if ! python asm.py tests/$base.s; then
        echo "FAIL: assembly returned error"
        exit 1
    fi
    if cmp -s tests/$base.bin tests/$base.bin.expect; then
        echo -n "assemble..."
    else
        echo "FAIL: Assembled binary does not match expected output"
        exit 1
    fi

    # now run the simulator on the assembled binary and check for correct behavior
    echo -n "run... "
    if [ -f tests/$base.flags ]; then
        xargs -a tests/$base.flags python sim.py --summary tests/$base.bin > tests/$base.output
    else
        python sim.py --summary tests/$base.bin > tests/$base.output
    fi
    if cmp -s tests/$base.output tests/$base.output.expect; then
        echo -n "PASS"
    else
        echo "FAIL: Simulator output does not match expected output"
        exit 1
    fi

    if [ -f ./sim2 ]; then
        if [ -f tests/$base.flags ]; then
            xargs -a tests/$base.flags ./sim2 --maxcycle $SIM2_MAXCYCLE --summary tests/$base.bin > tests/$base.sim2.output
        else
            ./sim2 --maxcycle $SIM2_MAXCYCLE --summary tests/$base.bin > tests/$base.sim2.output
        fi
        if cmp -s tests/$base.sim2.output tests/$base.output.expect; then
            echo " (sim2 PASS)"
        else
            echo " (sim2 FAIL)"
            diff tests/$base.sim2.output tests/$base.output.expect
            exit 1
        fi
    else
        echo ""
    fi
    sim_count=$((sim_count + 1))
done
echo "assembler + simulator tests: $sim_count passed"

# -- examples build tests --
# Each example is assembled and then simulated to ensure the example program terminates.
examples_count=0
for test in examples/*.s; do
    base=$(basename $test .s)
    echo -n "testing example $base..."
    if ! python asm.py examples/$base.s; then
        echo "FAIL: assembly returned error"
        exit 1
    fi
    echo -n "run... "
    if python sim.py --terminal --summary examples/$base.bin > examples/$base.output 2>&1; then
        echo "PASS"
    else
        echo "FAIL: simulator returned error"
        cat examples/$base.output
        exit 1
    fi
    if [ -f ./sim2 ]; then
        if ./sim2 --maxcycle $SIM2_MAXCYCLE --summary examples/$base.bin > examples/$base.sim2.output 2>&1; then
            echo " (sim2 PASS)"
        else
            echo " (sim2 FAIL)"
            cat examples/$base.sim2.output
            exit 1
        fi
    fi
    examples_count=$((examples_count + 1))
done
echo "example builds: $examples_count passed"
