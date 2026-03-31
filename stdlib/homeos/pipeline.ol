// homeos/pipeline.ol — G8 Pipeline (stub, will implement from G_COMPLETE)

let _phi_inv = 618;

pub fn pipeline(input) { return kt_search(input); }
pub fn bootstrap() {
    let _c = __file_read("homeos.knowledge");
    if len(_c) == 0 { return "no homeos.knowledge"; };
    return spider_feed(_c, "homeos.knowledge");
}
pub fn bootstrap_md(_p) { let _c = __file_read(_p); if len(_c) == 0 { return "empty"; }; return spider_feed_md(_c, _p); }
pub fn bootstrap_file(_p, _chunk) { return "use bootstrap()"; }
