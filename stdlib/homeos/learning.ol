// homeos/learning.ol — G7 Learning (stub, will implement from G_COMPLETE)

let _qr_facts = [];

pub fn dn_observe(fact) { push(_qr_facts, fact); return "DN (fire=1)"; }
pub fn dn_count() { return len(_qr_facts); }
pub fn qr_count() { return 0; }
pub fn learning_status() { return "DN:" + __to_string(len(_qr_facts)) + " QR:0"; }
