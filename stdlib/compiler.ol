// ═══════════════════════════════════════════════════════════════
// Nox Self-Hosting Compiler — Olang → VM v2 Bytecode
// Reads .ol source, emits OLNG bytecode, appends to VM binary.
// ═══════════════════════════════════════════════════════════════

// ── Token types ──
let TK_NUM = 1;
let TK_STR = 2;
let TK_IDENT = 3;
let TK_OP = 4;
let TK_SEMI = 5;
let TK_LPAREN = 6;
let TK_RPAREN = 7;
let TK_LBRACE = 8;
let TK_RBRACE = 9;
let TK_LBRACKET = 10;
let TK_RBRACKET = 11;
let TK_COMMA = 12;
let TK_ASSIGN = 13;
let TK_EOF = 14;
let TK_LET = 20;
let TK_FN = 21;
let TK_IF = 22;
let TK_ELSE = 23;
let TK_WHILE = 24;
let TK_RETURN = 25;
let TK_EMIT = 26;
let TK_TRUE = 27;
let TK_FALSE = 28;
let TK_TRY = 31;
let TK_CATCH = 32;
let TK_THROW = 33;
let TK_BREAK = 34;
let TK_CONTINUE = 35;
let TK_FOR = 36;
let TK_IN = 37;
let TK_MATCH = 38;
let TK_ARROW = 39;
let TK_IMPORT = 40;
let TK_COLON = 30;

// ── AST node types ──
let AST_NUM = 1;
let AST_STR = 2;
let AST_VAR = 3;
let AST_LET = 4;
let AST_BINOP = 5;
let AST_CALL = 6;
let AST_FN = 7;
let AST_BLOCK = 8;
let AST_IF = 9;
let AST_WHILE = 10;
let AST_RETURN = 11;
let AST_EMIT = 12;
let AST_PROGRAM = 13;
let AST_EXPR_STMT = 14;
let AST_ASSIGN = 15;
let AST_ARRAY = 16;
let AST_AND = 17;
let AST_OR = 18;
let AST_TRY = 20;
let AST_THROW = 21;
let AST_BREAK = 22;
let AST_CONTINUE = 23;

// ── Opcodes ──
let OP_PUSH = 0x01;
let OP_LOAD = 0x02;
let OP_EMIT = 0x06;
let OP_CALL = 0x07;
let OP_RET = 0x08;
let OP_JMP = 0x09;
let OP_JZ = 0x0A;
let OP_DUP = 0x0B;
let OP_POP = 0x0C;
let OP_LOOP = 0x0E;
let OP_HALT = 0x0F;
let OP_STORE = 0x13;
let OP_STORE_LOCAL = 0x16;
let OP_PUSH_NUM = 0x15;
let OP_CLOSURE = 0x25;
let OP_ADD = 0x2A;
let OP_SUB = 0x2B;
let OP_MUL = 0x2C;
let OP_DIV = 0x2D;
let OP_MOD = 0x2E;
let OP_EQ = 0x31;
let OP_NE = 0x32;
let OP_LT = 0x33;
let OP_GT = 0x34;
let OP_LE = 0x35;
let OP_GE = 0x36;
let OP_CLOSURE_CAP = 0x30;
let OP_TRY_BEGIN = 0x1A;
let OP_CATCH_END = 0x1B;
let OP_THROW = 0x78;

// ═══ Global state ═══
let g_source = "";
let g_source_len = 0;
let g_tokens = [];
let g_tok_types = [];
let g_tok_values = [];
let g_tok_count = 0;
let g_pos = 0;
let g_code = [];       // bytecode output (array of bytes)
let g_break_patches = [];  // break jump offsets to patch
let g_loop_start = 0;     // loop start offset for continue
let g_fn_depth = 0;       // function nesting depth (0 = top level)
let g_for_id = 0;        // unique ID for for loop desugar names

// ═══════════════════════════════════════════════════════════════
// LEXER
// ═══════════════════════════════════════════════════════════════

fn is_digit(c) {
    let code = __char_code(c);
    return code >= 48 && code <= 57;
};

fn is_alpha(c) {
    let code = __char_code(c);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code == 95;
};

fn is_alnum(c) {
    return is_digit(c) || is_alpha(c);
};

fn is_space(c) {
    let code = __char_code(c);
    return code == 32 || code == 9 || code == 13 || code == 10;
};

fn add_token(typ, val) {
    push(g_tok_types, typ);
    push(g_tok_values, val);
    g_tok_count = g_tok_count + 1;
};

