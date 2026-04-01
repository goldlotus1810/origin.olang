// ═══ NoxOS Virtual Network — Guest TCP proxy ═══
// Guest writes to I/O ports → Nox proxies via host TCP
// Port 0x300 = command, 0x301 = data, 0x302 = status
// Commands: 1=connect(ip,port), 2=send(data), 3=recv, 4=close

let VNET_PORT_CMD = 768;    // 0x300
let VNET_PORT_DATA = 769;   // 0x301
let VNET_PORT_STATUS = 770; // 0x302

let vnet_fd = [0];           // active TCP connection
let vnet_buf = [0];          // data buffer
let vnet_cmd = [0];          // pending command
let vnet_ip = [""];          // target IP
let vnet_port_num = [0];     // target port

fn vnet_init() {
    let buf = __mmap(4096);
    let _ = __set_at(vnet_buf, 0, buf);
};

// Handle IO from guest
fn vnet_handle_io(port, direction, data_byte) {
    if port == VNET_PORT_CMD {
        if direction == 1 {
            let _ = __set_at(vnet_cmd, 0, data_byte);
            // Execute command
            if data_byte == 1 {
                // Connect — ip and port set via data port prior
                let fd = __tcp_connect(__array_get(vnet_ip, 0), __array_get(vnet_port_num, 0));
                let _ = __set_at(vnet_fd, 0, fd);
            };
            if data_byte == 4 {
                // Close
                if __array_get(vnet_fd, 0) > 0 {
                    __tcp_close(__array_get(vnet_fd, 0));
                    let _ = __set_at(vnet_fd, 0, 0);
                };
            };
        };
        return 1;
    };
    if port == VNET_PORT_DATA {
        if direction == 1 {
            // Guest sends data byte — accumulate in buffer
            let buf = __array_get(vnet_buf, 0);
            // Simple: send byte immediately
            if __array_get(vnet_fd, 0) > 0 {
                __mem_write8(buf, 0, data_byte);
                __syscall(1, __array_get(vnet_fd, 0), buf, 1, 0, 0, 0);
            };
        };
        return 1;
    };
    if port == VNET_PORT_STATUS {
        // Guest reads status: 0=disconnected, 1=connected
        return 1;
    };
    return 0;
};

emit "vnet.ol loaded";
