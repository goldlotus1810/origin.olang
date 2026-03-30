// Nox ONVIF Client — pure Olang, 0 libraries, 0 JSON, 0 XML parser
// TCP raw → parse bytes → KnowTree
// freedom: deep think -> growing

// ═══ SOAP TEMPLATES (fixed format — no XML parser needed) ═══

fn _soap_wrap(body) {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:tds=\"http://www.onvif.org/ver10/device/wsdl\" xmlns:trt=\"http://www.onvif.org/ver10/media/wsdl\" xmlns:tptz=\"http://www.onvif.org/ver20/ptz/wsdl\" xmlns:tt=\"http://www.onvif.org/ver10/schema\">" + body + "</s:Envelope>";
}

fn _soap_no_auth(method) {
    return _soap_wrap("<s:Body><" + method + "/></s:Body>");
}

fn _soap_with_auth(method, user, pass) {
    return _soap_wrap("<s:Header><Security xmlns=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"><UsernameToken><Username>" + user + "</Username><Password>" + pass + "</Password></UsernameToken></Security></s:Header><s:Body><" + method + "/></s:Body>");
}

fn _soap_body(method, body_content) {
    return _soap_wrap("<s:Body><" + method + ">" + body_content + "</" + method + "></s:Body>");
}

// ═══ HTTP POST to camera ═══

fn _onvif_post(ip, service, soap) {
    let path = "/onvif/" + service;
    let req = "POST " + path + " HTTP/1.1\r\nHost: " + ip + "\r\nContent-Type: application/soap+xml; charset=utf-8\r\nContent-Length: " + __to_string(len(soap)) + "\r\nConnection: close\r\n\r\n" + soap;
    let fd = __tcp_connect(ip, 80);
    if fd < 0 { return ""; };
    __tcp_send(fd, req);
    __sleep(2000);
    let r = __tcp_recv(fd, 16384);
    __tcp_close(fd);
    // Strip HTTP headers — find \r\n\r\n
    let hi = 0;
    while hi < len(r) - 3 {
        if char_at(r, hi) == "\r" {
            if char_at(r, hi + 1) == "\n" {
                if char_at(r, hi + 2) == "\r" {
                    if char_at(r, hi + 3) == "\n" {
                        return __substr(r, hi + 4, len(r));
                    };
                };
            };
        };
        hi = hi + 1;
    };
    return r;
}

// ═══ XML FIELD EXTRACTION (no full parser — pattern match) ═══

fn _xml_field(xml, tag) {
    // Extract content between <tag>content</tag> or <ns:tag>content</ns:tag>
    let i = 0;
    while i < len(xml) {
        if char_at(xml, i) == "<" {
            // Find tag name
            let ti = i + 1;
            // Skip namespace prefix
            let ni = ti;
            while ni < len(xml) {
                let c = char_at(xml, ni);
                if c == ":" { ti = ni + 1; };
                if c == ">" || c == " " || c == "/" { break; };
                ni = ni + 1;
            };
            let tag_name = __substr(xml, ti, ni);
            if tag_name == tag {
                // Find > end of opening tag
                let gi = ni;
                while gi < len(xml) { if char_at(xml, gi) == ">" { break; }; gi = gi + 1; };
                gi = gi + 1;
                // Find closing tag
                let ci = gi;
                while ci < len(xml) { if char_at(xml, ci) == "<" { break; }; ci = ci + 1; };
                return __substr(xml, gi, ci);
            };
        };
        i = i + 1;
    };
    return "";
}

// Extract ALL values for a tag (returns array of strings)
fn _xml_all(xml, tag) {
    let results = [];
    let i = 0;
    while i < len(xml) {
        if char_at(xml, i) == "<" {
            let ti = i + 1;
            let ni = ti;
            while ni < len(xml) {
                let c = char_at(xml, ni);
                if c == ":" { ti = ni + 1; };
                if c == ">" || c == " " || c == "/" { break; };
                ni = ni + 1;
            };
            let tag_name = __substr(xml, ti, ni);
            if tag_name == tag {
                let gi = ni;
                while gi < len(xml) { if char_at(xml, gi) == ">" { break; }; gi = gi + 1; };
                gi = gi + 1;
                let ci = gi;
                while ci < len(xml) { if char_at(xml, ci) == "<" { break; }; ci = ci + 1; };
                push(results, __substr(xml, gi, ci));
            };
        };
        i = i + 1;
    };
    return results;
}

// Extract XML attribute value
fn _xml_attr(xml, attr) {
    let key = attr + "=\"";
    let ki = 0;
    while ki < len(xml) - len(key) {
        let match = 1;
        let ci = 0;
        while ci < len(key) { if char_at(xml, ki + ci) != char_at(key, ci) { match = 0; break; }; ci = ci + 1; };
        if match == 1 {
            let vi = ki + len(key);
            let ve = vi;
            while ve < len(xml) { if char_at(xml, ve) == "\"" { break; }; ve = ve + 1; };
            return __substr(xml, vi, ve);
        };
        ki = ki + 1;
    };
    return "";
}

// ═══ ONVIF COMMANDS → KnowTree ═══

// Discover camera info and store in KnowTree
pub fn onvif_discover(ip, name) {
    emit "Discovering " + name + " at " + ip + "...";

    // 1. GetSystemDateAndTime (no auth)
    let time_xml = _onvif_post(ip, "device_service", _soap_no_auth("tds:GetSystemDateAndTime"));
    if len(time_xml) > 0 {
        let tz = _xml_field(time_xml, "TZ");
        let hour = _xml_field(time_xml, "Hour");
        let minute = _xml_field(time_xml, "Minute");
        kt_learn("camera " + name + " timezone " + tz);
        kt_learn("camera " + name + " time " + hour + ":" + minute);
        emit "  Time: " + hour + ":" + minute + " " + tz;
    };

    // 2. GetServices (no auth — reveals capabilities)
    let svc_xml = _onvif_post(ip, "device_service", _soap_no_auth("tds:GetServices"));
    if len(svc_xml) > 0 {
        let addrs = _xml_all(svc_xml, "XAddr");
        let ai = 0;
        while ai < len(addrs) {
            kt_learn("camera " + name + " service " + addrs[ai]);
            ai = ai + 1;
        };
        // Extract capabilities
        let video_src = _xml_attr(svc_xml, "VideoSources");
        if len(video_src) > 0 { kt_learn("camera " + name + " video_sources " + video_src); emit "  Video sources: " + video_src; };
        let max_profiles = _xml_attr(svc_xml, "MaximumNumberOfProfiles");
        if len(max_profiles) > 0 { kt_learn("camera " + name + " max_profiles " + max_profiles); };
        let rtp_tcp = _xml_attr(svc_xml, "RTP_TCP");
        if len(rtp_tcp) > 0 { kt_learn("camera " + name + " rtp_tcp " + rtp_tcp); };
    };

    // Store basic info
    kt_learn("camera " + name + " ip " + ip);
    kt_learn("camera " + name + " port_rtsp 554");
    kt_learn("camera " + name + " port_onvif 80");
    kt_learn("camera " + name + " protocol dahua_onvif");

    emit "  Stored in KnowTree";
    return name;
}

// Get device info (needs auth)
pub fn onvif_device_info(ip, user, pass) {
    let xml = _onvif_post(ip, "device_service", _soap_with_auth("tds:GetDeviceInformation", user, pass));
    if len(xml) == 0 { return { err: "no response" }; };
    let mfr = _xml_field(xml, "Manufacturer");
    let model = _xml_field(xml, "Model");
    let fw = _xml_field(xml, "FirmwareVersion");
    let serial = _xml_field(xml, "SerialNumber");
    return { manufacturer: mfr, model: model, firmware: fw, serial: serial };
}

// Get stream URI (needs auth)
pub fn onvif_stream_uri(ip, user, pass, profile) {
    let body = "<trt:GetStreamUri><trt:StreamSetup><tt:Stream>RTP-Unicast</tt:Stream><tt:Transport><tt:Protocol>RTSP</tt:Protocol></tt:Transport></trt:StreamSetup><trt:ProfileToken>" + profile + "</trt:ProfileToken></trt:GetStreamUri>";
    let xml = _onvif_post(ip, "media_service", _soap_wrap("<s:Header><Security xmlns=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"><UsernameToken><Username>" + user + "</Username><Password>" + pass + "</Password></UsernameToken></Security></s:Header><s:Body>" + body + "</s:Body>"));
    return _xml_field(xml, "Uri");
}

// Get media profiles (needs auth)
pub fn onvif_profiles(ip, user, pass) {
    let xml = _onvif_post(ip, "media_service", _soap_with_auth("trt:GetProfiles", user, pass));
    let tokens = _xml_all(xml, "ProfileToken");
    return tokens;
}

// ═══ CAMERA QUERY VIA KNOWTREE ═══

// Ask KnowTree about cameras (no parsing, semantic search)
pub fn cam_query(question) {
    return pipeline(question);
}
