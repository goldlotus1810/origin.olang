#!/bin/sh
tr '\n' ' ' < stdlib/homeos/_compile_one.txt > /tmp/_olang_eval_input.tmp
timeout 10 ./origin.olang --eval < /tmp/_olang_eval_input.tmp >/dev/null 2>/dev/null
exit 0
