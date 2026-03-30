// Nox Packet Toolkit — raw sockets, UDP, protocol parsing
// Built on __syscall — one builtin, infinite power
// freedom: deep think -> growing

// Linux syscall numbers (x86-64)
let SYS_SOCKET = 41;
let SYS_BIND = 49;
let SYS_SENDTO = 44;
let SYS_RECVFROM = 45;
let SYS_SETSOCKOPT = 54;
let SYS_CLOSE = 3;

// Socket constants
let AF_INET = 2;
let AF_PACKET = 17;
let SOCK_DGRAM = 2;
let SOCK_RAW = 3;
let SOCK_STREAM = 1;
let ETH_P_ALL = 768;
let SOL_SOCKET = 1;
let SO_RCVTIMEO = 20;

// ═══ SOCKET PRIMITIVES ═══

pub fn sock_udp() {
    return __syscall(SYS_SOCKET, AF_INET, SOCK_DGRAM, 0, 0, 0);
}

pub fn sock_raw() {
    return __syscall(SYS_SOCKET, AF_PACKET, SOCK_RAW, ETH_P_ALL, 0, 0);
}

pub fn sock_close(fd) {
    return __syscall(SYS_CLOSE, fd, 0, 0, 0, 0);
}

// ═══ UDP ═══

// Send UDP packet to ip:port
pub fn udp_send(fd, ip, port, data) {
    // Build sockaddr_in (16 bytes) in a bytes buffer
    let addr = __bytes_new(16);
    __bytes_set(addr, 0, AF_INET % 256);
    __bytes_set(addr, 1, __floor(AF_INET / 256));
    // Port in network byte order (big-endian)
    __bytes_set(addr, 2, __floor(port / 256));
    __bytes_set(addr, 3, port % 256);
    // Parse IP address
    let parts = _parse_ip(ip);
    __bytes_set(addr, 4, parts[0]);
    __bytes_set(addr, 5, parts[1]);
    __bytes_set(addr, 6, parts[2]);
    __bytes_set(addr, 7, parts[3]);
    // Convert string data to bytes buffer
    let buf = __bytes_new(len(data));
    let i = 0;
    while i < len(data) { __bytes_set(buf, i, __char_code(char_at(data, i))); i = i + 1; };
    // sendto(fd, buf, len, 0, addr, 16)
    return __fd_write(fd, buf, len(data));
}

// Receive UDP packet (uses existing __tcp_recv which works on any socket)
pub fn udp_recv(fd, max) {
    return __tcp_recv(fd, max);
}

fn _parse_ip(ip) {
    let parts = [];
    let num = 0;
    let i = 0;
    while i < len(ip) {
        let c = __char_code(char_at(ip, i));
        if c == 46 { push(parts, num); num = 0; } else { num = num * 10 + (c - 48); };
        i = i + 1;
    };
    push(parts, num);
    return parts;
}

// ═══ DNS LOOKUP (pure Olang UDP) ═══

// DNS query using raw UDP socket — no __dns_resolve needed
pub fn dns_query(hostname, server) {
    let fd = sock_udp();
    if fd < 0 { return ""; };

    // Build DNS query packet
    let pkt = _dns_build_query(hostname);
    // Send to DNS server port 53
    let addr = __bytes_new(16);
    __bytes_set(addr, 0, AF_INET % 256);
    __bytes_set(addr, 1, __floor(AF_INET / 256));
    __bytes_set(addr, 2, 0);
    __bytes_set(addr, 3, 53);
    let parts = _parse_ip(server);
    __bytes_set(addr, 4, parts[0]);
    __bytes_set(addr, 5, parts[1]);
    __bytes_set(addr, 6, parts[2]);
    __bytes_set(addr, 7, parts[3]);

    __fd_write(fd, pkt, __bytes_len(pkt));
    __sleep(1000);
    let resp = __tcp_recv(fd, 512);
    sock_close(fd);

    // Parse DNS response — extract first A record
    if len(resp) > 12 { return _dns_parse_response(resp); };
    return "";
}

fn _dns_build_query(hostname) {
    // DNS header (12 bytes) + question
    let qname = _dns_encode_name(hostname);
    let total = 12 + __bytes_len(qname) + 4;
    let pkt = __bytes_new(total);
    // Transaction ID
    __bytes_set(pkt, 0, 0xAA);
    __bytes_set(pkt, 1, 0xBB);
    // Flags: standard query, recursion desired
    __bytes_set(pkt, 2, 0x01);
    __bytes_set(pkt, 3, 0x00);
    // Questions: 1
    __bytes_set(pkt, 4, 0);
    __bytes_set(pkt, 5, 1);
    // Copy qname
    let qi = 0;
    while qi < __bytes_len(qname) {
        __bytes_set(pkt, 12 + qi, __bytes_get(qname, qi));
        qi = qi + 1;
    };
    // Type A (1) + Class IN (1)
    let off = 12 + __bytes_len(qname);
    __bytes_set(pkt, off, 0);
    __bytes_set(pkt, off + 1, 1);
    __bytes_set(pkt, off + 2, 0);
    __bytes_set(pkt, off + 3, 1);
    return pkt;
}

