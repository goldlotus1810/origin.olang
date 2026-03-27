// homeos/spider.ol — Bug Spider
// Runs as eval code (not boot closure) to avoid var_table overflow.
// Usage: type "spider" in REPL

pub fn spider() {
    // Spider runs tests via eval to avoid boot closure limitations.
    // Each batch is a single eval with inline test function.
    let _sp_code = "fn sp(d,g,e){if __to_string(g)==__to_string(e){return 1;};emit \"  FAIL:\"+d+\" got:\"+__to_string(g); return 0;};let p=0;";

    // Batch 1: nested builtins
    _sp_code = _sp_code + "p=p+sp(\"nest:sha\",__substr(__sha256(\"abc\"),0,8),\"ba7816bf\");";
    _sp_code = _sp_code + "p=p+sp(\"nest:chr\",char_at(__sha256(\"abc\"),0),\"b\");";
    _sp_code = _sp_code + "p=p+sp(\"nest:len\",len(__sha256(\"x\")),64);";
    _sp_code = _sp_code + "p=p+sp(\"nest:tostr\",__substr(__to_string(12345),0,3),\"123\");";
    _sp_code = _sp_code + "p=p+sp(\"nest:3lvl\",__substr(__sha256(__to_string(42)),0,8),__substr(__sha256(__to_string(42)),0,8));";
    _sp_code = _sp_code + "p=p+sp(\"nest:cat\",len(\"ab\"+\"cd\"),4);";
    _sp_code = _sp_code + "p=p+sp(\"nest:ts2\",__to_string(__to_string(99)),\"99\");";

    // Batch 2: interpolation
    _sp_code = _sp_code + "p=p+sp(\"int:add\",$\"{2+3}\",\"5\");";
    _sp_code = _sp_code + "p=p+sp(\"int:mul\",$\"{7*6}\",\"42\");";
    _sp_code = _sp_code + "p=p+sp(\"int:sub\",$\"{100-37}\",\"63\");";
    _sp_code = _sp_code + "let xi=10;p=p+sp(\"int:var\",$\"{xi*2+1}\",\"21\");";
    _sp_code = _sp_code + "let ni=5;p=p+sp(\"int:mix\",$\"v={ni*ni}\",\"v=25\");";

    // Batch 3: operators + strings + crypto
    _sp_code = _sp_code + "p=p+sp(\"op:prec\",2+3*4,14);";
    _sp_code = _sp_code + "p=p+sp(\"op:paren\",(2+3)*4,20);";
    _sp_code = _sp_code + "p=p+sp(\"str:len\",len(\"hello\"),5);";
    _sp_code = _sp_code + "p=p+sp(\"str:sub\",__substr(\"abcdef\",2,4),\"cd\");";
    _sp_code = _sp_code + "p=p+sp(\"str:cat\",\"ab\"+\"cd\",\"abcd\");";
    _sp_code = _sp_code + "p=p+sp(\"cry:empty\",__substr(__sha256(\"\"),0,8),\"e3b0c442\");";
    _sp_code = _sp_code + "p=p+sp(\"cry:hello\",len(__sha256(\"hello\")),64);";
    _sp_code = _sp_code + "p=p+sp(\"sort\",sort([3,1,2])[0],1);";

    // Batch 4: functions + recursion
    _sp_code = _sp_code + "fn fib(n){if n<2{return n;};return fib(n-1)+fib(n-2);};";
    _sp_code = _sp_code + "p=p+sp(\"fn:fib\",fib(10),55);";
    _sp_code = _sp_code + "fn fact(n){if n<2{return 1;};return n*fact(n-1);};";
    _sp_code = _sp_code + "p=p+sp(\"fn:fact\",fact(6),720);";
    _sp_code = _sp_code + "fn dbl(x){return x*2;};p=p+sp(\"fn:nest\",dbl(dbl(5)),20);";

    // Batch 5: lambda + HOF
    _sp_code = _sp_code + "let f=fn(x){return x*3;};p=p+sp(\"lam\",f(7),21);";
    _sp_code = _sp_code + "p=p+sp(\"map\",map([1,2,3],fn(x){return x*10;}),[10,20,30]);";
    _sp_code = _sp_code + "p=p+sp(\"filter\",filter([1,2,3,4,5],fn(x){return x>3;}),[4,5]);";
    _sp_code = _sp_code + "p=p+sp(\"reduce\",reduce([1,2,3,4],fn(a,b){return a+b;}),10);";

    // Final
    _sp_code = _sp_code + "emit \"SPIDER:\"+__to_string(p)+\"/28\";";

    // Compile + execute
    let _sp_tokens = tokenize(_sp_code);
    let _sp_ast = parse(_sp_tokens);
    if _g_parse_error == 1 { let _g_parse_error = 0; return "SPIDER: PARSE ERROR"; };
    let _g_pos = 0;
    _prefill_output();
    analyze(_sp_ast);
    let _sp_bc = _g_output;
    if _g_pos == 0 { return "SPIDER: EMPTY"; };
    __eval_bytecode(_sp_bc);
    return "";
}
