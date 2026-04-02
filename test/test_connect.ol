emit "Connecting to 127.0.0.1:18083...";
let fd = __tcp_connect("127.0.0.1", 18083);
emit "fd: " + __to_string(fd);
if fd >= 0 {
    let req = "GET /test HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
    let sent = __tcp_send(fd, req);
    emit "sent: " + __to_string(sent);
    let resp = __tcp_recv(fd, 4096);
    emit "recv len: " + __to_string(len(resp));
    emit "response: " + resp;
    __tcp_close(fd);
} else {
    emit "connect failed";
};