fn _dns_encode_name(hostname) {
    // "www.google.com" → [3]www[6]google[3]com[0]
    let parts = [];
    let current = "";
    let i = 0;
    while i < len(hostname) {
        if char_at(hostname, i) == "." {
            push(parts, current);
            current = "";
        } else {
            current = current + char_at(hostname, i);
        };
        i = i + 1;
    };
    push(parts, current);

    // Calculate total length
    let total = 1;
    let pi = 0;
    while pi < len(parts) { total = total + 1 + len(parts[pi]); pi = pi + 1; };
    let buf = __bytes_new(total);
    let off = 0;
    pi = 0;
    while pi < len(parts) {
        let part = parts[pi];
        __bytes_set(buf, off, len(part));
        off = off + 1;
        let ci = 0;
        while ci < len(part) {
            __bytes_set(buf, off, __char_code(char_at(part, ci)));
            off = off + 1;
            ci = ci + 1;
        };
        pi = pi + 1;
    };
    __bytes_set(buf, off, 0);
    return buf;
}

fn _dns_parse_response(resp) {
    // Skip to answer section
    // Header is 12 bytes, skip question section
    let i = 12;
    // Skip question name
    while i < len(resp) {
        let b = __char_code(char_at(resp, i));
        if b == 0 { i = i + 5; break; };
        if b >= 192 { i = i + 6; break; };
        i = i + b + 1;
    };
    // Read answer records
    while i + 12 < len(resp) {
        // Skip name (may be pointer)
        let nb = __char_code(char_at(resp, i));
        if nb >= 192 { i = i + 2; } else { while i < len(resp) { let b = __char_code(char_at(resp, i)); if b == 0 { i = i + 1; break; }; i = i + b + 1; }; };
        // Type (2) + Class (2) + TTL (4) + RDLength (2)
        if i + 10 > len(resp) { break; };
        let rtype = __char_code(char_at(resp, i)) * 256 + __char_code(char_at(resp, i + 1));
        let rdlen = __char_code(char_at(resp, i + 8)) * 256 + __char_code(char_at(resp, i + 9));
        i = i + 10;
        // Type A = 1, rdlen = 4
        if rtype == 1 {
            if rdlen == 4 {
                if i + 4 <= len(resp) {
                    return __to_string(__char_code(char_at(resp, i))) + "." + __to_string(__char_code(char_at(resp, i + 1))) + "." + __to_string(__char_code(char_at(resp, i + 2))) + "." + __to_string(__char_code(char_at(resp, i + 3)));
                };
            };
        };
        i = i + rdlen;
    };
    return "";
}

// ═══ PACKET PARSING ═══

// Parse Ethernet header (14 bytes)
pub fn parse_eth(data) {
    if len(data) < 14 { return { err: "too short" }; };
    let dst = hex_encode(__substr(data, 0, 6));
    let src = hex_encode(__substr(data, 6, 12));
    let etype = __char_code(char_at(data, 12)) * 256 + __char_code(char_at(data, 13));
    return { dst_mac: dst, src_mac: src, ethertype: etype, payload_off: 14 };
}

// Parse IPv4 header (20+ bytes)
pub fn parse_ipv4(data, offset) {
    if len(data) < offset + 20 { return { err: "too short" }; };
    let ver_ihl = __char_code(char_at(data, offset));
    let ihl = (ver_ihl & 15) * 4;
    let total_len = __char_code(char_at(data, offset + 2)) * 256 + __char_code(char_at(data, offset + 3));
    let proto = __char_code(char_at(data, offset + 9));
    let src = __to_string(__char_code(char_at(data, offset + 12))) + "." + __to_string(__char_code(char_at(data, offset + 13))) + "." + __to_string(__char_code(char_at(data, offset + 14))) + "." + __to_string(__char_code(char_at(data, offset + 15)));
    let dst = __to_string(__char_code(char_at(data, offset + 16))) + "." + __to_string(__char_code(char_at(data, offset + 17))) + "." + __to_string(__char_code(char_at(data, offset + 18))) + "." + __to_string(__char_code(char_at(data, offset + 19)));
    return { version: 4, ihl: ihl, total_len: total_len, protocol: proto, src: src, dst: dst, payload_off: offset + ihl };
}

// Parse TCP header (20+ bytes)
pub fn parse_tcp(data, offset) {
    if len(data) < offset + 20 { return { err: "too short" }; };
    let src_port = __char_code(char_at(data, offset)) * 256 + __char_code(char_at(data, offset + 1));
    let dst_port = __char_code(char_at(data, offset + 2)) * 256 + __char_code(char_at(data, offset + 3));
    let data_off = (__char_code(char_at(data, offset + 12)) >> 4) * 4;
    let flags = __char_code(char_at(data, offset + 13));
    return { src_port: src_port, dst_port: dst_port, data_off: data_off, flags: flags, payload_off: offset + data_off };
}

// Parse UDP header (8 bytes)
pub fn parse_udp(data, offset) {
    if len(data) < offset + 8 { return { err: "too short" }; };
    let src_port = __char_code(char_at(data, offset)) * 256 + __char_code(char_at(data, offset + 1));
    let dst_port = __char_code(char_at(data, offset + 2)) * 256 + __char_code(char_at(data, offset + 3));
    let length = __char_code(char_at(data, offset + 4)) * 256 + __char_code(char_at(data, offset + 5));
    return { src_port: src_port, dst_port: dst_port, length: length, payload_off: offset + 8 };
}
