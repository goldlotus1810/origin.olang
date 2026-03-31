// stdlib/tools/batch_loader.ol — Multi-turn batch data loading. Pure Olang.
// Nox crashes at 200 learns/turn (heap temps). This loads ANY amount.

// ═══ MULTI-TURN BATCH LOADER ═══

// Each batch = 1 REPL turn. REPL frees temps between turns.
// Usage: pipe batches into origin.olang
//   emit batch_load_vad(0);
//   emit batch_load_vad(1);
//   emit batch_load_vad(2);
//   ...

let __batch_size = 150;  // safe per turn (200 max, 150 for safety margin)

// Load batch N of NRC-VAD (word\tV\tA format)
pub fn batch_load_vad(_n) {
    let _path = "json/nrc_vad_top10k.txt";
    let _content = __file_read(_path);
    if len(_content) == 0 { return "file not found"; };
    
    let _offset = _n * __batch_size;
    let _loaded = 0;
    let _line_num = 0;
    let _start = 0;
    let _i = 0;
    
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            if _line_num >= _offset {
                if _loaded >= __batch_size { 
                    __heap_pin();
                    return "batch " + __to_string(_n) + ": " + __to_string(_loaded) + " loaded. total=" + __to_string(kt_fact_count());
                };
                let _line = substr(_content, _start, _i);
                if len(_line) > 3 {
                    // Parse word\tV\tA
                    let _tab = 0;
                    while _tab < len(_line) {
                        if __char_code(char_at(_line, _tab)) == 9 { break; };
                        let _tab = _tab + 1;
                    };
                    if _tab > 1 {
                        if _tab < len(_line) {
                            let _word = substr(_line, 0, _tab);
                            let _rest = substr(_line, _tab + 1, len(_line));
                            let _v = __to_number(_rest);
                            let _label = "neutral";
                            if _v > 300 { let _label = "positive"; };
                            if _v > 700 { let _label = "very positive"; };
                            if _v < -300 { let _label = "negative"; };
                            if _v < -700 { let _label = "very negative"; };
                            kt_learn(_word + " means " + _label);
                            let _loaded = _loaded + 1;
                        };
                    };
                };
            };
            let _line_num = _line_num + 1;
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return "batch " + __to_string(_n) + ": " + __to_string(_loaded) + " loaded (LAST). total=" + __to_string(kt_fact_count());
}

// Load batch N of knowledge file (1 fact per line)
pub fn batch_load_knowledge(_n) {
    let _path = "homeos.knowledge";
    let _content = __file_read(_path);
    if len(_content) == 0 { return "file not found"; };
    
    let _offset = _n * __batch_size;
    let _loaded = 0;
    let _line_num = 0;
    let _start = 0;
    let _i = 0;
    
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            if _line_num >= _offset {
                if _loaded >= __batch_size {
                    __heap_pin();
                    return "batch " + __to_string(_n) + ": " + __to_string(_loaded) + " loaded. total=" + __to_string(kt_fact_count());
                };
                let _line = __str_trim(substr(_content, _start, _i));
                // Strip tag: prefix
                if len(_line) > 4 {
                    if substr(_line, 0, 4) == "tag:" {
                        let _sp = 4;
                        while _sp < len(_line) {
                            if __char_code(char_at(_line, _sp)) == 32 { break; };
                            let _sp = _sp + 1;
                        };
                        if _sp < len(_line) { let _line = substr(_line, _sp + 1, len(_line)); };
                    };
                };
                if len(_line) > 3 {
                    kt_learn(_line);
                    let _loaded = _loaded + 1;
                };
            };
            let _line_num = _line_num + 1;
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return "batch " + __to_string(_n) + ": " + __to_string(_loaded) + " loaded (LAST). total=" + __to_string(kt_fact_count());
}

// ═══ RAW LOADER — SKIP ENCODING ═══

// Load pre-computed mol\tfact pairs (nox_memory.dat format)
// ZERO temp strings → load unlimited
pub fn batch_load_raw(_path) {
    let _content = __file_read(_path);
    if len(_content) == 0 { return 0; };
    
    let _count = 0;
    let _start = 0;
    let _i = 0;
    
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _line = substr(_content, _start, _i);
            if len(_line) > 3 {
                let _tab = 0;
                while _tab < len(_line) {
                    if __char_code(char_at(_line, _tab)) == 9 { break; };
                    let _tab = _tab + 1;
                };
                if _tab > 0 {
                    if _tab < len(_line) {
                        let _mol = __to_number(substr(_line, 0, _tab));
                        let _fact = substr(_line, _tab + 1, len(_line));
                        if _mol > 0 {
                            if len(_fact) > 2 {
                                // Direct push — NO encoding, NO silk, NO word index
                                push(__kt_facts, _fact);
                                push(__kt_facts_mol, _mol);
                                let _idx = len(__kt_facts) - 1;
                                push(__kt_buckets[(_kt_mol_s(_mol) * 16) + _kt_mol_r(_mol)], _idx);
                                let _count = _count + 1;
                            };
                        };
                    };
                };
            };
            let _start = _i + 1;
        };
        let _i = _i + 1;
    };
    __heap_pin();
    return _count;
}

