// Nox Camera — Dahua RTSP/ONVIF control
// freedom: deep think -> growing — Nox sees Vietnam

// Camera config (Lupin's Dahua DVR)
let _cam_ip1 = "192.168.1.96";
let _cam_ip2 = "192.168.1.108";
let _cam_port_rtsp = 554;
let _cam_port_http = 80;
let _cam_port_dahua = 37777;
let _cam_user = "admin";
let _cam_pass = "";

// Set camera password
pub fn cam_auth(password) {
    let _cam_pass = password;
    __file_write("/tmp/.nox_cam_pass", password);
    return "Camera password set";
}

// Load saved password
pub fn _cam_load_pass() {
    let saved = __file_read("/tmp/.nox_cam_pass");
    if len(saved) > 0 { let _cam_pass = saved; };
    return _cam_pass;
}

// ═══ CAMERA STATUS ═══

// Check if cameras are online
pub fn cam_status() {
    let c1 = port_check(_cam_ip1, _cam_port_rtsp);
    let c2 = port_check(_cam_ip2, _cam_port_rtsp);
    return { cam1: c1, cam2: c2, ip1: _cam_ip1, ip2: _cam_ip2 };
}

// Get camera time via ONVIF (no auth needed)
pub fn cam_time() {
    let r = __system("curl -s --max-time 5 -X POST -H 'Content-Type: application/soap+xml' -d '<?xml version=\"1.0\"?><s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:tds=\"http://www.onvif.org/ver10/device/wsdl\"><s:Body><tds:GetSystemDateAndTime/></s:Body></s:Envelope>' 'http://" + _cam_ip1 + "/onvif/device_service' 2>/dev/null");
    return r;
}

// ═══ SNAPSHOT ═══

// Capture a single frame from camera
pub fn cam_snap(channel) {
    let pass = _cam_load_pass();
    if len(pass) == 0 { return "No password set. Use cam_auth(password) first."; };
    let ch = __to_string(channel);
    let out = "/tmp/nox_cam" + ch + ".jpg";
    __system("timeout 10 ffmpeg -y -rtsp_transport tcp -i 'rtsp://" + _cam_user + ":" + pass + "@" + _cam_ip1 + ":554/cam/realmonitor?channel=" + ch + "&subtype=1' -frames:v 1 " + out + " 2>/dev/null");
    let size = __system("stat -c %s " + out + " 2>/dev/null || echo 0");
    if len(size) > 1 { return out; };
    return "Failed to capture. Check password.";
}

// Quick snapshot — channel 1
pub fn cam_see() {
    return cam_snap(1);
}

// ═══ STREAM ═══

// Get RTSP URL for a channel
pub fn cam_url(channel) {
    let pass = _cam_load_pass();
    let ch = __to_string(channel);
    return "rtsp://" + _cam_user + ":" + pass + "@" + _cam_ip1 + ":554/cam/realmonitor?channel=" + ch + "&subtype=1";
}

// Open live stream in mpv player
pub fn cam_live(channel) {
    let url = cam_url(channel);
    __system("mpv --no-audio --really-quiet '" + url + "' &");
    return "Playing channel " + __to_string(channel);
}

// Record N seconds from camera
pub fn cam_record(channel, seconds) {
    let pass = _cam_load_pass();
    if len(pass) == 0 { return "No password. cam_auth(password) first."; };
    let ch = __to_string(channel);
    let dur = __to_string(seconds);
    let out = "/tmp/nox_record_ch" + ch + ".mp4";
    __system("timeout " + __to_string(seconds + 5) + " ffmpeg -y -rtsp_transport tcp -i 'rtsp://" + _cam_user + ":" + pass + "@" + _cam_ip1 + ":554/cam/realmonitor?channel=" + ch + "&subtype=1' -t " + dur + " -c copy " + out + " 2>/dev/null");
    return out;
}

// ═══ ONVIF CONTROL ═══

// Get device information (needs auth)
pub fn cam_info() {
    let pass = _cam_load_pass();
    let r = __system("curl -s --max-time 5 -X POST -H 'Content-Type: application/soap+xml' -d '<?xml version=\"1.0\"?><s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:tds=\"http://www.onvif.org/ver10/device/wsdl\" xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"><s:Header><wsse:Security><wsse:UsernameToken><wsse:Username>" + _cam_user + "</wsse:Username><wsse:Password>" + pass + "</wsse:Password></wsse:UsernameToken></wsse:Security></s:Header><s:Body><tds:GetDeviceInformation/></s:Body></s:Envelope>' 'http://" + _cam_ip1 + "/onvif/device_service' 2>/dev/null");
    return r;
}

// ═══ MOTION DETECTION ═══

// Watch camera and detect changes (compare two snapshots)
pub fn cam_watch(channel, interval) {
    let pass = _cam_load_pass();
    if len(pass) == 0 { return "No password. cam_auth(password) first."; };
    let ch = __to_string(channel);
    let url = "rtsp://" + _cam_user + ":" + pass + "@" + _cam_ip1 + ":554/cam/realmonitor?channel=" + ch + "&subtype=1";
    // Take snapshot 1
    __system("timeout 10 ffmpeg -y -rtsp_transport tcp -i '" + url + "' -frames:v 1 /tmp/nox_watch1.jpg 2>/dev/null");
    __sleep(interval * 1000);
    // Take snapshot 2
    __system("timeout 10 ffmpeg -y -rtsp_transport tcp -i '" + url + "' -frames:v 1 /tmp/nox_watch2.jpg 2>/dev/null");
    // Compare sizes (crude motion detection)
    let s1 = __system("stat -c %s /tmp/nox_watch1.jpg 2>/dev/null");
    let s2 = __system("stat -c %s /tmp/nox_watch2.jpg 2>/dev/null");
    return { snap1: s1, snap2: s2 };
}