fn lex(source) {
    g_source = source;
    g_source_len = len(source);
    let i = 0;
    while i < g_source_len {
        let c = char_at(source, i);
        let code = __char_code(c);

        // Skip whitespace
        if is_space(c) { i = i + 1; } else {

        // Skip line comments (// or #)
        if c == "/" && i + 1 < g_source_len && char_at(source, i + 1) == "/" {
            while i < g_source_len && __char_code(char_at(source, i)) != 10 {
                i = i + 1;
            };
        } else {
        if c == "#" {
            while i < g_source_len && __char_code(char_at(source, i)) != 10 {
                i = i + 1;
            };
        } else {

        // Numbers (decimal and 0x hex)
        if is_digit(c) {
            let start = i;
            if c == "0" && i + 1 < g_source_len && char_at(source, i + 1) == "x" {
                i = i + 2;
                while i < g_source_len && is_alnum(char_at(source, i)) {
                    i = i + 1;
                };
            } else {
                while i < g_source_len && (is_digit(char_at(source, i)) || char_at(source, i) == ".") {
                    i = i + 1;
                };
            };
            let num_str = substr(source, start, i);
            let val = parse_number(num_str);
            add_token(TK_NUM, val);
        } else {

        // Strings (use char codes to avoid escape dependency)
        if __char_code(c) == 34 {
            i = i + 1;
            let start = i;
            while i < g_source_len && __char_code(char_at(source, i)) != 34 {
                if __char_code(char_at(source, i)) == 92 { i = i + 1; };
                i = i + 1;
            };
            let str_val = substr(source, start, i);
            i = i + 1;
            add_token(TK_STR, str_val);
        } else {

        // Identifiers / keywords
        if is_alpha(c) {
            let start = i;
            while i < g_source_len && is_alnum(char_at(source, i)) {
                i = i + 1;
            };
            let word = substr(source, start, i);
            let kw = 0;
            if word == "let" { add_token(TK_LET, word); kw = 1; };
            if kw == 0 && word == "fn" { add_token(TK_FN, word); kw = 1; };
            if kw == 0 && word == "if" { add_token(TK_IF, word); kw = 1; };
            if kw == 0 && word == "else" { add_token(TK_ELSE, word); kw = 1; };
            if kw == 0 && word == "while" { add_token(TK_WHILE, word); kw = 1; };
            if kw == 0 && word == "return" { add_token(TK_RETURN, word); kw = 1; };
            if kw == 0 && word == "emit" { add_token(TK_EMIT, word); kw = 1; };
            if kw == 0 && word == "true" { add_token(TK_TRUE, word); kw = 1; };
            if kw == 0 && word == "false" { add_token(TK_FALSE, word); kw = 1; };
            if kw == 0 && word == "try" { add_token(TK_TRY, word); kw = 1; };
            if kw == 0 && word == "catch" { add_token(TK_CATCH, word); kw = 1; };
            if kw == 0 && word == "throw" { add_token(TK_THROW, word); kw = 1; };
            if kw == 0 && word == "break" { add_token(TK_BREAK, word); kw = 1; };
            if kw == 0 && word == "continue" { add_token(TK_CONTINUE, word); kw = 1; };
            if kw == 0 && word == "for" { add_token(TK_FOR, word); kw = 1; };
            if kw == 0 && word == "in" { add_token(TK_IN, word); kw = 1; };
            if kw == 0 && word == "match" { add_token(TK_MATCH, word); kw = 1; };
            if kw == 0 && word == "import" { add_token(TK_IMPORT, word); kw = 1; };
            if kw == 0 { add_token(TK_IDENT, word); };
        } else {

        // Two-char operators
        if c == "=" && i + 1 < g_source_len && char_at(source, i + 1) == ">" {
            add_token(TK_ARROW, "=>"); i = i + 2;
        } else {
        if c == "=" && i + 1 < g_source_len && char_at(source, i + 1) == "=" {
            add_token(TK_OP, "=="); i = i + 2;
        } else {
        if c == "!" && i + 1 < g_source_len && char_at(source, i + 1) == "=" {
            add_token(TK_OP, "!="); i = i + 2;
        } else {
        if c == "!" {
            add_token(TK_OP, "!"); i = i + 1;
        } else {
        if c == "<" && i + 1 < g_source_len && char_at(source, i + 1) == "=" {
            add_token(TK_OP, "<="); i = i + 2;
        } else {
        if c == ">" && i + 1 < g_source_len && char_at(source, i + 1) == "=" {
            add_token(TK_OP, ">="); i = i + 2;
        } else {
        if c == "&" && i + 1 < g_source_len && char_at(source, i + 1) == "&" {
            add_token(TK_OP, "&&"); i = i + 2;
        } else {
        if c == "|" && i + 1 < g_source_len && char_at(source, i + 1) == "|" {
            add_token(TK_OP, "||"); i = i + 2;
        } else {

        // Single-char tokens
        if c == "+" || c == "-" || c == "*" || c == "/" || c == "%" || c == "<" || c == ">" {
            add_token(TK_OP, c); i = i + 1;
        } else {
        if c == "=" { add_token(TK_ASSIGN, c); i = i + 1; } else {
        if c == ";" { add_token(TK_SEMI, c); i = i + 1; } else {
        if c == "(" { add_token(TK_LPAREN, c); i = i + 1; } else {
        if c == ")" { add_token(TK_RPAREN, c); i = i + 1; } else {
        if c == "{" { add_token(TK_LBRACE, c); i = i + 1; } else {
        if c == "}" { add_token(TK_RBRACE, c); i = i + 1; } else {
        if c == "[" { add_token(TK_LBRACKET, c); i = i + 1; } else {
        if c == "]" { add_token(TK_RBRACKET, c); i = i + 1; } else {
        if c == "," { add_token(TK_COMMA, c); i = i + 1; } else {
        if c == ":" { add_token(TK_COLON, c); i = i + 1; } else {
        if c == "." { add_token(TK_OP, c); i = i + 1; } else {
            // Unknown char, skip
            i = i + 1;
        };};};};};};};};};};};};};};};};};};};}; }; }; }; }; }; };
    };
    add_token(TK_EOF, "");
};

fn parse_number(s) {
    let result = 0;
    let i = 0;
    let neg = 0;
    let slen = len(s);
    if slen > 0 && char_at(s, 0) == "-" {
        neg = 1;
        i = 1;
    };
    // Check 0x prefix
    if i + 1 < slen && char_at(s, i) == "0" && char_at(s, i + 1) == "x" {
        i = i + 2;
        while i < slen {
            let d = __char_code(char_at(s, i));
            if d >= 48 && d <= 57 { result = result * 16 + d - 48; } else {
            if d >= 97 && d <= 102 { result = result * 16 + d - 87; } else {
            if d >= 65 && d <= 70 { result = result * 16 + d - 55; }; }; };
            i = i + 1;
        };
    } else {
        // Decimal
        let has_dot = 0;
        let frac = 0;
        let frac_div = 1;
        while i < slen {
            let ch = char_at(s, i);
            if ch == "." {
                has_dot = 1;
            } else {
                let d = __char_code(ch) - 48;
                if has_dot == 0 {
                    result = result * 10 + d;
                } else {
                    frac = frac * 10 + d;
                    frac_div = frac_div * 10;
                };
            };
            i = i + 1;
        };
        if has_dot == 1 {
            result = result + frac / frac_div;
        };
    };
    if neg == 1 { result = 0 - result; };
    return result;
};

// ═══════════════════════════════════════════════════════════════
// PARSER — tokens → AST (arrays)
// ═══════════════════════════════════════════════════════════════

fn peek_type() { return __array_get(g_tok_types, g_pos); };
fn peek_val()  { return __array_get(g_tok_values, g_pos); };
fn advance()   { g_pos = g_pos + 1; return __array_get(g_tok_values, g_pos - 1); };
fn expect(kind) {
    if peek_type() != kind {
        emit "Parse error: unexpected token";
        emit peek_val();
    };
    return advance();
};
fn match_tok(kind) {
    if peek_type() == kind { advance(); return 1; };
    return 0;
};

fn parse_program() {
    let stmts = [];
    while peek_type() != TK_EOF {
        push(stmts, parse_statement());
    };
    let node = [];
    push(node, AST_PROGRAM);
    push(node, stmts);
    return node;
};

