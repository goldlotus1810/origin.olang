let _tu_ok = 1;
fn _tu_chk(_tc_n, _tc_g, _tc_e) { if _tc_g != _tc_e { let _tu_ok = 0; emit "FAIL " + _tc_n + " got=" + __to_string(_tc_g); }; };

// Unicode length (codepoints, not bytes)
_tu_chk("ulen_ascii", ulen("hello"), 5);
_tu_chk("ulen_viet", ulen("việt"), 4);
_tu_chk("ulen_full", ulen("xin chào"), 8);
_tu_chk("ulen_emoji", ulen("😊🎉"), 2);

// Unicode char_at (codepoint at index)
_tu_chk("uchar_v", uchar_at("việt", 0), 118);
_tu_chk("uchar_e", uchar_at("việt", 2), 7879);
_tu_chk("uchar_t", uchar_at("việt", 3), 116);

// UTF-8 codepoint decode
_tu_chk("utf8_A", __utf8_cp("A", 0), 65);
_tu_chk("utf8_e", __utf8_cp("é", 0), 233);
_tu_chk("utf8_d", __utf8_cp("đ", 0), 273);

// UTF-8 byte lengths
_tu_chk("utf8len_1", __utf8_len("A", 0), 1);
_tu_chk("utf8len_2", __utf8_len("é", 0), 2);
_tu_chk("utf8len_3", __utf8_len("ệ", 0), 3);

// Vietnamese string operations
_tu_chk("viet_eq", "chào" == "chào", 1);
_tu_chk("viet_contains", contains("xin chào bạn", "chào"), 1);
_tu_chk("viet_substr", substr("việt nam", 0, 4), "việ");

// String with mixed
let _tu_msg = "Hello Việt Nam 😊";
_tu_chk("mixed_len", len(_tu_msg) > 10, 1);

if _tu_ok { emit "PASS"; } else { emit "FAIL"; };
