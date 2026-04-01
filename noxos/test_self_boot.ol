fn hw64(b,o,v){__mem_write32(b,o,v%4294967296);__mem_write32(b,o+4,__floor(v/4294967296));};
let kvm_fd=__fd_open("/dev/kvm",2);
let vm_fd=__syscall(16,kvm_fd,44545,0,0,0,0);
let _=__syscall(16,vm_fd,44615,4294565888,0,0,0);
let mem=__mmap(2097152);
let off=[0];
fn sc(mem,off,ch){let o=__array_get(off,0);__mem_write8(mem,o,176);__mem_write8(mem,o+1,ch);__mem_write8(mem,o+2,230);__mem_write8(mem,o+3,233);let _=__set_at(off,0,o+4);};
// "NoxOS!\n" = 7 chars
sc(mem,off,78);sc(mem,off,111);sc(mem,off,120);sc(mem,off,79);sc(mem,off,83);sc(mem,off,33);sc(mem,off,10);
__mem_write8(mem, __array_get(off, 0), 244);

let reg=__mmap(4096);__mem_write32(reg,0,0);__mem_write32(reg,4,0);
hw64(reg,8,0);hw64(reg,16,2097152);hw64(reg,24,mem);
let _=__syscall(16,vm_fd,1075883590,reg,0,0,0);__munmap(reg,4096);
let vcpu_fd=__syscall(16,vm_fd,44609,0,0,0,0);
let kvm_run=__mmap_file(vcpu_fd,__syscall(16,kvm_fd,44548,0,0,0,0));
let sregs=__mmap(4096);let _=__syscall(16,vcpu_fd,2168848003,sregs,0,0,0);
hw64(sregs,0,0);__mem_write32(sregs,12,0);
let _=__syscall(16,vcpu_fd,1095106180,sregs,0,0,0);
let regs=__mmap(4096);let ri=0;while ri<144{__mem_write8(regs,ri,0);let ri=ri+1;};
hw64(regs,128,0);hw64(regs,136,2);
let _=__syscall(16,vcpu_fd,1083223682,regs,0,0,0);
__munmap(sregs,4096);__munmap(regs,4096);

let io_count=[0];let bytes=[];let done=[0];
while __array_get(done,0)==0{
    let _=__syscall(16,vcpu_fd,44672,0,0,0,0);
    let ex=__mem_read32(kvm_run,8);
    if ex==5{let _=__set_at(done,0,1);};
    if ex==8{let _=__set_at(done,0,1);};
    if ex==2{
        let raw=__mem_read32(kvm_run,32);
        let dir=raw%256;let port=__floor(raw/65536)%65536;
        if dir==1{if port==233{
            let doff=__mem_read32(kvm_run,40);
            let byte=__mem_read32(kvm_run,doff)%256;
            push(bytes,byte);
            let _=__set_at(io_count,0,__array_get(io_count,0)+1);
        };};
    };
};
emit "IO exits: "+__to_string(__array_get(io_count,0));
let bi=0;
while bi<len(bytes){
    emit "byte "+__to_string(bi)+": "+__to_string(__array_get(bytes,bi));
    let bi=bi+1;
};
__fd_close(vcpu_fd);__fd_close(vm_fd);__munmap(mem,2097152);__fd_close(kvm_fd);
