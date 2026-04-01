// ═══ NoxOS Virtual Disk — Guest I/O via port emulation ═══
// Guest writes sector# to port 0x1F3, data to port 0x1F0
// Host intercepts KVM_EXIT_IO → read/write disk image file
// Simple sector-based: 512 bytes per sector

let SECTOR_SIZE = 512;
let VDISK_PORT_DATA = 496;     // 0x1F0
let VDISK_PORT_SECTOR = 499;   // 0x1F3
let VDISK_PORT_CMD = 503;      // 0x1F7 — 0x20=read, 0x30=write

// State
let vdisk_path = [""];
let vdisk_fd = [0];
let vdisk_sector = [0];
let vdisk_buf = [0];  // mmap buffer for sector I/O

fn vdisk_create(path, sectors) {
    // Create disk image file filled with zeros
    let size = sectors * SECTOR_SIZE;
    let zeros = __mmap(size);
    let i = 0;
    while i < size { __mem_write8(zeros, i, 0); let i = i + 1; };
    // Write to file via fd
    let fd = __fd_open(path, 577);  // O_WRONLY|O_CREAT|O_TRUNC = 1|64|512
    if fd < 0 { emit "[vdisk] create failed"; return fd; };
    __syscall(1, fd, zeros, size, 0, 0, 0);  // write
    __fd_close(fd);
    __munmap(zeros, size);
    emit "[vdisk] created " + path + " (" + __to_string(sectors) + " sectors)";
    return 0;
};

fn vdisk_open(path) {
    let fd = __fd_open(path, 2);  // O_RDWR
    if fd < 0 { emit "[vdisk] open failed: " + path; return fd; };
    let _ = __set_at(vdisk_path, 0, path);
    let _ = __set_at(vdisk_fd, 0, fd);
    // Allocate sector buffer
    if __array_get(vdisk_buf, 0) == 0 {
        let buf = __mmap(4096);
        let _ = __set_at(vdisk_buf, 0, buf);
    };
    emit "[vdisk] opened " + path;
    return 0;
};

fn vdisk_close() {
    if __array_get(vdisk_fd, 0) > 0 {
        __fd_close(__array_get(vdisk_fd, 0));
        let _ = __set_at(vdisk_fd, 0, 0);
    };
};

// Read sector from disk image into buffer
fn vdisk_read_sector(sector) {
    let fd = __array_get(vdisk_fd, 0);
    let buf = __array_get(vdisk_buf, 0);
    let offset = sector * SECTOR_SIZE;
    // pread64(fd, buf, 512, offset)
    let n = __syscall(17, fd, buf, SECTOR_SIZE, offset, 0, 0);
    return n;
};

// Write sector from buffer to disk image
fn vdisk_write_sector(sector) {
    let fd = __array_get(vdisk_fd, 0);
    let buf = __array_get(vdisk_buf, 0);
    let offset = sector * SECTOR_SIZE;
    // pwrite64(fd, buf, 512, offset)
    let n = __syscall(18, fd, buf, SECTOR_SIZE, offset, 0, 0);
    return n;
};

// Handle IO exit from KVM guest
// Returns: 1 if handled, 0 if not a vdisk port
fn vdisk_handle_io(port, direction, data_byte) {
    // Set sector number
    if port == VDISK_PORT_SECTOR {
        if direction == 1 {  // OUT
            let _ = __set_at(vdisk_sector, 0, data_byte);
        };
        return 1;
    };
    // Command port
    if port == VDISK_PORT_CMD {
        if direction == 1 {
            if data_byte == 32 {  // 0x20 = read sector
                vdisk_read_sector(__array_get(vdisk_sector, 0));
            };
            if data_byte == 48 {  // 0x30 = write sector
                vdisk_write_sector(__array_get(vdisk_sector, 0));
            };
        };
        return 1;
    };
    // Data port — read/write buffer byte 0
    if port == VDISK_PORT_DATA {
        let buf = __array_get(vdisk_buf, 0);
        if direction == 1 {  // OUT — guest writes data
            __mem_write8(buf, 0, data_byte);
        };
        // IN would read buf[0] — handled by caller setting kvm_run data
        return 1;
    };
    return 0;
};

emit "vdisk.ol loaded";
