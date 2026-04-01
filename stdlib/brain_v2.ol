// ═══ brain_v2.ol — Integrated Brain: Encode + KnowTree + Pipeline ═══
// Uses: UCD v18 P_weight tables + NRC-VAD 44K emotions
// All data via mmap O(1). No fake encode. Real brain.

// ── Load data tables ──
let _pw_fd = __fd_open("data/p_weight_table.bin", 0);
let _pw = __syscall(9, 0, 131072, 1, 2, _pw_fd, 0);
let _vad_fd = __fd_open("data/nrc_vad_hash.bin", 0);
let _vad = __syscall(9, 0, 131072, 1, 2, _vad_fd, 0);

// ── Mol helpers ──
fn mol_pack(s,r,v,a,t){return s*4096+r*256+v*32+a*4+t;};
fn mol_s(m){return __floor(m/4096)%16;};
fn mol_r(m){return __floor(m/256)%16;};
fn mol_v(m){return __floor(m/32)%8;};
fn mol_a(m){return __floor(m/4)%8;};
fn mol_t(m){return m%4;};
fn mol_dist(a,b){
    let ds=mol_s(a)-mol_s(b);if ds<0{let ds=0-ds;};
    let dr=mol_r(a)-mol_r(b);if dr<0{let dr=0-dr;};
    let dv=mol_v(a)-mol_v(b);if dv<0{let dv=0-dv;};
    let da=mol_a(a)-mol_a(b);if da<0{let da=0-da;};
    let dt=mol_t(a)-mol_t(b);if dt<0{let dt=0-dt;};
    return ds+dr+dv*2+da*2+dt*4;
};

// ── NRC-VAD hash with probing ──
fn _h1(t,s,e){let h=5381;let i=s;while i<e{let c=__char_code(char_at(t,i));if c>=65{if c<=90{let c=c+32;};};let h=__bit_and(h*33+c,65535);let i=i+1;};return h;};
fn _h2(t,s,e){let h=0;let i=s;while i<e{let c=__char_code(char_at(t,i));if c>=65{if c<=90{let c=c+32;};};let h=__bit_and(h*31+c,255);let i=i+1;};if h==0{return 1;};return h;};

fn vad_lookup(t,s,e){
    let slot=_h1(t,s,e);let chk=_h2(t,s,e);let p=0;
    while p<16{let idx=__bit_and(slot+p,65535)*2;
        let ch=__mem_read8(_vad,idx);if ch==0{return 0;};
        if ch==chk{return __mem_read8(_vad,idx+1);};
        let p=p+1;};
    return 0;
};

// ── Encode word (UCD + NRC-VAD) ──
fn encode_word(t,s,e){
    let sm=0;let rf=0;let tf=2;let fi=1;let i=s;
    while i<e{let cp=__char_code(char_at(t,i));if cp<65536{
        let lo=__mem_read8(_pw,cp*2);let hi=__mem_read8(_pw,cp*2+1);let pw=lo+hi*256;
        let cs=__floor(pw/4096)%16;if cs>sm{let sm=cs;};
        if fi==1{let rf=__floor(pw/256)%16;let tf=pw%4;let fi=0;};
    };let i=i+1;};
    let v=4;let a=3;
    let pk=vad_lookup(t,s,e);if pk>0{let v=__bit_and(pk,7);let a=__bit_and(__floor(pk/8),7);};
    let wh=__bit_and(_h1(t,s,e),15);
    let r=__floor(rf*6/10+wh*4/10);if r>15{let r=15;};
    return mol_pack(sm,r,v,a,tf);
};

// ── Encode sentence (emotion-dominant compose) ──
fn encode(text){
    let mols=[];let ws=0;let i=0;
    while i<=len(text){let ie=0;
        if i==len(text){let ie=1;}else{if __char_code(char_at(text,i))==32{let ie=1;};};
        if ie==1{if i>ws{push(mols,encode_word(text,ws,i));};let ws=i+1;};let i=i+1;};
    if len(mols)==0{return 0;};if len(mols)==1{return __array_get(mols,0);};
    // S=max, R=first content, V=strongest emotion, A=max, T=first
    let s_max=0;let a_max=0;let v_best=4;let v_str=0;let r_best=mol_r(__array_get(mols,0));
    let mi=0;while mi<len(mols){let m=__array_get(mols,mi);
        let cs=mol_s(m);if cs>s_max{let s_max=cs;};
        let ca=mol_a(m);if ca>a_max{let a_max=ca;};
        let wv=mol_v(m);let dev=wv-4;if dev<0{let dev=0-dev;};
        if dev>v_str{let v_str=dev;let v_best=wv;
            let r_best=mol_r(m);};  // R from strongest emotion word
        let mi=mi+1;};
    return mol_pack(s_max,r_best,v_best,a_max,mol_t(__array_get(mols,0)));
};

// ═══ KnowTree ═══
let _facts_text=[];let _facts_mol=[];let _fc=[0];

fn learn(text){
    let mol=encode(text);
    push(_facts_text,text);push(_facts_mol,mol);
    let _ =__set_at(_fc,0,__array_get(_fc,0)+1);
    __mx_w(mol,__array_get(_fc,0));
};

fn search(query){
    let qm=encode(query);
    let n=__array_get(_fc,0);if n==0{return "";};
    let bd=999;let bi=0-1;let i=0;
    while i<n{let d=mol_dist(qm,__array_get(_facts_mol,i));
        if d<bd{let bd=d;let bi=i;};let i=i+1;};
    if bi>=0{return __array_get(_facts_text,bi);};
    return "";
};

fn search_dist(query){
    let qm=encode(query);
    let n=__array_get(_fc,0);if n==0{return 999;};
    let bd=999;let i=0;
    while i<n{let d=mol_dist(qm,__array_get(_facts_mol,i));
        if d<bd{let bd=d;};let i=i+1;};
    return bd;
};

// ═══ Instincts ═══
fn instinct_honesty(dist){
    if dist>25{return 0;};     // silence
    if dist>15{return 400;};   // "I think..."
    if dist>5{return 700;};    // "probably"
    return 1000;                // confident
};

fn instinct_curiosity(dist){
    if dist>20{return 1;};return 0;
};

// ═══ Silk ═══
fn silk_fire(a,b){
    let h=__bit_and(__bit_xor(a,b)*40503+a+b,65535);
    let w=__mxr(h);let nw=w+100;if nw>65535{let nw=65535;};
    __mx_w(h,nw);
};

// ═══ Pipeline ═══
fn pipeline(input){
    // CP1: Security
    let mol=encode(input);
    if mol_v(mol)<2{if mol_a(mol)>5{return "crisis";};};
    // Search
    let result=search(input);
    let dist=search_dist(input);
    // Honesty
    let conf=instinct_honesty(dist);
    if conf==0{return "";};  // silence
    // Silk fire
    if len(result)>0{silk_fire(mol,encode(result));};
    return result;
};

fn fact_count(){return __array_get(_fc,0);};

emit "brain_v2 loaded — UCD v18 + NRC-VAD + pipeline";
