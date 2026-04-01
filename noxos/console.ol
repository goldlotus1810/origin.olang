// ═══ NoxOS Console v2 — Direct stdin read ═══

// ── KnowTree (compact) ──
fn mp(s,r,v,a,t){return s*4096+r*256+v*32+a*4+t;};
fn ms(m){return __floor(m/4096)%16;};fn mr(m){return __floor(m/256)%16;};
fn mv(m){return __floor(m/32)%8;};fn ma(m){return __floor(m/4)%8;};fn mt(m){return m%4;};
fn md(a,b){let ds=ms(a)-ms(b);if ds<0{let ds=0-ds;};let dr=mr(a)-mr(b);if dr<0{let dr=0-dr;};let dv=mv(a)-mv(b);if dv<0{let dv=0-dv;};let da=ma(a)-ma(b);if da<0{let da=0-da;};let dt=mt(a)-mt(b);if dt<0{let dt=0-dt;};return ds+dr+dv*2+da*2+dt*4;};
fn ew(t,ws,we){let h=[0];let r=[0];let i=ws;let p=[0];while i<we{let c=__char_code(char_at(t,i));let pp=__array_get(p,0);let _=__set_at(h,0,__bit_and(__array_get(h,0)*31+c,65535));let _=__set_at(r,0,__bit_and(__array_get(r,0)*37+c+pp*7,65535));let _=__set_at(p,0,pp+1);let i=i+1;};return mp(__array_get(h,0)%16,__array_get(r,0)%16,4,3,2);};
fn bc(t){let c=[];let ws=0;let i=0;while i<=len(t){let ie=0;if i==len(t){let ie=1;}else{if __char_code(char_at(t,i))==32{let ie=1;};};if ie==1{if i>ws{push(c,ew(t,ws,i));};let ws=i+1;};let i=i+1;};return c;};
fn cd(a,b){let la=len(a);let lb=len(b);let cl=la;if lb<cl{let cl=lb;};let d=[0];let i=0;while i<cl{let _=__set_at(d,0,__array_get(d,0)+md(__array_get(a,i),__array_get(b,i)));let i=i+1;};let df=la-lb;if df<0{let df=0-df;};return __array_get(d,0)+df*2;};

let ft=[];let fch=[];let fc=[0];
fn learn(t){push(ft,t);push(fch,bc(t));let _=__set_at(fc,0,__array_get(fc,0)+1);};
fn search(q){let qc=bc(q);let n=__array_get(fc,0);if n==0{return "";};let bd=[999];let bi=[999];let i=0;while i<n{let d=cd(qc,__array_get(fch,i));if d<__array_get(bd,0){let _=__set_at(bd,0,d);let _=__set_at(bi,0,i);};let i=i+1;};if __array_get(bi,0)<999{return __array_get(ft,__array_get(bi,0));};return "";};

// Load facts
fn load_facts(path){let data=__file_read(path);if len(data)==0{return 0;};let loaded=[0];let ls=0;let i=0;while i<=len(data){let nl=0;if i==len(data){let nl=1;}else{if __char_code(char_at(data,i))==10{let nl=1;};};if nl==1{if i>ls{let line=substr(data,ls,i);if len(line)>2{learn(line);let _=__set_at(loaded,0,__array_get(loaded,0)+1);};};let ls=i+1;};let i=i+1;};return __array_get(loaded,0);};
let n=load_facts("data/facts.dat");
__heap_pin();

// ── Read line from stdin via raw syscall ──
fn read_line() {
    let buf = __mmap(4096);
    let pos = [0];
    let done = [0];
    while __array_get(done, 0) == 0 {
        let n = __syscall(0, 0, buf + __array_get(pos, 0), 1, 0, 0, 0);
        if n <= 0 { let _ = __set_at(done, 0, 2); };  // EOF
        if n > 0 {
            let ch = __mem_read8(buf, __array_get(pos, 0));
            if ch == 10 { let _ = __set_at(done, 0, 1); };  // newline
            if ch != 10 { let _ = __set_at(pos, 0, __array_get(pos, 0) + 1); };
        };
    };
    // Build string from buffer
    let result = "";
    let i = 0;
    let p = __array_get(pos, 0);
    while i < p {
        let ch = __mem_read8(buf, i);
        // Convert byte to char — use substr trick
        if ch >= 32 { if ch < 127 {
            let table = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            let result = result + substr(table, ch - 32, ch - 31);
        }; };
        let i = i + 1;
    };
    __munmap(buf, 4096);
    if __array_get(done, 0) == 2 { return ""; };
    return result;
};

// ═══ CONSOLE ═══
emit "";
emit "  Nox v0.1 | " + __to_string(__array_get(fc, 0)) + " facts";
let cpu = __system("cat /proc/loadavg 2>/dev/null");
emit "  load: " + cpu;
emit "";

let running = [1];
while __array_get(running, 0) == 1 {
    emit "nox> ";
    let line = read_line();
    if len(line) == 0 { let _ = __set_at(running, 0, 0); };

    if len(line) > 4 {
        if substr(line, 0, 4) == "ask " {
            let q = substr(line, 4, len(line));
            let r = search(q);
            if len(r) > 0 { emit "  " + r; } else { emit "  ?"; };
        };
    };
    if len(line) > 6 {
        if substr(line, 0, 6) == "learn " {
            let fact = substr(line, 6, len(line));
            learn(fact);
            __file_append("/tmp/nox_learned.dat", fact + "\n");
            emit "  ok (" + __to_string(__array_get(fc, 0)) + ")";
        };
        if substr(line, 0, 6) == "shell " {
            emit __system(substr(line, 6, len(line)));
        };
    };
    if line == "facts" { emit "  " + __to_string(__array_get(fc, 0)); };
    if line == "quit" { let _ = __set_at(running, 0, 0); };
};
