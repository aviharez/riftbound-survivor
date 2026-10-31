#!/usr/bin/env bash
# Runs every headless test from CLAUDE.md. Each test must print its success line (regex, first argument
# of run) and no "SCRIPT ERROR". A parse error makes Godot hang instead of exiting, so every
# test has a timeout. usage: GODOT=/path/to/godot tools/run_tests.sh
set -u
G="${GODOT:-godot}"
T="${TEST_TIMEOUT:-500}"
cd "$(dirname "$0")/.."
fail=0
run() {
  local name="$1" ok_re="$2"; shift 2
  local log="/tmp/rb_test_${name}.log"
  local start=$(date +%s)
  timeout "$T" "$G" --headless --path . "$@" > "$log" 2>&1
  local code=$?
  local secs=$(( $(date +%s) - start ))
  if grep -q "SCRIPT ERROR" "$log" || ! grep -Eq "$ok_re" "$log" || [ $code -ne 0 ]; then
    echo "FAIL $name (exit $code, ${secs}s) -> $log"; grep -E "SCRIPT ERROR|FAIL|ERROR" "$log" | head -5; fail=1
  else
    echo "ok   $name (${secs}s) $(grep -E "$ok_re" "$log" | tail -1 | cut -c1-150)"
  fi
}
timeout "$T" "$G" --headless --path . --import > /tmp/rb_test_import.log 2>&1 || { echo "FAIL import"; fail=1; }
run mapgen "fails=0 " -s tests/test_mapgen.gd
run academy "academy tests: PASS" -s tests/test_academy.gd
run auto_4242 "\[autotest\] done" --fixed-fps 60 -- --autotest --seed=4242
run auto_slots4 "\[autotest\] done" --fixed-fps 60 -- --autotest --seed=565590 --slots=4
run die_77 "\[autotest\] done" --fixed-fps 60 -- --autotest-die --seed=77
run die_kael "\[autotest\] done" --fixed-fps 60 -- --autotest-die --seed=77 --char=kael
run late_99 "\[autotest\] done" --fixed-fps 60 -- --autotest-late --seed=99 --slots=4
run boss_lyra "\[autotest\] done" --fixed-fps 60 -- --autotest-boss --seed=31337 --char=lyra
run evolve_a "evolutions=\[\"[a-z]+\", \"[a-z]+\", \"[a-z]+\", \"[a-z]+\"\]" --fixed-fps 60 -- --autotest --seed=4242 --char=lyra --weapons=bolt,chain,meteor --ready-evolve --slots=4
run evolve_b "evolutions=\[\"[a-z]+\", \"[a-z]+\", \"[a-z]+\", \"[a-z]+\"\]" --fixed-fps 60 -- --autotest --seed=565590 --char=kael --weapons=void,lance,seed --ready-evolve --slots=4
run alpha_weapons "\[autotest\] done" --fixed-fps 60 -- --autotest --seed=31337 --char=astra --weapons=slash,chakram,familiar,beam,venom,mine --slots=4
exit $fail
