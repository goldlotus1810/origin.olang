// stdlib/tools/binary_reader.ol — Read structured binary data. Pure Olang.
// LLM: pre-trained on structured data. Nox: raw bytes. This parses.

// ═══ P_WEIGHT TABLE READER ═══

// Read P_weight for codepoint from udc_p_table.bin
// Table format: [u16] × 196,608 entries, little-endian
// Codepoint cp → table[cp] → 16-bit P_weight (SRVAT packed)
pub fn pw_lookup(_cp) {
    let _bytes = __file_read_bytes("json/udc_p_table.bin");
    if len(_bytes) == 0 { return 0; };
    let _offset = _cp * 2;
    if _offset + 1 >= len(_bytes) { return 0; };
    let _lo = __bytes_get(_bytes, _offset);
    let _hi = __bytes_get(_bytes, _offset + 1);
    return _lo + _hi * 256;
}

// Unpack P_weight into [S, R, V, A, T]
pub fn pw_unpack(_pw) {
    let _s = __floor(_pw / 4096) % 16;
    let _r = __floor(_pw / 256) % 16;
    let _v = __floor(_pw / 32) % 8;
    let _a = __floor(_pw / 4) % 8;
    let _t = _pw % 4;
    return [_s, _r, _v, _a, _t];
}

// P_weight summary for a codepoint
pub fn pw_info(_cp) {
    let _pw = pw_lookup(_cp);
    if _pw == 0 { return "cp=" + __to_string(_cp) + " → no P_weight"; };
    let _dims = pw_unpack(_pw);
    return "cp=" + __to_string(_cp) 
         + " pw=" + __to_string(_pw)
         + " S=" + __to_string(__array_get(_dims, 0))
         + " R=" + __to_string(__array_get(_dims, 1))
         + " V=" + __to_string(__array_get(_dims, 2))
         + " A=" + __to_string(__array_get(_dims, 3))
         + " T=" + __to_string(__array_get(_dims, 4));
}

// P_weight for character (wraps codepoint lookup)
pub fn pw_char(_ch) {
    return pw_lookup(__char_code(_ch));
}

// ═══ NRC-VAD BINARY READER ═══

// NRC-VAD binary format: [f32 valence][f32 arousal][f32 dominance] per entry
// 54,801 entries × 12 bytes = ~640KB (but actual file = 256KB, different format)
// Actual: hash-indexed binary, need to check format

// Read NRC-VAD binary stats
pub fn nrc_stats() {
    let _bytes = __file_read_bytes("json/nrc_vad.bin");
    let _size = len(_bytes);
    return "nrc_vad.bin: " + __to_string(_size) + " bytes"
         + " = " + __to_string(_size / 4) + " u32 entries"
         + " or " + __to_string(_size / 12) + " triplets (V,A,D)";
}

// ═══ DATA ANALYZER ═══

// Analyze json/ directory
pub fn data_inventory() {
    let _files = __readdir("json");
    let _out = "=== json/ DATA INVENTORY ===\n";
    let _total_files = 0;
    let _i = 0;
    while _i < len(_files) {
        let _name = __array_get(_files, _i);
        let _path = "json/" + _name;
        let _content = __file_read(_path);
        let _size = len(_content);
        let _lines = 0;
        if _size > 0 {
            let _j = 0;
            while _j < _size {
                if __char_code(char_at(_content, _j)) == 10 { let _lines = _lines + 1; };
                let _j = _j + 1;
            };
        };
        let _size_str = __to_string(_size);
        if _size > 1024 { let _size_str = __to_string(__floor(_size / 1024)) + "KB"; };
        if _size > 1048576 { let _size_str = __to_string(__floor(_size / 1048576)) + "MB"; };
        let _out = _out + "  " + _name + ": " + _size_str + " (" + __to_string(_lines) + " lines)\n";
        let _total_files = _total_files + 1;
        let _i = _i + 1;
    };
    
    // Also check json/json/ subdirectory
    let _subfiles = __readdir("json/json");
    let _sub_count = len(_subfiles);
    let _out = _out + "  json/json/: " + __to_string(_sub_count) + " files (Unicode DB)\n";
    let _total_files = _total_files + _sub_count;
    
    let _out = _out + "TOTAL: " + __to_string(_total_files) + " files\n";
    return _out;
}

// Analyze KnowTree distribution
pub fn kt_distribution() {
    let _out = "=== KNOWTREE DISTRIBUTION ===\n";
    let _out = _out + "Facts: " + __to_string(kt_fact_count()) + "\n";
    
    // Count facts per S dimension (0-15)
    let _s_counts = [];
    let _i = 0;
    while _i < 16 { push(_s_counts, 0); let _i = _i + 1; };
    
    let _v_counts = [];
    let _i = 0;
    while _i < 8 { push(_v_counts, 0); let _i = _i + 1; };
    
    let _i = 0;
    while _i < len(__kt_facts_mol) {
        let _mol = __array_get(__kt_facts_mol, _i);
        let _s = _kt_mol_s(_mol);
        let _v = _kt_mol_v(_mol);
        set_at(_s_counts, _s, __array_get(_s_counts, _s) + 1);
        set_at(_v_counts, _v, __array_get(_v_counts, _v) + 1);
        let _i = _i + 1;
    };
    
    let _out = _out + "S distribution: ";
    let _i = 0;
    while _i < 16 {
        let _c = __array_get(_s_counts, _i);
        if _c > 0 { let _out = _out + "S" + __to_string(_i) + "=" + __to_string(_c) + " "; };
        let _i = _i + 1;
    };
    
    let _out = _out + "\nV distribution: ";
    let _i = 0;
    while _i < 8 {
        let _c = __array_get(_v_counts, _i);
        if _c > 0 { let _out = _out + "V" + __to_string(_i) + "=" + __to_string(_c) + " "; };
        let _i = _i + 1;
    };
    
    return _out + "\n";
}

// P_weight table coverage stats
pub fn pw_coverage() {
    let _bytes = __file_read_bytes("json/udc_p_table.bin");
    if len(_bytes) == 0 { return "P_weight table not found"; };
    
    let _total = len(_bytes) / 2;
    let _nonzero = 0;
    let _i = 0;
    while _i < len(_bytes) {
        if __bytes_get(_bytes, _i) > 0 { let _nonzero = _nonzero + 1; };
        let _i = _i + 2;  // skip to next u16
    };
    
    return "P_weight table: " + __to_string(_total) + " entries, " 
         + __to_string(_nonzero) + " non-zero ("
         + __to_string(__floor(_nonzero * 100 / _total)) + "%)";
}
