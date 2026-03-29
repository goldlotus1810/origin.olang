#!/usr/bin/env python3
"""Nox keyboard — type text via uinput. Called by Olang."""
import os, struct, time, fcntl, sys

KEYS = {' ':57,'a':30,'b':48,'c':46,'d':32,'e':18,'f':33,'g':34,'h':35,'i':23,'j':36,'k':37,'l':38,'m':50,'n':49,'o':24,'p':25,'q':16,'r':19,'s':31,'t':20,'u':22,'v':47,'w':17,'x':45,'y':21,'z':44,'0':11,'1':2,'2':3,'3':4,'4':5,'5':6,'6':7,'7':8,'8':9,'9':10,'.':52,',':51,'-':12,'\n':28}

fd = os.open('/dev/uinput', os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(fd, 0x40045564, 1)
for i in range(256): fcntl.ioctl(fd, 0x40045565, i)
fcntl.ioctl(fd, 0x40045564, 2)
fcntl.ioctl(fd, 0x40045566, 0)
fcntl.ioctl(fd, 0x40045566, 1)
os.write(fd, b'nox\x00'+b'\x00'*76+struct.pack('<HHHH',3,0x1234,0x5678,1)+b'\x00'*1028)
fcntl.ioctl(fd, 0x5501, 0)
time.sleep(0.5)

text = sys.argv[1] if len(sys.argv)>1 else ""
for c in text.lower():
    code = KEYS.get(c, 0)
    if code:
        need_shift = c.isupper() or c in '!@#$%'
        if need_shift:
            os.write(fd, struct.pack('<QQHHi',0,0,1,42,1))
            os.write(fd, struct.pack('<QQHHi',0,0,0,0,0))
        os.write(fd, struct.pack('<QQHHi',0,0,1,code,1))
        os.write(fd, struct.pack('<QQHHi',0,0,0,0,0))
        os.write(fd, struct.pack('<QQHHi',0,0,1,code,0))
        os.write(fd, struct.pack('<QQHHi',0,0,0,0,0))
        if need_shift:
            os.write(fd, struct.pack('<QQHHi',0,0,1,42,0))
            os.write(fd, struct.pack('<QQHHi',0,0,0,0,0))
        time.sleep(0.02)

time.sleep(0.3)
fcntl.ioctl(fd, 0x5502, 0)
os.close(fd)
