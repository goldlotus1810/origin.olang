// ═══ Nox Brain — Main Entry Point ═══
// Full stack: knowtree + silk + persist + feedback + generate + brain_v3
// Boot → Interactive REPL → Shutdown
//
// Usage: ./nox_brain.olang
// Or pipe: echo "query" | ./nox_brain.olang

import "stdlib/core.ol";
import "stdlib/knowtree.ol";
import "stdlib/silk.ol";
import "stdlib/persist.ol";
import "stdlib/feedback.ol";
import "stdlib/generate.ol";
import "stdlib/brain_v3.ol";

// ═══ BOOT ═══
let _data_dir = "data";
let booted = brain_boot(_data_dir);
emit "Nox brain ready. " + __to_string(__array_get(kt_count, 0)) + " facts loaded.";

// ═══ INTERACTIVE LOOP ═══
// Read queries from stdin, respond, loop until EOF
let _running = [1];
while __array_get(_running, 0) == 1 {
    emit "> ";
    let input = __readline();
    if len(input) == 0 {
        // EOF or empty → exit
        let _ = __set_at(_running, 0, 0);
    } else {
        // Check commands
        if __str_starts_with(input, "/quit") == 1 {
            let _ = __set_at(_running, 0, 0);
        } else {
        if __str_starts_with(input, "/learn ") == 1 {
            let fact = substr(input, 7, len(input));
            brain_learn(fact);
            emit "Learned: " + fact;
        } else {
        if __str_starts_with(input, "/save") == 1 {
            let n = brain_save();
            emit "Saved " + __to_string(n) + " items.";
        } else {
        if __str_starts_with(input, "/count") == 1 {
            emit "Facts: " + __to_string(__array_get(kt_count, 0));
        } else {
        if __str_starts_with(input, "/status") == 1 {
            emit "Facts: " + __to_string(__array_get(kt_count, 0));
            emit "Heap: " + __to_string(__heap_used());
        } else {
            // Normal query → generate response
            let response = ptav_cycle(input);
            if len(response) > 0 {
                emit response;
            } else {
                emit "I don't know enough about that.";
            };
        };};};};};
    };
};

// ═══ SHUTDOWN ═══
brain_shutdown();
emit "Nox brain shutdown. Knowledge saved.";
