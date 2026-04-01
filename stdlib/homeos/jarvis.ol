// jarvis.ol — JARVIS: 1 brain, N mouths
// Phase 1: file-based (/tmp/nox_inbox → /tmp/nox_outbox)
// Phase 2: TCP socket (port 9100, plain text line protocol)
// Brain = Nox (origin.olang + persist files)
// Mouth = any process: nc localhost 9100, or write /tmp/nox_inbox

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

// ═══ Phase 2: TCP socket — echo "query" | nc localhost 9100 ═══

pub fn nox_jarvis_tcp() {
    nox_bootstrap();
    let _fc = __to_string(kt_fact_count());
    emit "Nox brain online. " + _fc + " facts. tcp://0.0.0.0:9100";
    let _srv = __tcp_listen(9100);
    nox_jarvis_status();
    let _n = [0];
    while 1 == 1 {
        let _fd = __tcp_accept(_srv);
        if _fd >= 0 {
            let _q = __tcp_recv(_fd, 4096);
            if len(_q) > 0 {
                let _qt = __str_trim(_q);
                let _r = pipeline(_qt);
                if len(_r) == 0 { let _r = "..."; };
                __tcp_send(_fd, _r + "\n");
                emit "> " + _qt;
                emit "< " + _r;
                let _ = __set_at(_n, 0, __array_get(_n, 0) + 1);
                if (__array_get(_n, 0) % 10) == 0 { nox_save(); nox_jarvis_status(); };
            };
            __tcp_close(_fd);
        };
    };
}
