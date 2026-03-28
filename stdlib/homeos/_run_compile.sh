#!/bin/sh
# Compile one .ol file via subprocess
# Path is read from /tmp/_olang_src_path.tmp
# Result written to /tmp/_olang_bc.tmp
tr '\n' ' ' < stdlib/homeos/_compile_one.txt > /tmp/_olang_eval_input.tmp
timeout 30 ./origin.olang --eval < /tmp/_olang_eval_input.tmp 2>/dev/null
exit 0