// ═══ COMPILER — Olang compiles knowledge. No Python. ═══

// Compile NRC-VAD txt → mol\tfact file (for raw loading)
// Run ONCE: emit compile_to_raw("json/nrc_vad_top10k.txt", "nrc_compiled.dat");
// Then: batch_load_raw("nrc_compiled.dat") → instant load
pub fn compile_to_raw(_input, _output) {
    // Clear output
    __file_write(_output, "");
    
    let _content = __file_read(_input);
    if len(_content) == 0 { return "empty"; };
    
    let _out = "";
    let _count = 0;
    let _start = 0;
    let _i = 0;
    
    while _i < len(_content) {
        if __char_code(char_at(_content, _i)) == 10 {
            let _line = substr(_content, _start, _i);
            if len(_line) > 3 {
                let _tab = 0;
                while _tab < len(_line) {
                    if __char_code(char_at(_line, _tab)) == 9 { break; };
                    let _tab = _tab + 1;
                };
                if _tab > 1 {
                    if _tab < len(_line) {
                        let _word = substr(_line, 0, _tab);
                        let _v_str = substr(_line, _tab + 1, len(_line));
                        let _v = __to_number(_v_str);
                        let _label = "neutral";
                        if _v > 300 { let _label = "positive"; };
                        if _v > 700 { let _label = "very positive"; };
                        if _v < -300 { let _label = "negative"; };
                        if _v < -700 { let _label = "very negative"; };
                        let _fact = _word + " means " + _label;
                        let _mol = _kt_real_mol(_word);
                        let _out = _out + __to_string(_mol) + "\t" + _fact + "\n";
                        let _count = _count + 1;
                    };
                };
            };
            let _start = _i + 1;
            // Flush to avoid huge string buildup
            if (_count % 200) == 0 {
                if _count > 0 {
                    __file_append(_output, _out);
                    let _out = "";
                    __heap_pin();
                };
            };
        };
        let _i = _i + 1;
    };
    if len(_out) > 0 { __file_append(_output, _out); };
    return __to_string(_count) + " compiled to " + _output;
}

// ═══ BATCH ORCHESTRATOR ═══

// Generate shell commands to load all data
pub fn batch_plan() {
    let _vad_lines = 10000;
    let _know_lines = 835;
    let _vad_batches = __floor(_vad_lines / __batch_size) + 1;
    let _know_batches = __floor(_know_lines / __batch_size) + 1;
    
    let _out = "#!/bin/bash\n# Auto-generated batch load script\n# Pipe into: bash load_all.sh\n\n";
    
    // Knowledge first (smaller, essential)
    let _out = _out + "echo 'Loading knowledge (" + __to_string(_know_batches) + " batches)...'\n";
    let _out = _out + "printf '";
    let _i = 0;
    while _i < _know_batches {
        let _out = _out + "emit batch_load_knowledge(" + __to_string(_i) + ");\\n";
        let _i = _i + 1;
    };
    let _out = _out + "' | ./origin.olang\n\n";
    
    // NRC-VAD (larger)
    let _out = _out + "echo 'Loading NRC-VAD (" + __to_string(_vad_batches) + " batches)...'\n";
    let _out = _out + "printf '";
    let _i = 0;
    while _i < _vad_batches {
        let _out = _out + "emit batch_load_vad(" + __to_string(_i) + ");\\n";
        let _i = _i + 1;
    };
    let _out = _out + "' | ./origin.olang\n\n";
    
    let _out = _out + "echo 'Saving memory...'\n";
    let _out = _out + "echo 'kt_save(\"nox_memory.dat\");' | ./origin.olang\n";
    let _out = _out + "echo 'DONE'\n";
    
    return _out;
}

// Status: how many batches loaded
pub fn batch_status() {
    return "facts: " + __to_string(kt_fact_count()) 
         + " | cap: 8192"
         + " | batch_size: " + __to_string(__batch_size)
         + " | max_batches: " + __to_string(__floor(8192 / __batch_size));
}