fn parse_try() {
    expect(TK_TRY);
    let body = parse_block();
    expect(TK_CATCH);
    expect(TK_LPAREN);
    let var_name = expect(TK_IDENT);
    expect(TK_RPAREN);
    let handler = parse_block();
    let node = [];
    push(node, AST_TRY);
    push(node, body);
    push(node, var_name);
    push(node, handler);
    return node;
};

fn parse_throw() {
    expect(TK_THROW);
    let val = parse_expr();
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_THROW);
    push(node, val);
    return node;
};

fn parse_break() {
    expect(TK_BREAK);
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_BREAK);
    return node;
};

fn parse_continue() {
    expect(TK_CONTINUE);
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_CONTINUE);
    return node;
};

fn parse_for() {
    expect(TK_FOR);
    let var_name = expect(TK_IDENT);
    expect(TK_IN);
    let arr_expr = parse_expr();
    let body = parse_block();
    // Unique names for nested for loops
    let fid = __to_string(g_for_id);
    g_for_id = g_for_id + 1;
    let arr_name = "__fa" + fid;
    let idx_name = "__fi" + fid;
    let arr_let = [];
    push(arr_let, AST_LET);
    push(arr_let, arr_name);
    push(arr_let, arr_expr);
    let idx_zero = [];
    push(idx_zero, AST_NUM);
    push(idx_zero, 0);
    let idx_let = [];
    push(idx_let, AST_LET);
    push(idx_let, idx_name);
    push(idx_let, idx_zero);
    let arr_var = [];
    push(arr_var, AST_VAR);
    push(arr_var, arr_name);
    let len_args = [];
    push(len_args, arr_var);
    let len_call = [];
    push(len_call, AST_CALL);
    push(len_call, "len");
    push(len_call, len_args);
    let idx_var = [];
    push(idx_var, AST_VAR);
    push(idx_var, idx_name);
    let cond = [];
    push(cond, AST_BINOP);
    push(cond, "<");
    push(cond, idx_var);
    push(cond, len_call);
    let av2 = [];
    push(av2, AST_VAR);
    push(av2, arr_name);
    let iv2 = [];
    push(iv2, AST_VAR);
    push(iv2, idx_name);
    let get_args = [];
    push(get_args, av2);
    push(get_args, iv2);
    let get_call = [];
    push(get_call, AST_CALL);
    push(get_call, "__array_get");
    push(get_call, get_args);
    let var_let = [];
    push(var_let, AST_LET);
    push(var_let, var_name);
    push(var_let, get_call);
    let iv3 = [];
    push(iv3, AST_VAR);
    push(iv3, idx_name);
    let one = [];
    push(one, AST_NUM);
    push(one, 1);
    let inc = [];
    push(inc, AST_BINOP);
    push(inc, "+");
    push(inc, iv3);
    push(inc, one);
    let inc_assign = [];
    push(inc_assign, AST_ASSIGN);
    push(inc_assign, idx_name);
    push(inc_assign, inc);
    // While body: [var_let, inc_assign, body_stmts...]
    // inc BEFORE body so continue doesn't skip it
    let body_stmts = __array_get(body, 1);
    let while_stmts = [];
    push(while_stmts, var_let);
    push(while_stmts, inc_assign);
    let si = 0;
    while si < len(body_stmts) {
        push(while_stmts, __array_get(body_stmts, si));
        si = si + 1;
    };
    let while_body = [];
    push(while_body, AST_BLOCK);
    push(while_body, while_stmts);
    let while_node = [];
    push(while_node, AST_WHILE);
    push(while_node, cond);
    push(while_node, while_body);
    // Block: [arr_let, idx_let, while_node]
    let block_stmts = [];
    push(block_stmts, arr_let);
    push(block_stmts, idx_let);
    push(block_stmts, while_node);
    let block = [];
    push(block, AST_BLOCK);
    push(block, block_stmts);
    return block;
};

fn parse_match() {
    expect(TK_MATCH);
    let val = parse_expr();
    expect(TK_LBRACE);
    let val_let = [];
    push(val_let, AST_LET);
    push(val_let, "__match_val");
    push(val_let, val);
    // Collect arms: [pat_or_0, body] pairs
    let arms_pat = [];
    let arms_body = [];
    while peek_type() != TK_RBRACE {
        if peek_type() == TK_IDENT && peek_val() == "_" {
            advance();
            push(arms_pat, 0);
        } else {
            push(arms_pat, parse_expr());
        };
        expect(TK_ARROW);
        let stmt = parse_statement();
        let body_stmts = [];
        push(body_stmts, stmt);
        let body = [];
        push(body, AST_BLOCK);
        push(body, body_stmts);
        push(arms_body, body);
    };
    expect(TK_RBRACE);
    match_tok(TK_SEMI);
    // Build if/else chain from LAST to FIRST
    let result = 0;
    let ai = len(arms_pat) - 1;
    while ai >= 0 {
        let pat = __array_get(arms_pat, ai);
        let body = __array_get(arms_body, ai);
        if pat == 0 {
            result = body;
        } else {
            let mv = [];
            push(mv, AST_VAR);
            push(mv, "__match_val");
            let cond = [];
            push(cond, AST_BINOP);
            push(cond, "==");
            push(cond, mv);
            push(cond, pat);
            let if_node = [];
            push(if_node, AST_IF);
            push(if_node, cond);
            push(if_node, body);
            push(if_node, result);
            result = if_node;
        };
        ai = ai - 1;
    };
    let block_stmts = [];
    push(block_stmts, val_let);
    if result != 0 { push(block_stmts, result); };
    let block = [];
    push(block, AST_BLOCK);
    push(block, block_stmts);
    return block;
};

