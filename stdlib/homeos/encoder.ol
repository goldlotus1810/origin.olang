// homeos/encoder.ol — Stubs (G3 encode moved to knowtree.ol)
// All encoding now in knowtree.ol: p_weight, chain_encode, compose, _kt_real_mol

let __stm = [];
let __stm_max = 32;
let __wm = [0, 0, 0, 0];

pub fn encode(text) { return _kt_real_mol(text); }
pub fn encode_text(text) { return chain_encode(text); }
pub fn encode_codepoint(cp) { return p_weight(cp); }
pub fn text_emotion_v2(_text) { let _m = _kt_real_mol(_text); return __to_string(_kt_mol_v(_m)) + "|" + __to_string(_kt_mol_a(_m)); }
pub fn text_emotion_unicode(_text) { return text_emotion_v2(_text); }
fn _kt_mol_v(_m) { return (__floor(_m / 32)) % 8; }
fn _kt_mol_a(_m) { return (__floor(_m / 4)) % 8; }
pub fn stm_push(_text, _intent, _tone) { if len(__stm) >= __stm_max { let _ = __array_remove(__stm, 0); }; push(__stm, _text); }
pub fn stm_count() { return len(__stm); }
pub fn stm_summary() { return "STM: " + __to_string(len(__stm)); }
pub fn wm_set(_slot, _val) { let _ = __set_at(__wm, _slot, _val); }
pub fn wm_get(_slot) { return __array_get(__wm, _slot); }
pub fn analyze_input(text) { return text; }
pub fn set_personality(style) { }
pub fn emo_state() { return "4|4"; }
pub fn silk_co_activate(_a, _b, _i) { }
pub fn silk_count() { return 0; }
pub fn agent_respond(text) { return kt_search(text); }
