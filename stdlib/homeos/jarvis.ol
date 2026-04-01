// jarvis.ol — JARVIS Phase 1: 1 brain, N mouths (file-based)
// Brain = Nox (origin.olang + persist files)
// Mouth = any process that writes /tmp/nox_inbox, reads /tmp/nox_outbox

pub fn nox_jarvis_status() {
    let _s = "facts=" + __to_string(kt_fact_count());
    let _s = _s + " stm=" + __to_string(kt_stm_count());
    let _s = _s + " heap=" + __to_string(__floor(__heap_used() / 1024)) + "KB";
    __file_write("/tmp/nox_status", _s + "\n");
    return _s;
}

pub fn nox_jarvis_once() {
    let _q = __file_read("/tmp/nox_inbox");
    if len(_q) == 0 { return ""; };
    __file_write("/tmp/nox_inbox", "");
    let _r = pipeline(__str_trim(_q));
    if len(_r) == 0 { let _r = "..."; };
    __file_write("/tmp/nox_outbox", _r + "\n");
    nox_jarvis_status();
    return _r;
}

pub fn nox_jarvis_listen() {
    nox_bootstrap();
    emit "Nox brain online. " + __to_string(kt_fact_count()) + " facts.";
    __file_write("/tmp/nox_inbox", "");
    __file_write("/tmp/nox_outbox", "");
    nox_jarvis_status();
    let _n = [0];
    while 1 == 1 {
        let _q = __file_read("/tmp/nox_inbox");
        if len(_q) > 0 {
            let _r = nox_jarvis_once();
            emit "> " + __str_trim(_q);
            emit "< " + _r;
            let _ = __set_at(_n, 0, __array_get(_n, 0) + 1);
            if (__array_get(_n, 0) % 10) == 0 { nox_save(); };
        };
        __sleep(500);
    };
}