fn parse_statement() {
    let t = peek_type();
    if t == TK_TRY { return parse_try(); };
    if t == TK_THROW { return parse_throw(); };
    if t == TK_BREAK { return parse_break(); };
    if t == TK_CONTINUE { return parse_continue(); };
    if t == TK_FOR { return parse_for(); };
    if t == TK_MATCH { return parse_match(); };
    if t == TK_IMPORT {
        advance();
        if peek_type() == 2 { advance(); };
        match_tok(TK_SEMI);
        let nop = [];
        push(nop, AST_BLOCK);
        push(nop, []);
        return nop;
    };
    if t == TK_LET { return parse_let(); };
    if t == TK_FN { return parse_fn(); };
    if t == TK_IF { return parse_if(); };
    if t == TK_WHILE { return parse_while(); };
    if t == TK_RETURN { return parse_return(); };
    if t == TK_EMIT { return parse_emit(); };
    // Check for assignment: ident = expr, ident[i] = val, ident.field = val
    if t == TK_IDENT {
        let next_type = __array_get(g_tok_types, g_pos + 1);
        if next_type == TK_ASSIGN {
            let name = advance();
            advance();
            let val = parse_expr();
            match_tok(TK_SEMI);
            let node = [];
            push(node, AST_ASSIGN);
            push(node, name);
            push(node, val);
            return node;
        };
        if next_type == TK_LBRACKET {
            let name = advance();
            advance();
            let idx = parse_expr();
            expect(TK_RBRACKET);
            if peek_type() == TK_ASSIGN {
                advance();
                let val = parse_expr();
                match_tok(TK_SEMI);
                let arr_node = [];
                push(arr_node, AST_VAR);
                push(arr_node, name);
                let args = [];
                push(args, arr_node);
                push(args, idx);
                push(args, val);
                let call = [];
                push(call, AST_CALL);
                push(call, "__set_at");
                push(call, args);
                let stmt = [];
                push(stmt, AST_EXPR_STMT);
                push(stmt, call);
                return stmt;
            };
        };
        if next_type == TK_OP && __array_get(g_tok_values, g_pos + 1) == "." {
            let save_pos = g_pos;
            let name = advance();
            advance();
            let field = advance();
            if peek_type() == TK_ASSIGN {
                advance();
                let val = parse_expr();
                match_tok(TK_SEMI);
                let obj_node = [];
                push(obj_node, AST_VAR);
                push(obj_node, name);
                let fname = [];
                push(fname, AST_STR);
                push(fname, field);
                let args = [];
                push(args, obj_node);
                push(args, fname);
                push(args, val);
                let call = [];
                push(call, AST_CALL);
                push(call, "__dict_set");
                push(call, args);
                let stmt = [];
                push(stmt, AST_EXPR_STMT);
                push(stmt, call);
                return stmt;
            } else {
                g_pos = save_pos;
            };
        };
    };
    let expr = parse_expr();
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_EXPR_STMT);
    push(node, expr);
    return node;
};

fn parse_let() {
    expect(TK_LET);
    let name = expect(TK_IDENT);
    expect(TK_ASSIGN);
    let val = parse_expr();
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_LET);
    push(node, name);
    push(node, val);
    return node;
};

fn parse_fn() {
    expect(TK_FN);
    let name = expect(TK_IDENT);
    expect(TK_LPAREN);
    let params = [];
    while peek_type() != TK_RPAREN {
        push(params, expect(TK_IDENT));
        if peek_type() != TK_RPAREN { expect(TK_COMMA); };
    };
    expect(TK_RPAREN);
    let body = parse_block();
    let node = [];
    push(node, AST_FN);
    push(node, name);
    push(node, params);
    push(node, body);
    return node;
};

fn parse_if() {
    expect(TK_IF);
    let cond = parse_expr();
    let then_b = parse_block();
    let else_b = 0;
    if peek_type() == TK_ELSE {
        advance();
        if peek_type() == TK_IF {
            else_b = parse_if();
        } else {
            else_b = parse_block();
        };
    };
    let node = [];
    push(node, AST_IF);
    push(node, cond);
    push(node, then_b);
    push(node, else_b);
    return node;
};

fn parse_while() {
    expect(TK_WHILE);
    let cond = parse_expr();
    let body = parse_block();
    let node = [];
    push(node, AST_WHILE);
    push(node, cond);
    push(node, body);
    return node;
};

fn parse_return() {
    expect(TK_RETURN);
    let val = 0;
    if peek_type() != TK_SEMI && peek_type() != TK_RBRACE {
        val = parse_expr();
    };
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_RETURN);
    push(node, val);
    return node;
};

fn parse_emit() {
    expect(TK_EMIT);
    let val = parse_expr();
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_EMIT);
    push(node, val);
    return node;
};

fn parse_block() {
    expect(TK_LBRACE);
    let stmts = [];
    while peek_type() != TK_RBRACE {
        push(stmts, parse_statement());
    };
    expect(TK_RBRACE);
    match_tok(TK_SEMI);
    let node = [];
    push(node, AST_BLOCK);
    push(node, stmts);
    return node;
};

fn parse_expr() { return parse_or(); };

fn parse_or() {
    let left = parse_and();
    while peek_type() == TK_OP && peek_val() == "||" {
        advance();
        let right = parse_and();
        let node = [];
        push(node, AST_OR);
        push(node, left);
        push(node, right);
        left = node;
    };
    return left;
};

fn parse_and() {
    let left = parse_comparison();
    while peek_type() == TK_OP && peek_val() == "&&" {
        advance();
        let right = parse_comparison();
        let node = [];
        push(node, AST_AND);
        push(node, left);
        push(node, right);
        left = node;
    };
    return left;
};

fn parse_comparison() {
    let left = parse_addition();
    while peek_type() == TK_OP {
        let op = peek_val();
        if op == "==" || op == "!=" || op == "<" || op == ">" || op == "<=" || op == ">=" {
            advance();
            let right = parse_addition();
            let node = [];
            push(node, AST_BINOP);
            push(node, op);
            push(node, left);
            push(node, right);
            left = node;
        } else {
            return left;
        };
    };
    return left;
};

fn parse_addition() {
    let left = parse_multiplication();
    while peek_type() == TK_OP && (peek_val() == "+" || peek_val() == "-") {
        let op = advance();
        let right = parse_multiplication();
        let node = [];
        push(node, AST_BINOP);
        push(node, op);
        push(node, left);
        push(node, right);
        left = node;
    };
    return left;
};

fn parse_multiplication() {
    let left = parse_unary();
    while peek_type() == TK_OP && (peek_val() == "*" || peek_val() == "/" || peek_val() == "%") {
        let op = advance();
        let right = parse_unary();
        let node = [];
        push(node, AST_BINOP);
        push(node, op);
        push(node, left);
        push(node, right);
        left = node;
    };
    return left;
};

