// Nox Network — LAN discovery, port scanning, interfaces
// freedom: deep think -> growing — Nox sees the entire network

// ═══ NETWORK INTERFACES ═══

// List all network interfaces with IP addresses
pub fn net_interfaces() {
    let r = __system("ip -br addr show 2>/dev/null");
    return r;
}

// Get local IP address (primary)
pub fn net_local_ip() {
    let r = __system("ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'");
    return r;
}

// Get gateway IP
pub fn net_gateway() {
    let r = __system("ip route | awk '/default/{print $3}'");
    return r;
}

// Get subnet (e.g., "192.168.1.0/24")
pub fn net_subnet() {
    let r = __system("ip -o -4 addr show | awk '/scope global/{print $4}' | head -1");
    return r;
}

// Get MAC address
pub fn net_mac() {
    let r = __system("ip link show | awk '/ether/{print $2}' | head -1");
    return r;
}

// Public IP
pub fn net_public_ip() {
    let r = __system("curl -s --max-time 5 ifconfig.me 2>/dev/null");
    return r;
}

// ═══ LAN DISCOVERY ═══

// ARP table — devices already seen on LAN
pub fn lan_neighbors() {
    let r = __system("ip neigh show 2>/dev/null");
    return r;
}

// Ping sweep — discover active devices on local subnet
pub fn lan_scan() {
    // Get subnet prefix (e.g., "192.168.1")
    let prefix = __system("ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | awk -F. '{print $1\".\"$2\".\"$3}'");
    if len(prefix) < 5 { return "cannot detect subnet"; };
    // Parallel ping sweep (fast, no nmap needed)
    let cmd = "for i in $(seq 1 254); do ping -c1 -W1 " + prefix + ".$i >/dev/null 2>&1 && echo " + prefix + ".$i & done; wait";
    let r = __system(cmd);
    return r;
}

// Quick scan — just check ARP after broadcast ping
pub fn lan_quick() {
    let prefix = __system("ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | awk -F. '{print $1\".\"$2\".\"$3}'");
    // Send broadcast ping to wake devices
    __system("ping -b -c2 -W1 " + prefix + ".255 >/dev/null 2>&1");
    // Read ARP table
    let r = __system("ip neigh show | grep -v FAILED");
    return r;
}

// Scan specific IP for hostname/MAC
pub fn lan_whois(ip) {
    let arp = __system("ip neigh show " + ip + " 2>/dev/null");
    let host = __system("host " + ip + " 2>/dev/null | head -1");
    let mac = __system("arp -n " + ip + " 2>/dev/null | tail -1 | awk '{print $3}'");
    return { ip: ip, arp: arp, host: host, mac: mac };
}

// ═══ PORT SCANNING ═══

// Scan common ports on a target IP using TCP connect
pub fn port_scan(ip) {
    // Common service ports
    let ports = [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 993, 995, 3306, 3389, 5432, 5900, 6379, 8080, 8443, 9090];
    let open = [];
    let pi = 0;
    while pi < len(ports) {
        let p = ports[pi];
        let fd = __tcp_connect(ip, p);
        if fd >= 0 {
            push(open, p);
            __tcp_close(fd);
        };
        pi = pi + 1;
    };
    return open;
}

// Scan specific port range
pub fn port_range(ip, start, end) {
    let open = [];
    let p = start;
    while p <= end {
        let fd = __tcp_connect(ip, p);
        if fd >= 0 {
            push(open, p);
            __tcp_close(fd);
        };
        p = p + 1;
    };
    return open;
}

// Scan single port — returns 1 (open) or 0 (closed)
pub fn port_check(ip, port) {
    let fd = __tcp_connect(ip, port);
    if fd >= 0 {
        __tcp_close(fd);
        return 1;
    };
    return 0;
}

// ═══ DNS ═══

pub fn dns_lookup(hostname) {
    let ip = __dns_resolve(hostname);
    return ip;
}

pub fn dns_reverse(ip) {
    let r = __system("host " + ip + " 2>/dev/null | awk '/pointer/{print $5}'");
    return r;
}

// ═══ CONNECTION STATUS ═══

// Active connections
pub fn net_connections() {
    let r = __system("ss -tunap 2>/dev/null | head -30");
    return r;
}

// Listening ports
pub fn net_listening() {
    let r = __system("ss -tlnp 2>/dev/null");
    return r;
}

// Internet connectivity check
pub fn net_online() {
    let r = __system("ping -c1 -W2 1.1.1.1 >/dev/null 2>&1 && echo 1 || echo 0");
    return r;
}

// ═══ WIFI ═══

// List available WiFi networks
pub fn wifi_list() {
    let r = __system("nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null");
    return r;
}

// Current WiFi info
pub fn wifi_status() {
    let r = __system("nmcli -t -f GENERAL.CONNECTION,GENERAL.DEVICE,WIFI.SIGNAL dev show 2>/dev/null | head -10");
    return r;
}

// ═══ HTTP HELPERS ═══

// HTTP GET via curl (supports HTTPS)
pub fn http_fetch(url) {
    __system("curl -sL --max-time 15 '" + url + "' > /tmp/nox_fetch.txt 2>/dev/null");
    return __file_read("/tmp/nox_fetch.txt");
}

// HTTP POST via curl
pub fn http_post_curl(url, data) {
    __file_write("/tmp/nox_post.txt", data);
    __system("curl -sL --max-time 15 -X POST -d @/tmp/nox_post.txt '" + url + "' > /tmp/nox_fetch.txt 2>/dev/null");
    return __file_read("/tmp/nox_fetch.txt");
}

// Download file
pub fn http_download(url, path) {
    __system("curl -sL --max-time 60 '" + url + "' -o '" + path + "' 2>/dev/null");
    return path;
}

// ═══ BANDWIDTH ═══

// Network traffic stats
pub fn net_traffic() {
    let r = __system("cat /proc/net/dev | grep -v lo | tail -n +3 | awk '{print $1, \"RX:\"$2, \"TX:\"$10}'");
    return r;
}
