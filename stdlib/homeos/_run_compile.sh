#!/bin/sh
tr '\n' ' ' < stdlib/homeos/_compile_one.txt | timeout 60 ./origin.olang --eval 2>/dev/null
exit 0