fn parse_unary() {
    if peek_type() == TK_OP && peek_val() == "-" {
        advance();
        let expr = parse_primary();
        let zero = [];
        push(zero, AST_NUM);
        push(zero, 0);
        let node = [];
        push(node, AST_BINOP);
        push(node, "-");
        push(node, zero);
        push(node, expr);
        return node;
    };
    if peek_type() == TK_OP && peek_val() == "!" {
        advance();
        let expr = parse_unary();
        let zero = [];
        push(zero, AST_NUM);
        push(zero, 0);
        let node = [];
        push(node, AST_BINOP);
        push(node, "==");
        push(node, expr);
        push(node, zero);
        return node;
    };
    return parse_postfix(parse_primary());
};

fn parse_postfix(node) {
    while peek_type() == TK_LBRACKET || (peek_type() == TK_OP && peek_val() == ".") {
        if peek_type() == TK_LBRACKET {
            advance();
            let idx = parse_expr();
            expect(TK_RBRACKET);
            let args = [];
            push(args, node);
            push(args, idx);
            let call = [];
            push(call, AST_CALL);
            push(call, "__array_get");
            push(call, args);
            node = call;
        } else {
            advance();
            let field = expect(TK_IDENT);
            let fname = [];
            push(fname, AST_STR);
            push(fname, field);
            let args = [];
            push(args, node);
            push(args, fname);
            let call = [];
            push(call, AST_CALL);
            push(call, "__dict_get");
            push(call, args);
            node = call;
        };
    };
    return node;
};

fn parse_dict() {
    advance();
    let pairs = [];
    while peek_type() != TK_RBRACE {
        let key = expect(TK_IDENT);
        expect(TK_COLON);
        let val = parse_expr();
        let pair = [];
        push(pair, key);
        push(pair, val);
        push(pairs, pair);
        if peek_type() != TK_RBRACE { expect(TK_COMMA); };
    };
    expect(TK_RBRACE);
    let node = [];
    push(node, AST_DICT);
    push(node, pairs);
    return node;
};

fn parse_primary() {
    let t = peek_type();
    if t == TK_NUM {
        let val = advance();
        let node = [];
        push(node, AST_NUM);
        push(node, val);  // already a number from lexer
        return node;
    };
    if t == TK_STR {
        let val = advance();
        let node = [];
        push(node, AST_STR);
        push(node, val);
        return node;
    };
    if t == TK_TRUE {
        advance();
        let node = [];
        push(node, AST_NUM);
        push(node, 1);
        return node;
    };
    if t == TK_FALSE {
        advance();
        let node = [];
        push(node, AST_NUM);
        push(node, 0);
        return node;
    };
    if t == TK_IDENT {
        let name = advance();
        if peek_type() == TK_LPAREN {
            advance();  // skip (
            let args = [];
            while peek_type() != TK_RPAREN {
                push(args, parse_expr());
                if peek_type() != TK_RPAREN { expect(TK_COMMA); };
            };
            expect(TK_RPAREN);
            let node = [];
            push(node, AST_CALL);
            push(node, name);
            push(node, args);
            return node;
        };
        let node = [];
        push(node, AST_VAR);
        push(node, name);
        return node;
    };
    if t == TK_LPAREN {
        advance();
        let expr = parse_expr();
        expect(TK_RPAREN);
        return expr;
    };
    if t == TK_LBRACKET {
        advance();
        let elems = [];
        while peek_type() != TK_RBRACKET {
            push(elems, parse_expr());
            if peek_type() != TK_RBRACKET { expect(TK_COMMA); };
        };
        expect(TK_RBRACKET);
        let node = [];
        push(node, AST_ARRAY);
        push(node, elems);
        return node;
    };
    if t == TK_LBRACE && __array_get(g_tok_types, g_pos + 1) == TK_IDENT && __array_get(g_tok_types, g_pos + 2) == TK_COLON {
        return parse_dict();
    };
    emit "Parse error: unexpected";
    emit peek_val();
    return 0;
};

// ═══════════════════════════════════════════════════════════════
// CODEGEN — AST → bytecode (array of bytes)
// ═══════════════════════════════════════════════════════════════

fn emit_byte(b) {
    push(g_code, __bit_and(__floor(b), 255));
};

fn emit_u16(v) {
    let iv = __floor(v);
    emit_byte(__bit_and(iv, 255));
    emit_byte(__bit_and(__bit_shr(iv, 8), 255));
};

fn emit_u32(v) {
    let iv = __floor(v);
    emit_byte(__bit_and(iv, 255));
    emit_byte(__bit_and(__bit_shr(iv, 8), 255));
    emit_byte(__bit_and(__bit_shr(iv, 16), 255));
    emit_byte(__bit_and(__bit_shr(iv, 24), 255));
};

fn emit_i32(v) {
    // Signed 32-bit: if negative, convert to two's complement
    let iv = __floor(v);
    if iv < 0 { iv = 4294967296 + iv; };
    emit_u32(iv);
};

fn emit_f64(v) {
    // f64 → 8 bytes little-endian
    // Use __f64_to_le_bytes if available, else manual
    let bytes = __f64_to_le_bytes(v);
    let i = 0;
    while i < 8 {
        emit_byte(__array_get(bytes, i));
        i = i + 1;
    };
};

fn fnv1a(name) {
    // FNV-1a hash, return lower 32 bits
    let h = 0xcbf29ce484222325;
    let prime = 0x100000001b3;
    let i = 0;
    let slen = len(name);
    while i < slen {
        let c = __char_code(char_at(name, i));
        // h = (h XOR c) * prime — need 64-bit ops
        // Olang uses f64, so this won't work for full 64-bit hash.
        // Simplified: use 32-bit FNV-1a
        h = __bit_xor(h, c);
        h = h * 16777619;  // FNV-32 prime
        h = __bit_and(h, 4294967295);  // mask to 32 bits
        i = i + 1;
    };
    return h;
};

fn emit_name(name) {
    emit_u32(fnv1a(name));
};

fn emit_name(name) {
    let slen = len(name);
    emit_byte(slen);
    let i = 0;
    while i < slen {
        emit_byte(__char_code(char_at(name, i)));
        i = i + 1;
    };
};

fn emit_string(s) {
    let slen = len(s);
    // Pass 1: count actual chars (escapes = 1 char, not 2)
    let actual = 0;
    let i = 0;
    while i < slen {
        if __char_code(char_at(s, i)) == 92 && i + 1 < slen {
            actual = actual + 1;
            i = i + 2;
        } else {
            actual = actual + 1;
            i = i + 1;
        };
    };
    emit_byte(OP_PUSH);
    emit_u16(actual * 2);
    // Pass 2: emit chars, converting escapes
    i = 0;
    while i < slen {
        let cc = __char_code(char_at(s, i));
        if cc == 92 && i + 1 < slen {
            let esc = __char_code(char_at(s, i + 1));
            if esc == 110 { emit_u16(10); } else {
            if esc == 114 { emit_u16(13); } else {
            if esc == 116 { emit_u16(9); } else {
            if esc == 48 { emit_u16(0); } else {
            if esc == 92 { emit_u16(92); } else {
            if esc == 34 { emit_u16(34); } else {
                emit_u16(esc);
            };};};};}; };
            i = i + 2;
        } else {
            emit_u16(cc);
            i = i + 1;
        };
    };
};

fn current_offset() { return len(g_code); };

fn patch_i32(offset, value) {
    let iv = __floor(value);
    if iv < 0 { iv = 4294967296 + iv; };
    __set_at(g_code, offset, __bit_and(iv, 255));
    __set_at(g_code, offset + 1, __bit_and(__bit_shr(iv, 8), 255));
    __set_at(g_code, offset + 2, __bit_and(__bit_shr(iv, 16), 255));
    __set_at(g_code, offset + 3, __bit_and(__bit_shr(iv, 24), 255));
};

fn array_contains(arr, val) {
    let i = 0;
    while i < len(arr) {
        if __array_get(arr, i) == val { return 1; };
        i = i + 1;
    };
    return 0;
};

fn collect_free_vars(node, bound, free) {
    // Walk AST, find vars used but not in bound. Add to free (dedup).
    if type_of(node) != "array" { return 0; };
    let kind = __array_get(node, 0);
    if kind == AST_VAR {
        let name = __array_get(node, 1);
        if array_contains(bound, name) == 0 && array_contains(free, name) == 0 {
            push(free, name);
        };
        return 0;
    };
    if kind == AST_LET {
        // RHS first (may reference vars), then add name to bound
        collect_free_vars(__array_get(node, 2), bound, free);
        push(bound, __array_get(node, 1));
        return 0;
    };
    if kind == AST_ASSIGN {
        collect_free_vars(__array_get(node, 2), bound, free);
        return 0;
    };
    if kind == AST_FN {
        // Nested fn — skip (it has its own scope)
        return 0;
    };
    if kind == AST_BINOP {
        collect_free_vars(__array_get(node, 2), bound, free);
        collect_free_vars(__array_get(node, 3), bound, free);
        return 0;
    };
    if kind == AST_CALL {
        let args = __array_get(node, 2);
        let i = 0;
        while i < len(args) {
            collect_free_vars(__array_get(args, i), bound, free);
            i = i + 1;
        };
        return 0;
    };
    if kind == AST_BLOCK {
        let stmts = __array_get(node, 1);
        let i = 0;
        while i < len(stmts) {
            collect_free_vars(__array_get(stmts, i), bound, free);
            i = i + 1;
        };
        return 0;
    };
    if kind == AST_IF {
        collect_free_vars(__array_get(node, 1), bound, free);
        collect_free_vars(__array_get(node, 2), bound, free);
        if __array_get(node, 3) != 0 { collect_free_vars(__array_get(node, 3), bound, free); };
        return 0;
    };
    if kind == AST_WHILE {
        collect_free_vars(__array_get(node, 1), bound, free);
        collect_free_vars(__array_get(node, 2), bound, free);
        return 0;
    };
    if kind == AST_RETURN {
        if __array_get(node, 1) != 0 { collect_free_vars(__array_get(node, 1), bound, free); };
        return 0;
    };
    if kind == AST_EMIT {
        collect_free_vars(__array_get(node, 1), bound, free);
        return 0;
    };
    if kind == AST_EXPR_STMT {
        collect_free_vars(__array_get(node, 1), bound, free);
        return 0;
    };
    if kind == AST_AND || kind == AST_OR {
        collect_free_vars(__array_get(node, 1), bound, free);
        collect_free_vars(__array_get(node, 2), bound, free);
        return 0;
    };
    if kind == AST_ARRAY {
        let elems = __array_get(node, 1);
        let i = 0;
        while i < len(elems) {
            collect_free_vars(__array_get(elems, i), bound, free);
            i = i + 1;
        };
        return 0;
    };
    if kind == AST_TRY {
        collect_free_vars(__array_get(node, 1), bound, free);
        push(bound, __array_get(node, 2));
        collect_free_vars(__array_get(node, 3), bound, free);
        return 0;
    };
    if kind == AST_THROW {
        collect_free_vars(__array_get(node, 1), bound, free);
        return 0;
    };
    return 0;
};

fn find_free_vars(body, params) {
    let bound = [];
    let i = 0;
    while i < len(params) {
        push(bound, __array_get(params, i));
        i = i + 1;
    };
    let free = [];
    collect_free_vars(body, bound, free);
    return free;
};

fn compile_node_ext(kind, node) {
    if kind == AST_TRY {
        let body = __array_get(node, 1);
        let var_name = __array_get(node, 2);
        let handler = __array_get(node, 3);
        emit_byte(OP_TRY_BEGIN);
        let try_off = current_offset();
        emit_i32(0);
        compile_node(body);
        emit_byte(OP_CATCH_END);
        emit_byte(OP_JMP);
        let jmp_off = current_offset();
        emit_i32(0);
        let jmp_target = current_offset();
        patch_i32(try_off, current_offset());
        emit_byte(OP_PUSH_NUM);
        emit_f64(0);
        emit_byte(OP_STORE_LOCAL);
        emit_name(var_name);
        compile_node(handler);
        patch_i32(jmp_off, current_offset() - jmp_target);
        return 0;
    };
    if kind == AST_THROW {
        compile_node(__array_get(node, 1));
        emit_byte(OP_THROW);
        return 0;
    };
    if kind == AST_BREAK {
        emit_byte(OP_JMP);
        push(g_break_patches, current_offset());
        emit_i32(0);
        return 0;
    };
    if kind == AST_CONTINUE {
        emit_byte(OP_LOOP);
        let delta = g_loop_start - (current_offset() + 4);
        emit_i32(delta);
        return 0;
    };
    return 0;
};

fn compile_node(node) {
    if type_of(node) != "array" { return 0; };
    let kind = __array_get(node, 0);
    if kind >= 20 { return compile_node_ext(kind, node); };

    if kind == AST_PROGRAM {
        let stmts = __array_get(node, 1);
        let i = 0;
        while i < len(stmts) {
            compile_node(__array_get(stmts, i));
            i = i + 1;
        };
        emit_byte(OP_HALT);
        return 0;
    };

    if kind == AST_NUM {
        emit_byte(OP_PUSH_NUM);
        emit_f64(__array_get(node, 1));
        return 0;
    };

    if kind == AST_STR {
        emit_string(__array_get(node, 1));
        return 0;
    };

    if kind == AST_VAR {
        emit_byte(OP_LOAD);
        emit_name(__array_get(node, 1));
        return 0;
    };

    if kind == AST_LET {
        compile_node(__array_get(node, 2));
        emit_byte(OP_STORE_LOCAL);
        emit_name(__array_get(node, 1));
        return 0;
    };

    if kind == AST_ASSIGN {
        compile_node(__array_get(node, 2));
        emit_byte(OP_STORE);
        emit_name(__array_get(node, 1));
        return 0;
    };

    if kind == AST_EMIT {
        compile_node(__array_get(node, 1));
        emit_byte(OP_EMIT);
        return 0;
    };

    if kind == AST_EXPR_STMT {
        compile_node(__array_get(node, 1));
        emit_byte(OP_POP);
        return 0;
    };

    if kind == AST_BINOP {
        let op = __array_get(node, 1);
        compile_node(__array_get(node, 2));  // left
        compile_node(__array_get(node, 3));  // right
        if op == "+" { emit_byte(OP_ADD); } else {
        if op == "-" { emit_byte(OP_SUB); } else {
        if op == "*" { emit_byte(OP_MUL); } else {
        if op == "/" { emit_byte(OP_DIV); } else {
        if op == "%" { emit_byte(OP_MOD); } else {
        if op == "==" { emit_byte(OP_EQ); } else {
        if op == "!=" { emit_byte(OP_NE); } else {
        if op == "<" { emit_byte(OP_LT); } else {
        if op == ">" { emit_byte(OP_GT); } else {
        if op == "<=" { emit_byte(OP_LE); } else {
        if op == ">=" { emit_byte(OP_GE); }; }; }; }; }; }; }; }; }; }; };
        return 0;
    };

    if kind == AST_CALL {
        let name = __array_get(node, 1);
        let args = __array_get(node, 2);
        let argc = len(args);
        let i = 0;
        while i < argc {
            compile_node(__array_get(args, i));
            i = i + 1;
        };
        emit_byte(OP_CALL);
        emit_name(name);
        emit_byte(argc);
        return 0;
    };

    if kind == AST_DICT {
        let pairs = __array_get(node, 1);
        emit_byte(OP_CALL);
        emit_name("__dict_new");
        emit_byte(0);
        let i = 0;
        while i < len(pairs) {
            let pair = __array_get(pairs, i);
            emit_byte(OP_DUP);
            emit_string(__array_get(pair, 0));
            compile_node(__array_get(pair, 1));
            emit_byte(OP_CALL);
            emit_name("__dict_set");
            emit_byte(3);
            emit_byte(OP_POP);
            i = i + 1;
        };
        return 0;
    };

    if kind == AST_FN {
        let name = __array_get(node, 1);
        let params = __array_get(node, 2);
        let body = __array_get(node, 3);
        // Only analyze captures for nested functions (depth > 0)
        let free = [];
        if g_fn_depth > 0 { free = find_free_vars(body, params); };
        if len(free) > 0 {
            emit_byte(OP_CLOSURE_CAP);
            emit_byte(len(params));
            emit_byte(len(free));
            let ci = 0;
            while ci < len(free) {
                emit_name(__array_get(free, ci));
                ci = ci + 1;
            };
        } else {
            emit_byte(OP_CLOSURE);
            emit_byte(len(params));
        };
        let body_len_off = current_offset();
        emit_u32(0);
        let body_start = current_offset();
        g_fn_depth = g_fn_depth + 1;
        let pi = len(params) - 1;
        while pi >= 0 {
            emit_byte(OP_STORE_LOCAL);
            emit_name(__array_get(params, pi));
            pi = pi - 1;
        };
        compile_node(body);
        g_fn_depth = g_fn_depth - 1;
        if len(g_code) == 0 || __array_get(g_code, len(g_code) - 1) != OP_RET {
            emit_byte(OP_RET);
        };
        let body_end = current_offset();
        patch_i32(body_len_off, body_end - body_start);
        emit_byte(OP_STORE_LOCAL);
        emit_name(name);
        return 0;
    };

    if kind == AST_BLOCK {
        let stmts = __array_get(node, 1);
        let i = 0;
        while i < len(stmts) {
            compile_node(__array_get(stmts, i));
            i = i + 1;
        };
        return 0;
    };

    if kind == AST_IF {
        let cond = __array_get(node, 1);
        let then_b = __array_get(node, 2);
        let else_b = __array_get(node, 3);
        compile_node(cond);
        emit_byte(OP_JZ);
        let jz_off = current_offset();
        emit_i32(0);
        let jz_target = current_offset();
        compile_node(then_b);
        if else_b != 0 {
            emit_byte(OP_JMP);
            let jmp_off = current_offset();
            emit_i32(0);
            let jmp_target = current_offset();
            patch_i32(jz_off, current_offset() - jz_target);
            compile_node(else_b);
            patch_i32(jmp_off, current_offset() - jmp_target);
        } else {
            patch_i32(jz_off, current_offset() - jz_target);
        };
        return 0;
    };

    if kind == AST_WHILE {
        // Save outer loop state
        let old_break_patches = g_break_patches;
        let old_loop_start = g_loop_start;
        g_break_patches = [];
        let loop_start = current_offset();
        g_loop_start = loop_start;
        compile_node(__array_get(node, 1));  // cond
        emit_byte(OP_JZ);
        let jz_off = current_offset();
        emit_i32(0);
        let jz_target = current_offset();
        compile_node(__array_get(node, 2));  // body
        emit_byte(OP_LOOP);
        let loop_delta = loop_start - (current_offset() + 4);
        emit_i32(loop_delta);
        patch_i32(jz_off, current_offset() - jz_target);
        // Patch all break jumps to here (after loop)
        let bi = 0;
        while bi < len(g_break_patches) {
            let bp = __array_get(g_break_patches, bi);
            patch_i32(bp, current_offset() - (bp + 4));
            bi = bi + 1;
        };
        // Restore outer loop state
        g_break_patches = old_break_patches;
        g_loop_start = old_loop_start;
        return 0;
    };

    if kind == AST_RETURN {
        let val = __array_get(node, 1);
        if val != 0 {
            compile_node(val);
        } else {
            emit_byte(OP_PUSH_NUM);
            emit_f64(0);
        };
        emit_byte(OP_RET);
        return 0;
    };

    if kind == AST_ARRAY {
        let elems = __array_get(node, 1);
        if len(elems) == 0 {
            emit_byte(OP_PUSH_NUM);
            emit_f64(16);
            emit_byte(OP_CALL);
            emit_name("__array_with_cap");
            emit_byte(1);
        } else {
            let i = 0;
            while i < len(elems) {
                compile_node(__array_get(elems, i));
                i = i + 1;
            };
            emit_byte(OP_PUSH_NUM);
            emit_f64(len(elems));
            emit_byte(OP_CALL);
            emit_name("__array_new");
            emit_byte(len(elems) + 1);
        };
        return 0;
    };

    if kind == AST_AND {
        compile_node(__array_get(node, 1));
        emit_byte(OP_DUP);
        emit_byte(OP_JZ);
        let jz_off = current_offset();
        emit_i32(0);
        let jz_target = current_offset();
        emit_byte(OP_POP);
        compile_node(__array_get(node, 2));
        patch_i32(jz_off, current_offset() - jz_target);
        return 0;
    };

    if kind == AST_OR {
        compile_node(__array_get(node, 1));
        emit_byte(OP_DUP);
        emit_byte(OP_JZ);
        let jz_off = current_offset();
        emit_i32(0);
        let jz_target = current_offset();
        emit_byte(OP_JMP);
        let jmp_off = current_offset();
        emit_i32(0);
        let jmp_target = current_offset();
        patch_i32(jz_off, current_offset() - jz_target);
        emit_byte(OP_POP);
        compile_node(__array_get(node, 2));
        patch_i32(jmp_off, current_offset() - jmp_target);
        return 0;
    };

    return 0;
};

// ═══════════════════════════════════════════════════════════════
// BUILDER — assemble binary
// ═══════════════════════════════════════════════════════════════

fn resolve_imports(source) {
    // Scan source char-by-char for lines starting with: import "path"
    // Prepend imported file contents, strip import lines
    let imported = [];
    let prefix = "";
    let slen = len(source);
    let i = 0;
    while i < slen {
        // Check if line starts with import "
        let bol = i;
        // Skip leading whitespace
        while i < slen && (__char_code(char_at(source, i)) == 32 || __char_code(char_at(source, i)) == 9) {
            i = i + 1;
        };
        // Check for "import "
        if i + 7 < slen && substr(source, i, i + 7) == "import " {
            let pi = i + 7;
            // Skip to opening quote
            while pi < slen && __char_code(char_at(source, pi)) != 34 { pi = pi + 1; };
            if pi < slen {
                let ps = pi + 1;
                // Find closing quote
                let pe = ps;
                while pe < slen && __char_code(char_at(source, pe)) != 34 { pe = pe + 1; };
                if pe < slen {
                    let path = substr(source, ps, pe);
                    let dup = 0;
                    let di = 0;
                    while di < len(imported) {
                        if __array_get(imported, di) == path { dup = 1; };
                        di = di + 1;
                    };
                    if dup == 0 {
                        push(imported, path);
                        let content = "" + __file_read(path);
                        if len(content) > 0 { prefix = prefix + content + "\n"; };
                    };
                };
            };
        };
        // Skip to end of line
        while i < slen && __char_code(char_at(source, i)) != 10 { i = i + 1; };
        if i < slen { i = i + 1; };
    };
    if len(prefix) > 0 { return prefix + source; };
    return source;
};

fn build_binary(source_path, output_path) {
    // Read source
    let source = "" + __file_read(source_path);
    if len(source) == 0 {
        emit "Error: cannot read source file";
        return 0;
    };

    // Resolve imports
    source = resolve_imports(source);

    // Lex
    g_tok_types = [];
    g_tok_values = [];
    g_tok_count = 0;
    g_pos = 0;
    g_code = [];
    lex(source);

    // Parse
    let ast = parse_program();
    emit "Parse OK!";

    // Codegen
    compile_node(ast);
    emit "Codegen OK!";

    // Step 1: Copy VM binary to output
    __system("cp vm/x86_64/vm_nox " + output_path);

    // Step 2: Get VM size
    let vm = __file_read("vm/x86_64/vm_nox");
    let vm_len = len(vm);
    emit "VM size: " + __to_string(vm_len);

    // Step 3: Build tail bytes: bc_size(4) + bytecode + trailer(8)
    let bc_len = len(g_code);
    let tail = [];
    // BC size (4 bytes LE)
    push(tail, __bit_and(bc_len, 255));
    push(tail, __bit_and(__bit_shr(bc_len, 8), 255));
    push(tail, __bit_and(__bit_shr(bc_len, 16), 255));
    push(tail, __bit_and(__bit_shr(bc_len, 24), 255));
    // Bytecode
    let i = 0;
    while i < bc_len {
        push(tail, __array_get(g_code, i));
        i = i + 1;
    };
    // Trailer (8 bytes LE = vm_len as offset to bc_size)
    push(tail, __bit_and(vm_len, 255));
    push(tail, __bit_and(__bit_shr(vm_len, 8), 255));
    push(tail, __bit_and(__bit_shr(vm_len, 16), 255));
    push(tail, __bit_and(__bit_shr(vm_len, 24), 255));
    push(tail, 0);
    push(tail, 0);
    push(tail, 0);
    push(tail, 0);

    // Step 4: Append tail to output file
    __file_append_bytes(output_path, tail);

    emit "Compiled: " + source_path;
    emit "  Bytecode: " + __to_string(bc_len) + " bytes";
    emit "  Output: " + output_path;
    return 1;
};

// ═══════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════

let _args_raw = "" + __file_read("/tmp/.nox_args");
let source_file = "";
let output_file = "";
if len(_args_raw) > 0 {
    let _args_lines = __str_split(_args_raw, 10);
    if len(_args_lines) >= 1 {
        source_file = __str_trim(__array_get(_args_lines, 0));
    };
    if len(_args_lines) >= 2 {
        output_file = __str_trim(__array_get(_args_lines, 1));
    };
};
if len(source_file) == 0 {
    source_file = "stdlib/compiler.ol";
    output_file = "/tmp/compiler_gen2.olang";
};
build_binary(source_file, output_file);
