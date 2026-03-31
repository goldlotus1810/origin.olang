# Tai lieu tham khao SDF cua Inigo Quilez -- Toan bo Cong thuc & Ky thuat

Nguon: https://iquilezles.org (144 bai viet)
Trich xuat: 2026-03-31

Tai lieu nay ghi lai TOAN BO cong thuc SDF va ky thuat tu website cua Inigo Quilez.
Quilez la NGUOI CO THAM QUYEN NHAT ve Signed Distance Fields (Truong Khoang Cach Co Dau)
trong do hoa may tinh. Cong trinh cua ong la nen tang toan hoc cho moi ung dung
dua tren SDF: render, tao mo hinh, va ngay cang nhieu ung dung NGOAI do hoa.

**SDF la gi?**
SDF = mot ham tra ve KHOANG CACH tu mot diem bat ky den be mat gan nhat.
- Gia tri DUONG (+) = diem nam NGOAI hinh
- Gia tri AM (-) = diem nam TRONG hinh
- Gia tri BANG 0 = diem nam TREN be mat

---

## Muc luc

1. [Ham khoang cach 3D (Hinh co ban)](#1-ham-khoang-cach-3d)
2. [Ham khoang cach 2D (Hinh co ban)](#2-ham-khoang-cach-2d)
3. [Phep toan Boolean (Hop, Tru, Giao, Xor)](#3-phep-toan-boolean)
4. [Smooth Minimum / Hop muot](#4-smooth-minimum)
5. [Phep toan mien (Lap, Doi xung, Keo dai)](#5-phep-toan-mien)
6. [Bien dang (Xoan, Uon, Dich chuyen)](#6-bien-dang)
7. [Tao 3D tu 2D (Xoay tron, Do)](#7-tao-3d-tu-2d)
8. [Phap tuyen / Tinh Gradient](#8-phap-tuyen-va-gradient)
9. [Raymarching voi SDF](#9-raymarching-voi-sdf)
10. [Bong mem tu SDF](#10-bong-mem)
11. [Ambient Occlusion tu SDF](#11-ambient-occlusion)
12. [Suong mu va Hieu ung khi quyen](#12-suong-mu-va-khi-quyen)
13. [Raymarching dia hinh](#13-raymarching-dia-hinh)
14. [Chi tiet FBM trong SDF](#14-chi-tiet-fbm-trong-sdf)
15. [Truong khoang cach Fractal](#15-truong-khoang-cach-fractal)
16. [SDF ben trong](#16-sdf-ben-trong)
17. [Bounding Volume cho SDF (Tang toc)](#17-bounding-volume-cho-sdf)
18. [Chieu sang ngoai troi](#18-chieu-sang-ngoai-troi)
19. [Meo tang hieu suat](#19-meo-tang-hieu-suat)
20. [Ung dung SDF ngoai do hoa](#20-ung-dung-ngoai-do-hoa)
21. [Danh muc bai viet day du](#21-danh-muc-bai-viet-day-du)

---

## 1. Ham khoang cach 3D

URL: https://iquilezles.org/articles/distfunctions/
Shadertoy playlist: https://www.shadertoy.com/playlist/43cXRl

Quy uoc: `dot2(v) = dot(v,v)` (binh phuong do dai).
Moi hinh co ban dat tai goc toa do. Bien doi diem p de dat vi tri.

### SDF chinh xac (khoang cach Euclid that)

**Hinh cau (Sphere)**
Tinh khoang cach tu diem p den mat cau ban kinh r.
→ Do dai vector p tru ban kinh = khoang cach den mat cau.
```glsl
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}
```

**Hop (Box)**
Tinh khoang cach tu diem p den hop co kich thuoc b (nua canh).
→ Dung abs() de loi dung doi xung, max() cho phan ngoai, min() cho phan trong.
(https://www.youtube.com/watch?v=62-pRVZuS5c)
```glsl
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
```

**Hop bo tron (Round Box)**
Giong hop thuong nhung canh duoc bo tron voi ban kinh r.
→ Lay SDF hop, tru di r de "phong" canh ra.
```glsl
float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}
```

**Khung hop (Box Frame)**
Chi co khung (canh) cua hop, khong co mat.
→ Ket hop 3 thanh (moi thanh la giao cua 2 mat) de tao khung.
```glsl
float sdBoxFrame(vec3 p, vec3 b, float e) {
    p = abs(p) - b;
    vec3 q = abs(p+e) - e;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}
```

**Hinh xuyen (Torus)**
Hinh banh donut. t.x = ban kinh vong lon, t.y = ban kinh ong.
→ Tinh khoang cach den vong tron lon (tren mat phang xz), roi den ong.
```glsl
float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x, p.y);
    return length(q) - t.y;
}
```

**Hinh xuyen cat (Capped Torus)**
Hinh xuyen nhung chi giu mot phan (cat bot).
→ sc = sin/cos cua goc cat. ra = ban kinh vong lon, rb = ban kinh ong.
```glsl
float sdCappedTorus(vec3 p, vec2 sc, float ra, float rb) {
    p.x = abs(p.x);
    float k = (sc.y*p.x > sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
    return sqrt(dot(p,p) + ra*ra - 2.0*ra*k) - rb;
}
```

**Mat xich (Link)**
Mot mat xich dan (nhu day chuyen). le = nua chieu dai phan thang,
r1 = ban kinh vong, r2 = ban kinh ong.
```glsl
float sdLink(vec3 p, float le, float r1, float r2) {
    vec3 q = vec3(p.x, max(abs(p.y)-le,0.0), p.z);
    return length(vec2(length(q.xy)-r1, q.z)) - r2;
}
```

**Hinh tru vo han (Infinite Cylinder)**
Hinh tru dai vo tan. c.xy = tam tren mat phang xz, c.z = ban kinh.
```glsl
float sdCylinder(vec3 p, vec3 c) {
    return length(p.xz - c.xy) - c.z;
}
```

**Hinh non (Cone)**
Hinh non chinh xac. c = sin/cos cua goc, h = chieu cao.
→ Dung clamp va dot product de chieu diem len canh non.
```glsl
float sdCone(vec3 p, vec2 c, float h) {
    vec2 q = h*vec2(c.x/c.y,-1.0);
    vec2 w = vec2(length(p.xz), p.y);
    vec2 a = w - q*clamp(dot(w,q)/dot(q,q), 0.0, 1.0);
    vec2 b = w - q*vec2(clamp(w.x/q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a,a), dot(b,b));
    float s = max(k*(w.x*q.y-w.y*q.x), k*(w.y-q.y));
    return sqrt(d)*sign(s);
}
```

**Mat phang (Plane)**
Mat phang vo han. n = phap tuyen (phai chuan hoa), h = do lech.
→ Phep chieu don gian: dot(p,n) + h.
```glsl
float sdPlane(vec3 p, vec3 n, float h) {
    return dot(p,n) + h;
}
```

**Lang tru luc giac (Hexagonal Prism)**
Hinh lang tru co mat cat la luc giac deu. h.x = kich thuoc luc giac, h.y = nua chieu cao.
```glsl
float sdHexPrism(vec3 p, vec2 h) {
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
        length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
        p.z-h.y);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
```

**Vien nang / Doan thang (Capsule / Line)**
Hinh vien nang noi hai diem a va b, ban kinh r.
→ Chieu diem p len doan thang ab, roi tinh khoang cach tru ban kinh.
```glsl
float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}
```

**Vien nang dung (Vertical Capsule)**
Vien nang dung doc theo truc y. h = chieu cao phan tru, r = ban kinh.
```glsl
float sdVerticalCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}
```

**Hinh tru co nap (Capped Cylinder) -- dung**
Hinh tru dung co 2 nap tren va duoi. r = ban kinh, h = nua chieu cao.
```glsl
float sdCappedCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
```

**Hinh tru co nap (Capped Cylinder) -- huong bat ky**
Hinh tru noi hai diem a va b bat ky, ban kinh r.
```glsl
float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3  ba = b - a;
    vec3  pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    return sign(d)*sqrt(abs(d))/baba;
}
```

**Hinh tru bo tron (Rounded Cylinder)**
Hinh tru co canh bo tron. ra = ban kinh tru, rb = ban kinh bo tron, h = nua chieu cao.
```glsl
float sdRoundedCylinder(vec3 p, float ra, float rb, float h) {
    vec2 d = vec2(length(p.xz)-ra+rb, abs(p.y)-h+rb);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}
```

**Hinh non co nap (Capped Cone) -- dung**
Hinh non bi cat o 2 dau. h = nua chieu cao, r1 = ban kinh day, r2 = ban kinh dinh.
```glsl
float sdCappedCone(vec3 p, float h, float r1, float r2) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.0*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp(dot(k1-q,k2)/dot2(k2), 0.0, 1.0);
    float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
    return s*sqrt(min(dot2(ca),dot2(cb)));
}
```

**Goc dac (Solid Angle)**
Hinh non rong (chi co mat ngoai). c = sin/cos goc, ra = ban kinh.
```glsl
float sdSolidAngle(vec3 p, vec2 c, float ra) {
    vec2 q = vec2(length(p.xz), p.y);
    float l = length(q) - ra;
    float m = length(q - c*clamp(dot(q,c),0.0,ra));
    return max(l, m*sign(c.y*q.x-c.x*q.y));
}
```

**Hinh cau bi cat (Cut Sphere)**
Hinh cau bi cat boi mat phang ngang. r = ban kinh cau, h = do cao mat cat.
```glsl
float sdCutSphere(vec3 p, float r, float h) {
    float w = sqrt(r*r-h*h);
    vec2 q = vec2(length(p.xz), p.y);
    float s = max((h-r)*q.x*q.x+w*w*(h+r-2.0*q.y), h*q.x-w*q.y);
    return (s<0.0) ? length(q)-r :
           (q.x<w) ? h - q.y     :
                     length(q-vec2(w,h));
}
```

**Death Star (hinh cau bi can)**
Hinh cau lon bi hinh cau nho "can" mot mieng. ra = ban kinh cau lon,
rb = ban kinh cau nho, d = khoang cach giua 2 tam.
```glsl
float sdDeathStar(vec3 p2, float ra, float rb, float d) {
    float a = (ra*ra - rb*rb + d*d)/(2.0*d);
    float b = sqrt(max(ra*ra-a*a,0.0));
    vec2 p = vec2(p2.x, length(p2.yz));
    if (p.x*b-p.y*a > d*max(b-p.y,0.0))
        return length(p-vec2(a,b));
    else
        return max((length(p)-ra), -(length(p-vec2(d,0.0))-rb));
}
```

**Hinh non tron (Round Cone) -- dung**
Hinh non co 2 dau ban cau. r1 = ban kinh day, r2 = ban kinh dinh, h = chieu cao.
```glsl
float sdRoundCone(vec3 p, float r1, float r2, float h) {
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    vec2 q = vec2(length(p.xz), p.y);
    float k = dot(q,vec2(-b,a));
    if (k<0.0) return length(q) - r1;
    if (k>a*h) return length(q-vec2(0.0,h)) - r2;
    return dot(q, vec2(a,b)) - r1;
}
```

**Doan Vesica (Vesica Segment)**
Hinh thau kinh 3D noi hai diem a, b voi do rong w.
```glsl
float sdVesicaSegment(vec3 p, vec3 a, vec3 b, float w) {
    vec3  c = (a+b)*0.5;
    float l = length(b-a);
    vec3  v = (b-a)/l;
    float y = dot(p-c,v);
    vec2  q = vec2(length(p-c-y*v), abs(y));
    float r = 0.5*l;
    float d = 0.5*(r*r-w*w)/w;
    vec3  h = (r*q.x<d*(q.y-r)) ? vec3(0.0,r,0.0) : vec3(-d,0.0,d+w);
    return length(q-h.xy) - h.z;
}
```

**Hinh thoi (Rhombus)**
Hinh thoi 3D. la, lb = kich thuoc, h = nua chieu cao, ra = bo tron.
```glsl
float sdRhombus(vec3 p, float la, float lb, float h, float ra) {
    p = abs(p);
    float f = clamp((la*p.x-lb*p.z+lb*lb)/(la*la+lb*lb), 0.0, 1.0);
    vec2  w = p.xz - vec2(la,lb)*vec2(f,1.0-f);
    vec2  q = vec2(length(w)*sign(w.x)-ra, p.y-h);
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}
```

**Bat dien (Octahedron) -- chinh xac**
Hinh bat dien deu. s = kich thuoc (khoang cach tu tam den dinh).
```glsl
float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    float m = p.x+p.y+p.z-s;
    vec3 q;
    if (3.0*p.x < m) q = p.xyz;
    else if (3.0*p.y < m) q = p.yzx;
    else if (3.0*p.z < m) q = p.zxy;
    else return m*0.57735027;
    float k = clamp(0.5*(q.z-q.y+s),0.0,s);
    return length(vec3(q.x,q.y-s+k,q.z-k));
}
```

**Bat dien (Octahedron) -- xap xi, nhanh**
Phien ban nhanh nhung chi la xap xi (bound), khong chinh xac hoan toan.
```glsl
float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}
```

**Kim tu thap (Pyramid)**
Kim tu thap co day vuong don vi, chieu cao h.
```glsl
float sdPyramid(vec3 p, float h) {
    float m2 = h*h + 0.25;
    p.xz = abs(p.xz);
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    vec3 q = vec3(p.z, h*p.y-0.5*p.x, h*p.x+0.5*p.y);
    float s = max(-q.x,0.0);
    float t = clamp((q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0);
    float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
    float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    return sqrt((d2+q.z*q.z)/m2) * sign(max(q.z,-p.y));
}
```

**Tam giac (Triangle) -- khoang cach khong dau**
Khoang cach tu diem p den tam giac co 3 dinh a, b, c.
→ Kiem tra diem chieu co nam trong tam giac khong, neu khong thi tinh khoang cach den canh gan nhat.
```glsl
float udTriangle(vec3 p, vec3 a, vec3 b, vec3 c) {
    vec3 ba = b-a; vec3 pa = p-a;
    vec3 cb = c-b; vec3 pb = p-b;
    vec3 ac = a-c; vec3 pc = p-c;
    vec3 nor = cross(ba, ac);
    return sqrt(
        (sign(dot(cross(ba,nor),pa)) +
         sign(dot(cross(cb,nor),pb)) +
         sign(dot(cross(ac,nor),pc)) < 2.0)
        ?
        min(min(
            dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
            dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb)),
            dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc))
        :
        dot(nor,pa)*dot(nor,pa)/dot2(nor));
}
```

**Tu giac (Quad) -- khoang cach khong dau**
Khoang cach tu diem p den tu giac co 4 dinh a, b, c, d.
```glsl
float udQuad(vec3 p, vec3 a, vec3 b, vec3 c, vec3 d) {
    vec3 ba = b-a; vec3 pa = p-a;
    vec3 cb = c-b; vec3 pb = p-b;
    vec3 dc = d-c; vec3 pc = p-c;
    vec3 ad = a-d; vec3 pd = p-d;
    vec3 nor = cross(ba, ad);
    return sqrt(
        (sign(dot(cross(ba,nor),pa)) +
         sign(dot(cross(cb,nor),pb)) +
         sign(dot(cross(dc,nor),pc)) +
         sign(dot(cross(ad,nor),pd)) < 3.0)
        ?
        min(min(min(
            dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
            dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb)),
            dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc)),
            dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd))
        :
        dot(nor,pa)*dot(nor,pa)/dot2(nor));
}
```

### SDF xap xi / Bound (khong chinh xac hoan toan)

**Ellipsoid (hinh bau duc 3D) -- can duoi**
Khoang cach xap xi (luon nho hon hoac bang khoang cach that).
→ Chia p cho r de "nen" thanh hinh cau, roi hieu chinh lai.
```glsl
float sdEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}
```

**Lang tru tam giac (Triangular Prism) -- can duoi**
```glsl
float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z-h.y, max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}
```

---

## 2. Ham khoang cach 2D

URL: https://iquilezles.org/articles/distfunctions2d/
Shadertoy playlist: https://www.shadertoy.com/playlist/MXdSRf

Tat ca la SDF chinh xac tru khi ghi chu khac. Quy uoc: `dot2(v) = dot(v,v)`.

### Danh sach hinh 2D co ban

| Hinh | Mo ta cong thuc |
|------|-----------------|
| Hinh tron (Circle) | `length(p) - r` -- khoang cach = do dai vector tru ban kinh |
| Hinh vuong (Box) | `length(max(abs(p)-b, 0)) + min(max(d.x,d.y), 0)` |
| Hop bo tron (Rounded Box) | Hop voi ban kinh bo tron khac nhau moi goc |
| Hop vat (Chamfer Box) | Hop voi goc vat phang |
| Hop xoay (Oriented Box) | Hop xoay theo goc giua hai diem |
| Doan thang (Segment) | Chieu diem len doan: `length(pa - ba*clamp(...))` |
| Hinh thoi (Rhombus) | Khoang cach chinh xac co dau |
| Hinh thang can (Isosceles Trapezoid) | Khoang cach chinh xac co dau |
| Hinh binh hanh (Parallelogram) | Khoang cach chinh xac co dau |
| Tam giac deu (Equilateral Triangle) | Ky thuat guong + kep canh |
| Tam giac can (Isosceles Triangle) | Khoang cach chinh xac co dau |
| Tam giac bat ky (Triangle) | Khoang cach canh + dau winding number |
| Vien nang le (Uneven Capsule) | Vien nang co 2 ban kinh khac nhau |
| Ngu giac deu (Regular Pentagon) | Ky thuat phan xa voi hang so cos/sin |
| Luc giac deu (Regular Hexagon) | Ky thuat phan xa: `k = vec3(-0.866025404, 0.5, 0.577350269)` |
| Bat giac deu (Regular Octagon) | Ky thuat phan xa kep |
| Ngoi sao David (Hexagram) | Hai phep phan xa |
| Ngoi sao nam canh (Pentagram) | Ba phep phan xa |
| Ngoi sao deu n canh (Regular Star) | Dung goc voi `atan` |
| Hinh quat (Pie/sector) | Cung hinh tron |
| Dia bi cat (Cut Disk) | Hinh tron co mat cat phang |
| Cung tron (Arc) | Cung tron co do day |
| Vong (Ring) | Phan cung tron |
| Mong ngua (Horseshoe) | Cung mo co do day |
| Vesica | Hinh thau kinh |
| Vesica huong (Oriented Vesica) | Giua hai diem |
| Hinh trang (Moon) | Hieu hai hinh cau |
| Chu thap tron (Circle Cross) | Chu thap noi trong hinh tron |
| Hinh trung (Egg) | Hinh trung bat doi xung |
| Hinh trai tim (Heart) | Hinh trai tim co dien |
| Hinh chu thap (Cross) | Hinh dau cong |
| Chu X bo tron (Rounded X) | Chu X co canh tron |
| Da giac bat ky (Polygon) | Duyet canh + winding number |
| Hinh elip (Ellipse) | Giai phuong trinh bac 4 (chinh xac!) |
| Parabol (Parabola) | Giai phuong trinh bac 3 |
| Doan parabol (Parabola Segment) | Parabol co gioi han |
| Bezier bac 2 (Quadratic Bezier) | Giai bac 3 tim diem gan nhat tren duong cong |
| Chu thap mem (Blobby Cross) | Hinh chu thap muot |
| Duong ham (Tunnel) | Hinh duong ham |
| Bac thang (Stairs) | Ham bac thang |
| Hinh tron bac 2 (Quadratic Circle) | `|x|^0.5 + |y|^0.5 = 1` |
| Hyperbol (Hyperbola) | Khoang cach chinh xac co dau |
| Cool S | Chu "S" ai cung ve hoi di hoc |

### Cong thuc quan trong: SDF da giac bat ky
Tinh khoang cach co dau tu diem p den da giac co N dinh.
→ Duyet tung canh, tim khoang cach nho nhat, dung winding number de xac dinh dau (+/-).
```glsl
float sdPolygon(vec2[N] v, vec2 p) {
    float d = dot(p-v[0], p-v[0]);
    float s = 1.0;
    for (int i=0, j=N-1; i<N; j=i, i++) {
        vec2 e = v[j] - v[i];
        vec2 w = p - v[i];
        vec2 b = w - e*clamp(dot(w,e)/dot(e,e), 0.0, 1.0);
        d = min(d, dot(b,b));
        bvec3 c = bvec3(p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x);
        if (all(c) || all(not(c))) s *= -1.0;
    }
    return s*sqrt(d);
}
```

### Cong thuc quan trong: SDF hinh elip (chinh xac)
Dung phuong trinh bac 4, cong thuc Cardano. Mot trong nhung SDF 2D phuc tap nhat.
Xem: https://iquilezles.org/articles/ellipsedist/

---

## 3. Phep toan Boolean

URL: https://iquilezles.org/articles/distfunctions/ (phan)
Them: https://iquilezles.org/articles/sdfxor/
Them: https://iquilezles.org/articles/interiordistance/

### Phep toan co ban
```glsl
// Hop (Union) -- chinh xac ben ngoai, SAI ben trong
float opUnion(float a, float b) { return min(a,b); }

// Tru (Subtraction) -- xap xi (khong chinh xac), KHONG giao hoan
float opSubtraction(float a, float b) { return max(-a,b); }

// Giao (Intersection) -- xap xi (khong chinh xac)
float opIntersection(float a, float b) { return max(a,b); }

// Xor -- CHINH XAC moi noi (Quilez da chung minh!)
float opXor(float a, float b) { return max(min(a,b), -max(a,b)); }
```

**Dieu QUAN TRONG can hieu:**
→ Hop (min) chinh xac o BEN NGOAI nhung SAI o BEN TRONG.
→ Tru (max) va Giao (max) chi la xap xi, KHONG phai SDF chinh xac.
→ Chi co Xor cho ket qua SDF chinh xac o MOI NOI -- Quilez da chung minh dieu nay.

### 8 cach ket hop 2 SDF
Co chinh xac 2^3 = 8 cach ket hop hai hinh chong nhau (3 vung chong,
moi vung co the la trong hoac ngoai). Bon cach la hop/tru/giao/xor.
Ba cach la don gian (chi a, chi b, tap rong). Cach thu tam la xor.

---

## 4. Smooth Minimum

URL: https://iquilezles.org/articles/smin/

Smooth minimum pha tron hai SDF trong khoang cach k (tinh bang don vi the gioi).
Tao ra hieu ung MUOT nhu dat nan, huu co. Tat ca bien the duoi day da duoc
chuan hoa de k tuong ung voi cung mot DO RONG pha tron.

→ Day la ky thuat QUAN TRONG NHAT de tao hinh dang huu co voi SDF.
→ k lon = pha tron nhieu (mem). k nho = pha tron it (sac net).

### Bay bien the Smooth Minimum

```glsl
// Smooth min ham mu (Exponential)
// → Dung ham mu de pha tron. Muot nhung cham.
float smin(float a, float b, float k) {
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

// Smooth min can (Root)
// → Dung can bac hai. Nhanh hon ham mu.
float smin(float a, float b, float k) {
    k *= 2.0;
    float x = b-a;
    return 0.5*(a+b-sqrt(x*x+k*k));
}

// Smooth min sigmoid (moi)
// → Dung ham sigmoid. Moi nhat.
float smin(float a, float b, float k) {
    k *= log(2.0);
    float x = b-a;
    return a + x/(1.0-exp2(x/k));
}

// Smooth min da thuc bac 2 (PHO BIEN NHAT)
// → Nhanh, de hieu, dung trong hau het truong hop.
float smin(float a, float b, float k) {
    k *= 4.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*k*(1.0/4.0);
}

// Smooth min da thuc bac 3
// → Muot hon bac 2, chi phi cao hon mot chut.
float smin(float a, float b, float k) {
    k *= 6.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*h*k*(1.0/6.0);
}

// Smooth min da thuc bac 4
// → Muot nhat trong nhom da thuc.
float smin(float a, float b, float k) {
    k *= 16.0/3.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*h*(4.0-h)*k*(1.0/16.0);
}

// Smooth min hinh tron (Circular)
// → Vung pha tron co hinh dang cung tron.
float smin(float a, float b, float k) {
    k *= 1.0/(1.0-sqrt(0.5));
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
}
```

### Phep tru muot va Phep giao muot
Suy ra tu hop muot bang cach dao dau:
```glsl
float opSmoothUnion(float a, float b, float k) {
    k *= 4.0;
    float h = max(k-abs(a-b),0.0);
    return min(a,b) - h*h*0.25/k;
}

float opSmoothSubtraction(float a, float b, float k) {
    return -opSmoothUnion(a, -b, k);
}

float opSmoothIntersection(float a, float b, float k) {
    return -opSmoothUnion(-a, -b, k);
}
```

**Dieu quan trong:** Moi phep toan muot deu cho ket qua XAP XI, khong phai SDF chinh xac.
He so chuan hoa dam bao k tuong ung voi DO RONG pha tron thuc te (tinh bang don vi khoang cach).

---

## 5. Phep toan mien (Domain Operations)

### Dat vi tri (Positioning)
URL: https://iquilezles.org/articles/distfunctions/ (phan)

```glsl
// Xoay/Tinh tien -- chinh xac
// Chi can bien doi diem p bang phep bien doi nghich dao cua doi tuong
vec3 opTx(vec3 p, transform t, sdf3d primitive) {
    return primitive(invert(t)*p);
}

// Co gia (Scale) -- chinh xac (chi voi co deu!)
// Chia p cho s, roi nhan ket qua voi s
float opScale(vec3 p, float s, sdf3d primitive) {
    return primitive(p/s)*s;
}
```

### Doi xung (Symmetry)
→ Dung abs() de "gap" khong gian. MIEN PHI -- khong ton them tinh toan.
```glsl
// Doi xung truc X -- chinh xac neu doi tuong khong cat mat phang guong
float opSymX(vec3 p, sdf3d primitive) {
    p.x = abs(p.x);
    return primitive(p);
}

// Doi xung XZ (doi xung phan tu)
float opSymXZ(vec3 p, sdf3d primitive) {
    p.xz = abs(p.xz);
    return primitive(p);
}
```

### Lap khong gian (Domain Repetition)
URL: https://iquilezles.org/articles/sdfrepetition/

→ Tao VO HAN ban sao cua doi tuong chi voi MOT lan tinh SDF!
```glsl
// Lap vo han (khoang cach s)
float opRepetition(vec3 p, vec3 s, sdf3d primitive) {
    vec3 q = p - s*round(p/s);
    return primitive(q);
}

// Lap co gioi han (l = so ban sao toi da moi truc)
vec3 opLimitedRepetition(vec3 p, float s, vec3 l, sdf3d primitive) {
    vec3 q = p - s*clamp(round(p/s), -l, l);
    return primitive(q);
}
```

**Chu y QUAN TRONG:** Chi dung cho hinh doi xung mac dinh.
Voi hinh khong doi xung, phai tinh them 2^d hinh lan can (xem bai goc).
Dung ID ban sao `round(p/s)` de tao bien the cho tung ban sao (mau, kich thuoc, goc xoay).

### Keo dai (Elongation)
→ "Keo" hinh ra theo bat ky truc nao. Chinh xac.
```glsl
float opElongate(sdf3d primitive, vec3 p, vec3 h) {
    vec3 q = p - clamp(p, -h, h);
    return primitive(q);
}
```

### Bo tron (Rounding / Inflation)
→ Tru khoang cach = nhay ra mat dang iso ben ngoai. Lam tron canh.
```glsl
float opRound(sdf3d primitive, float rad) {
    return primitive(p) - rad;
}
```

### Rong ruot (Onion / Hollowing)
→ Tao vo mong. abs(sdf) lam cho trong va ngoai doi xung, tru do day.
```glsl
float opOnion(float sdf, float thickness) {
    return abs(sdf) - thickness;
}
```

---

## 6. Bien dang (Deformations)

URL: https://iquilezles.org/articles/distfunctions/ (phan)

**CANH BAO:** Moi phep bien dang deu PHA VO SDF (lam mat tinh Euclid).
Phai GIAM buoc raymarching. Giu bien dang NHO de hieu suat tot.

```glsl
// Dich chuyen (Displacement) -- cong ham bat ky vao SDF
// → Them chi tiet be mat (nhu goi, nep nhan) bang ham sin/noise
float opDisplace(sdf3d primitive, vec3 p) {
    float d1 = primitive(p);
    float d2 = displacement(p);  // vi du: sin(20*p.x)*sin(20*p.y)*sin(20*p.z)
    return d1 + d2;
}

// Xoan quanh truc Y (Twist)
// → Xoay mat cat ngang theo chieu cao. k = toc do xoan.
float opTwist(sdf3d primitive, vec3 p) {
    float k = 10.0;  // toc do xoan
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz, p.y);
    return primitive(q);
}

// Uon cong theo truc X (Bend)
// → Uon doi tuong nhu uon mot thanh kim loai. k = do uon.
float opCheapBend(sdf3d primitive, vec3 p) {
    float k = 10.0;  // do uon
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy, p.z);
    return primitive(q);
}
```

---

## 7. Tao 3D tu 2D

URL: https://iquilezles.org/articles/distfunctions/ (phan)

**Uu diem chinh:** Neu SDF 2D chinh xac, SDF 3D ket qua CUNG chinh xac.
Tot hon phep toan boolean (chi cho xap xi).

```glsl
// Xoay tron (Revolution) -- quay SDF 2D quanh truc Y voi offset o
// → Nhu tien gom: lay mat cat 2D va xoay quanh truc
float opRevolution(vec3 p, sdf2d primitive, float o) {
    vec2 q = vec2(length(p.xz) - o, p.y);
    return primitive(q);
}

// Do (Extrusion) -- keo dai SDF 2D doc truc Z voi chieu cao h
// → Nhu ep do: lay hinh 2D va day ra thanh hinh 3D
float opExtrusion(vec3 p, sdf2d primitive, float h) {
    float d = primitive(p.xy);
    vec2 w = vec2(d, abs(p.z) - h);
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
```

---

## 8. Phap tuyen va Gradient

URL: https://iquilezles.org/articles/normalsSDF/
Them: https://iquilezles.org/articles/distgradfunctions2d/
Them: https://iquilezles.org/articles/distgradfunctions3d/

**Phap tuyen la gi?** La huong VUONG GOC voi be mat tai mot diem.
Voi SDF, phap tuyen = gradient cua ham khoang cach (huong tang nhanh nhat).

### Sai phan trung tam (Central Differences) -- 6 lan tinh SDF
→ Lay mau 2 phia moi truc (x, y, z). Chinh xac nhung ton.
```glsl
vec3 calcNormal(vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(
        f(p+h.xyy) - f(p-h.xyy),
        f(p+h.yxy) - f(p-h.yxy),
        f(p+h.yyx) - f(p-h.yyx)));
}
```

### Ky thuat tu dien (Tetrahedron) -- 4 lan tinh SDF -- KHUYEN DUNG
Phat hien boi Paulo Falcao (Pouet, 2008), roi Paul Malin (Shadertoy).
→ Chi can 4 mau thay vi 6! Nhanh hon 33%.
```glsl
vec3 calcNormal(vec3 p) {
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize(
        k.xyy*f(p + k.xyy*h) +
        k.yyx*f(p + k.yyx*h) +
        k.yxy*f(p + k.yxy*h) +
        k.xxx*f(p + k.xxx*h));
}
```

**Tai sao no hoat dong?** Bon diem mau tao thanh hinh tu dien. Tong co trong so
tao ra trieu tieu (cancellation) de cho 4 dao ham huong, tu do tai tao gradient.
Sau khi chuan hoa, bang phap tuyen be mat.

### Sai phan tien (Forward Differences) -- 4 lan tinh SDF, co sai lech
```glsl
vec3 calcNormal(vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(
        f(p+h.xyy) - f(p),
        f(p+h.yxy) - f(p),
        f(p+h.yyx) - f(p)));
}
```

### Gradient giai tich (Analytic Gradients) cho 2D + 3D
De co hieu suat va do chinh xac TOI DA, Quilez cung cap cong thuc gradient giai tich
cho TAT CA hinh co ban 2D va 3D. Cac cong thuc nay tinh ca gia tri SDF va gradient
trong MOT lan, tai su dung cac gia tri trung gian.

URL: https://iquilezles.org/articles/distgradfunctions2d/
URL: https://iquilezles.org/articles/distgradfunctions3d/

### Canh bao khi lap trinh
Trinh bien dich co the inline bon ham f() roi gop chung lai, ngan GPU tinh song song.
Cach xu ly: dung bien toan cuc hoac thu thuat de ngan inline, hoac chap nhan cham hon.

---

## 9. Raymarching voi SDF

URL: https://iquilezles.org/articles/raymarchingdf/

### Thuat toan Sphere Tracing co ban
→ Ban mot tia tu mat (ro = goc, rd = huong). Tai moi buoc, tinh SDF.
→ SDF cho biet khoang cach den be mat gan nhat. Buoc tien dung bang khoang cach do.
→ Goi la "sphere tracing" vi tai moi diem, khoang cach an toan la ban kinh hinh cau rong.
```glsl
float raymarch(vec3 ro, vec3 rd, float tmax) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS && t < tmax; i++) {
        float h = map(ro + rd*t);
        if (h < EPSILON) return t;  // trung!
        t += h;  // buoc tien bang khoang cach den be mat gan nhat
    }
    return -1.0;  // truot (khong trung gi)
}
```

### Lich su
- 1972: Ricci -- phep toan boolean tren implicits bang min/max
- 1989: Wyvill & Wyvill -- soft objects
- 1988: Hart, Sandin, Kauffman -- SDF raymarched dau tien (fractal)
- 1995: Hart -- tai lieu hoa ky thuat (goi nham la "Sphere Tracing")
- 2001-2007: Quilez + demoscene -- ky thuat SDF hien dai
- 2005-2006: Keenan Crane, Alex Evans -- dong gop quan trong
- 2007: Quilez -- canh SDF huong nghe thuat dau tien voi bong mem, pha tron muot, lap mien
- 2008: Bai trinh bay NVscene "Rendering Worlds with Two Triangles"
- 2012+: Gioi hoc thuat chu y
- 2017+: Nganh cong nghiep ap dung (cong cu SDF thuong mai)

### Tim chinh xac bang nhi phan (Binary Search Refinement)
URL: https://iquilezles.org/articles/binarysearchsdf/

Sau khi phat hien va cham ban dau, tim nhi phan giua hai buoc cuoi de xac dinh
vi tri giao cat chinh xac hon -- cho phap tuyen va texture tot hon.

---

## 10. Bong mem (Soft Shadows)

URL: https://iquilezles.org/articles/rmshadows/

### Bong cung (Hard Shadows) -- co ban
→ Ban tia tu diem ve nguon sang. Neu gap vat can = bong (tra ve 0).
```glsl
float shadow(vec3 ro, vec3 rd, float mint, float maxt) {
    float t = mint;
    for (int i = 0; i < 256 && t < maxt; i++) {
        float h = map(ro + rd*t);
        if (h < 0.001) return 0.0;
        t += h;
    }
    return 1.0;
}
```

### Bong mem (ky thuat dot pha cua Quilez)
**Y tuong then chot:** `bong = lan_di_sot_gan_nhat / khoang_cach_den_lan_sot_do`

Trong luc raymarching ve phia nguon sang, ca hai gia tri deu co san:
- `h` = khoang cach den be mat gan nhat tai buoc hien tai
- `t` = khoang cach da di tu diem can tinh bong

→ Bong tu nhien sac net gan cho tiep xuc va mem xa cho tiep xuc (dung vat ly!).
```glsl
float softshadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 256 && t < maxt; i++) {
        float h = map(ro + rd*t);
        if (h < 0.001) return 0.0;
        res = min(res, k*h/t);
        t += h;
    }
    return res;
}
```

- `k` dieu khien do cung bong (8 = mem, 128 = cung)
- k lien quan den kich thuoc nguon sang: `k = 1/tan(banKinhGocNguonSang)`
- Chi phi: gan nhu MIEN PHI tren tia bong!

### Bong mem cai tien (2020)
Quilez cai tien ky thuat de giam loi (anh sang ri tai diem tiep xuc)
bang cach theo doi lan di sot gan nhat can than hon. Dung giao cua
hinh non voi hinh cau thay vi lay mau diem.

---

## 11. Ambient Occlusion

### AO hinh cau (giai tich)
URL: https://iquilezles.org/articles/sphereao/

Voi hinh cau ban kinh r o khoang cach d tu diem be mat co phap tuyen n,
do che khuat KHONG trong so cosine la:

→ Cong thuc don gian va dep bat ngo:
```
occlusion = 1 - sqrt(1 - (r/d)^2)    (khi d > r)
```

Voi ban cau trong so cosine (cho chieu sang tan xa):
```
AO = 1 - (r^2 * dot(n, huongDenCau)) / d^2
```

### AO hinh hop (giai tich)
URL: https://iquilezles.org/articles/boxocclusion/
Tinh AO giai tich tu hinh hop co huong.

### AO da do phan giai (Multi-Resolution AO)
URL: https://iquilezles.org/articles/multiresaocc/

Ba dai tan so:
- **Tan so cao**: AO theo dinh (vertex), bake vao mesh
- **Tan so trung binh**: SSAO (khong gian man hinh, 16 mau nhan)
- **Tan so thap**: Giai tich (AO hinh cau/hop cho vat che lon)

Ket hop ca ba de co do che khuat vat ly hop ly o MOI ty le.

### AO dua tren SDF
Khi raymarching SDF, uoc tinh AO bang cach lay mau SDF doc theo phap tuyen:
→ O moi buoc, so sanh do cao ky vong voi gia tri SDF that. Chenh lech = bi che.
```glsl
float calcAO(vec3 pos, vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map(pos + h*nor);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0*occ, 0.0, 1.0);
}
```

---

## 12. Suong mu va Hieu ung khi quyen

URL: https://iquilezles.org/articles/fog/

### Suong mu co ban
→ Vat cang xa cang bi suong mu che. Dung ham mu suy giam.
```glsl
vec3 applyFog(vec3 col, float t) {
    float fogAmount = 1.0 - exp(-t*b);
    vec3  fogColor  = vec3(0.5, 0.6, 0.7);
    return mix(col, fogColor, fogAmount);
}
```

### Suong mu co mau (phu thuoc huong mat troi)
→ Nhin ve phia mat troi = suong vang. Nhin nguoc lai = suong xanh.
```glsl
vec3 applyFog(vec3 col, float t, vec3 rd, vec3 lig) {
    float fogAmount = 1.0 - exp(-t*b);
    float sunAmount = max(dot(rd, lig), 0.0);
    vec3  fogColor  = mix(vec3(0.5,0.6,0.7),   // xanh
                          vec3(1.0,0.9,0.7),    // vang
                          pow(sunAmount, 8.0));
    return mix(col, fogColor, fogAmount);
}
```

### Hap thu + Tan xa noi (Extinction + Inscattering) -- dua tren vat ly
Tach suong mu thanh hai thanh phan doc lap:
→ 6 he so doc lap (3 hap thu RGB + 3 tan xa RGB) cho phep tao hieu ung
khi quyen phong phu: phat sang, bloom, tan xa, mau hoang hon.
```glsl
vec3 extColor = vec3(exp(-distance*be.x), exp(-distance*be.y), exp(-distance*be.z));
vec3 insColor = vec3(exp(-distance*bi.x), exp(-distance*bi.y), exp(-distance*bi.z));
finalColor = pixelColor*(1.0-extColor) + fogColor*insColor;
```

### Suong mu theo do cao (Height Fog)
Voi mat do khong dong deu thay doi theo do cao:
```
density(y) = a * exp(-b*y)
```
Tich phan doc theo tia de co suong mu do cao chinh xac.

---

## 13. Raymarching dia hinh

URL: https://iquilezles.org/articles/terrainmarching/

### Khai niem
Cho ham do cao `y = f(x,z)`, buoc doc theo tia kiem tra xem y hien tai < f(x,z) khong.
→ Khi tia "chui xuong" duoi mat dat = trung!

### Thuat toan co ban
```glsl
float castRay(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + t*rd;
        float h = p.y - terrain(p.xz);
        if (h < EPSILON) return t;
        t += max(h * 0.5, MIN_STEP);  // buoc ti le voi do cao tren mat dat
    }
    return -1.0;
}
```

### Toi uu hoa
1. **Buoc thich ung**: Buoc ti le voi khoang cach tren mat dat
2. **Tim nhi phan**: Sau khi vuot qua, chia doi de tim giao cat chinh xac
3. **LOD**: Giam chi tiet dia hinh (it FBM octave hon) cho mau xa
4. **Buoc hinh non (Cone step)**: Dung dao ham dia hinh de tinh buoc an toan

---

## 14. Chi tiet FBM trong SDF

URL: https://iquilezles.org/articles/fbmsdf/

### Van de
Them fBM (nhieu fractal) vao SDF bang phep cong don gian se PHA VO tinh chat SDF
(do lon gradient != 1). Gay ra loi raymarcher va cham lai.

### Giai phap: Smooth Union FBM
Thay vi cong nhieu octave bang phep toan, dung smooth-minimum de ket hop chung.
Moi fBM octave la mot "lop" SDF rieng, duoc ket hop voi smin.

→ Y tuong then chot: Thay `+` bang `smin()` trong vong lap tich luy fBM.
Bao toan tinh chat SDF trong khi van co chi tiet fractal.

```
// fBM truyen thong (PHA VO SDF):
d = sdf(p);
d += noise(p*freq) * amp;  // SAI: pha vo SDF

// fBM tuong thich SDF:
d = sdf(p);
for moi octave:
    d = smin(d, -noise(p*freq)*amp, k);  // DUNG: SDF hop le
```

---

## 15. Truong khoang cach Fractal

URL: https://iquilezles.org/articles/distancefractals/

### Khoang cach den tap Julia/Mandelbrot
Voi anh xa da thuc `z_{n+1} = z_n^p + c`:

1. Tinh anh xa Boettcher: `phi_c(z_0) = lim_{n->inf} z_n^{p^{-n}}`
2. The Hubbard-Douady: `G_c(z_0) = log|phi_c(z_0)|`
3. Uoc tinh khoang cach: `d = G / |grad(G)| = |z_n| * log|z_n| / |z'_n|`

Theo doi ca `z_n` va dao ham `z'_n` trong khi lap:
```
z'_{n+1} = p * z_n^{p-1} * z'_n        (Julia)
z'_{n+1} = p * z_n^{p-1} * z'_n + 1    (Mandelbrot)
```

Phuong phap nay cung dung cho fractal 3D (Mandelbulb, Julia 3D).

---

## 16. SDF ben trong (Interior SDFs)

URL: https://iquilezles.org/articles/interiordistance/

### Van de
Phep hop `min(a,b)` cho SDF chinh xac BEN NGOAI nhung SAI khoang cach BEN TRONG.
Dieu nay gay loi cho: render the tich, vat ly, mo hinh khong gian am (phong).

### Giai phap
1. **Bo qua**: Du dung cho raymarching do vat duc co ban
2. **Cong thuc chinh xac**: Voi 2 hinh, tinh khoang cach ben trong giai tich
3. **Thu thuat dao**: Mo hinh khong gian am truc tiep thay vi tru tu khong gian duong

### Cong thuc chinh xac cho hop ben trong
Khi ca a va b am (ben trong ca 2 hinh):
```
d_chinh_xac = -sqrt(a^2 + b^2)  // vung giao ben trong
```

---

## 17. Bounding Volume cho SDF (Tang toc)

URL: https://iquilezles.org/articles/sdfbounding/

### Hinh cau bao co ban
→ Truoc khi tinh SDF phuc tap, kiem tra hinh cau bao don gian.
→ Neu diem o xa (ngoai hinh cau bao) = bo qua, tiet kiem tinh toan.
```glsl
float sdCharacter(vec3 pos, float minDist) {
    // Bo qua som voi hinh cau bao
    float dB = sdSphere(pos, boundingRadius);
    if (dB > minDist) return minDist;

    // Chi tinh day du khi co the gan hon
    float d1 = sdHead(pos);
    float d2 = sdBody(pos);
    // ...
    return min(minDist, min(d1, d2));
}
```

### Cay phan cap Bounding Volume (BVH)
Long hinh cau bao theo cap bac:
→ Nhu cay quyet dinh: kiem tra nhom lon truoc, chi di vao nhom nho khi can.
```
Nhan vat
  +-- Than tren (hinh cau bao)
  |     +-- Dau
  |     +-- Than
  +-- Than duoi (hinh cau bao)
        +-- Chan trai
        +-- Chan phai
```

### KD-Tree cho SDF
Chia viec tinh SDF theo khong gian. Moi la chua mot tap con hinh co ban.
Dat duoc tang toc 8 lan trong thu nghiem cua Quilez.

### Thu thuat: Tai su dung hinh co ban lam Bounding Volume
Lay mot hinh co ban da co (vi du hinh cau than), phong to mot chut.
Dung lam bounding volume -- KHONG ton them chi phi cho phep kiem tra.

---

## 18. Chieu sang ngoai troi

URL: https://iquilezles.org/articles/outdoorslighting/

### Dan den (3-4 nguon sang)
1. **Nguon chinh (mat troi)**: Huong, mau am, tao bong
2. **Nguon phu/bau troi**: Tu tren xuong, mau xanh/lanh, dai dien ban cau bau troi
3. **Anh sang phan xa**: Tu duoi len, mau am, dai dien phan xa mat dat
4. **Anh sang vien (tuy chon)**: Chieu vien (rim lighting)

### Quy tac QUAN TRONG
1. **LUON lam viec trong khong gian mau tuyen tinh** roi chinh gamma cuoi cung
2. `finalColor = pow(color, vec3(1.0/2.2))`
3. Nguon phu/ambient phai NHO hon nhieu nguon chinh trong khong gian tuyen tinh
4. BRDF tan xa = `max(dot(N,L), 0.0)` don gian -- duong cong gamma lo phan con lai

### Tich hop AO
```glsl
col = sun_color * shadow * max(dot(nor,sun_dir), 0.0);
col += sky_color * (0.5 + 0.5*nor.y) * ao;
col += bounce_color * max(-nor.y, 0.0) * ao;
```

---

## 19. Meo tang hieu suat

Tong hop tu tat ca bai viet cua Quilez:

1. **Dung SDF chinh xac khi co the** -- xap xi can nhieu buoc raymarching hon
2. **Xoay tron/Do > Boolean** -- cho SDF chinh xac VA code nhanh hon
3. **Bo tron = phep tru** -- `sdf(p) - r` re hon smooth union
4. **Rong ruot = abs** -- `abs(sdf) - thickness` rat re
5. **Bounding volumes** -- bo qua SDF phuc tap khi ro rang xa
6. **Tai su dung hinh co ban lam bound** -- phong SDF co san de kiem tra
7. **Phap tuyen tu dien** -- 4 lan tinh thay vi 6 cho sai phan trung tam
8. **Tranh luong giac** -- dung thay the dai so (3 bai viet ve dieu nay!)
9. **Giu bien dang nho** -- xoan/uon lon = nhieu buoc raymarching hon
10. **LOD cho nhieu** -- it FBM octave hon cho mat xa
11. **Doi metric (chuan Ln)** -- dep nhung cham, tranh trong san xuat
12. **Lap khong gian** -- hinh hoc vo tan chi ton MOT lan tinh
13. **Doi xung** -- `abs(p.x)` giam nua the gioi MIEN PHI
14. **Dieu kien GPU** -- cau truc code de giam phan ky (divergence)
15. **Tim nhi phan de tinh chinh** -- raymarching tho roi chia doi

---

## 20. Ung dung SDF ngoai do hoa

Cong trinh cua Quilez cho thay SDF huu ich NGOAI viec render:

1. **Phat hien va cham**: SDF cho khoang cach chinh xac den be mat. Am = xuyen qua.
   Gradient cho huong phan hoi va cham.

2. **Mo phong vat ly**: Va cham dua tren SDF don gian hon dua tren mesh.
   Khoang cach + gradient = du de xu ly tiep xuc.

3. **Tao mo hinh thu tuc (Procedural)**: SDF mo ta hinh dang bang toan hoc.
   Toan bo canh trong < 1KB code (demoscene 4K/64K intros).

4. **Nen hinh dang**: SDF toan hoc < du lieu mesh cho vat the muot.

5. **Render font**: SDF dung rong rai cho render chu tren GPU
   (texture khoang cach cho ky tu khong phu thuoc do phan giai).

6. **Lap ke hoach duong di robot**: SDF cua vat can = khoang cach di chuyen an toan.

7. **Cong cu thiet ke 2D/3D**: Adobe Project Neo dung SDF.
   SDF cho phep boolean muot ma da giac kho lam.

8. **Hoc may**: Neural SDFs (DeepSDF, v.v.) hoc tu SDF toan hoc cua Quilez.
   Khung hinh co ban + phep toan anh xa sang phep toan mang neural.

9. **Am thanh**: Bai ve tong hop FM cho thay Quilez nghi ve SDF
   nhu khoi xay dung toan hoc tong quat, khong chi hinh hoc.

---

## 21. Danh muc bai viet day du

### Chi muc ham huu ich
| Bai viet | URL |
|----------|-----|
| Ham bien doi (Remapping functions) | https://iquilezles.org/articles/functions/ |
| SDF 3D | https://iquilezles.org/articles/distfunctions/ |
| SDF 2D | https://iquilezles.org/articles/distfunctions2d/ |
| SDF 2D va gradient | https://iquilezles.org/articles/distgradfunctions2d/ |
| SDF 3D va gradient | https://iquilezles.org/articles/distgradfunctions3d/ |
| SDF 2D trong chuan L-infinity | https://iquilezles.org/articles/distfunctions2dlinf/ |
| Hop bao 2D (Bounding Boxes) | https://iquilezles.org/articles/bboxes2d/ |
| Hop bao 3D (Bounding Boxes) | https://iquilezles.org/articles/bboxes3d/ |
| Ham giao tia-be mat (Ray-Surface intersectors) | https://iquilezles.org/articles/intersectors/ |
| Ham hinh cau (Sphere functions) | https://iquilezles.org/articles/spherefunctions/ |
| Ham hinh hop (Box functions) | https://iquilezles.org/articles/boxfunctions/ |
| Ham smoothstep | https://iquilezles.org/articles/smoothsteps/ |
| Ham sigmoid | https://iquilezles.org/articles/sigmoids/ |
| Ham luong giac (Trigonometric) | https://iquilezles.org/articles/trigfunctions/ |
| Thu tuc loc duoc (Filterable procedurals) | https://iquilezles.org/articles/filterableprocedurals/ |

### Nhieu thu tuc (Procedural Noises)
| Bai viet | URL |
|----------|-----|
| FBM | https://iquilezles.org/articles/fbm/ |
| Dao ham nhieu gradient (Gradient noise derivatives) | https://iquilezles.org/articles/gradientnoise/ |
| Dao ham nhieu gia tri (Value noise derivatives) | https://iquilezles.org/articles/morenoise/ |
| Bop mien (Domain warping) | https://iquilezles.org/articles/warp/ |
| Voronoise | https://iquilezles.org/articles/voronoise/ |
| Voronoi muot (Smooth voronoi) | https://iquilezles.org/articles/smoothvoronoi/ |
| Canh Voronoi (Voronoi edges) | https://iquilezles.org/articles/voronoilines/ |

### SDF & Raymarching
| Bai viet | URL |
|----------|-----|
| Raymarching SDF | https://iquilezles.org/articles/raymarchingdf/ |
| Smooth minimum cho SDF | https://iquilezles.org/articles/smin/ |
| Lap khong gian (Domain Repetition) | https://iquilezles.org/articles/sdfrepetition/ |
| Bong mem (Soft Shadows) | https://iquilezles.org/articles/rmshadows/ |
| Phap tuyen so cho SDF (Numerical normals) | https://iquilezles.org/articles/normalsSDF/ |
| Hop tron muot (Smooth Rounded Boxes) | https://iquilezles.org/articles/roundedboxes/ |
| SDF ben trong (Interior SDFs) | https://iquilezles.org/articles/interiordistance/ |
| Phep toan Xor cho SDF | https://iquilezles.org/articles/sdfxor/ |
| Bounding Volume cho SDF | https://iquilezles.org/articles/sdfbounding/ |
| Tim nhi phan raycasting (Binary-search) | https://iquilezles.org/articles/binarysearchsdf/ |
| Chi tiet FBM trong SDF | https://iquilezles.org/articles/fbmsdf/ |
| SDF Ellipsoid | https://iquilezles.org/articles/ellipsoids/ |
| Xap xi khoang cach den implicits | https://iquilezles.org/articles/distance/ |
| Fractal Menger | https://iquilezles.org/articles/menger/ |
| Raymarching dia hinh | https://iquilezles.org/articles/terrainmarching/ |
| Depth buffer voi raymarching | https://iquilezles.org/articles/raypolys/ |
| Gioi thieu SDF raymarching (2008) | https://iquilezles.org/articles/nvscene2008/ |

### Chieu sang (Lighting)
| Bai viet | URL |
|----------|-----|
| Chieu sang ngoai troi (Outdoors lighting) | https://iquilezles.org/articles/outdoorslighting/ |
| Suong mu tot hon (Better fog) | https://iquilezles.org/articles/fog/ |
| AO da do phan giai (Multiresolution AO) | https://iquilezles.org/articles/multiresaocc/ |
| Dao ham huong (Directional derivative) | https://iquilezles.org/articles/derivative/ |
| AO khong gian man hinh (Screen space AO) | https://iquilezles.org/articles/ssao/ |
| AO theo dinh (Per vertex AO) | https://iquilezles.org/articles/pervertexao/ |
| Chieu sang toan cuc don gian (Simple GI) | https://iquilezles.org/articles/simplegi/ |

### Toan hoc huu ich
| Bai viet | URL |
|----------|-----|
| AO hinh cau (Sphere ambient occlusion) | https://iquilezles.org/articles/sphereao/ |
| AO hinh hop (Box ambient occlusion) | https://iquilezles.org/articles/boxocclusion/ |
| Mat do hinh cau (Sphere density) | https://iquilezles.org/articles/spheredensity/ |
| Tam nhin hinh cau (Sphere visibility) | https://iquilezles.org/articles/sphereocc/ |
| Phep chieu hinh cau (Sphere projection) | https://iquilezles.org/articles/sphereproj/ |
| Bong mem hinh cau (Sphere soft shadow) | https://iquilezles.org/articles/sphereshadow/ |
| IK don gian khong can luong giac (Simple IK) | https://iquilezles.org/articles/simpleik/ |
| Noi suy song tuyen nghich (Inverse bilinear) | https://iquilezles.org/articles/ibilinear/ |
| Khoang cach den tam giac (Distance to triangle) | https://iquilezles.org/articles/triangledistance/ |
| Hop bao Bezier (Bezier bounding box) | https://iquilezles.org/articles/bezierbbox/ |
| Hop bao dia/hinh tru (Disk/cylinder bbox) | https://iquilezles.org/articles/diskbbox/ |
| Khoang cach den elip (Distance to ellipse) | https://iquilezles.org/articles/ellipsedist/ |
| Lam viec voi elip (Working with ellipses) | https://iquilezles.org/articles/ellipses/ |
| Phap tuyen/dien tich da giac (Normal/areas) | https://iquilezles.org/articles/areas/ |
| Dien tich tam giac (Area of a triangle) | https://iquilezles.org/articles/trianglearea/ |
| Tinh phap tuyen mesh (Computing mesh normals) | https://iquilezles.org/articles/normals/ |
| Hinh cau va (Patched sphere) | https://iquilezles.org/articles/patchedsphere/ |
| Chuoi Fourier (Fourier series) | https://iquilezles.org/articles/fourier/ |
| Tich phan smoothstep (Smoothstep integral) | https://iquilezles.org/articles/smoothstepintegral/ |
| Phan xa va cat (Reflect and Clip) | https://iquilezles.org/articles/dontflip/ |
| Tong hop FM (FM synthesis) | https://iquilezles.org/articles/fm/ |
| Tu duy voi quaternion (Thinking with quaternions) | https://iquilezles.org/articles/quaternions/ |
| trisect() nhanh trong GLSL | https://iquilezles.org/articles/trisect/ |
| Nghich dao smoothstep (Inverse smoothstep) | https://iquilezles.org/articles/ismoothstep/ |
| Float va ngau nhien (Float and random) | https://iquilezles.org/articles/sfrand/ |

### Texture va Loc (Texturing and Filtering)
| Bai viet | URL |
|----------|-----|
| Premultiplied Alpha | https://iquilezles.org/articles/premultipliedalpha/ |
| Anh xa song phang (Biplanar mapping) | https://iquilezles.org/articles/biplanar/ |
| Lap texture (Texture repetition) | https://iquilezles.org/articles/texturerepetition/ |
| Loc texture thu tuc (Filtering procedural textures) | https://iquilezles.org/articles/filtering/ |
| Gioi han dai tan thu tuc (Band-limiting) | https://iquilezles.org/articles/bandlimiting/ |
| Vi phan tia va texture (Ray differentials) | https://iquilezles.org/articles/filteringrm/ |
| Loc o vuong giai tich (Analytic checkers filtering) | https://iquilezles.org/articles/checkerfiltering/ |
| Loc o vuong cai tien (Improved checkers) | https://iquilezles.org/articles/morecheckerfiltering/ |
| Loc song tuyen cai tien (Improved bilinear) | https://iquilezles.org/articles/texture/ |
| Noi suy phan cung cai tien (Improved HW interpolation) | https://iquilezles.org/articles/hwinterpolation/ |
| Duong noi hinh tru (Cylinder seams) | https://iquilezles.org/articles/tunnel/ |

### Raytracing
| Bai viet | URL |
|----------|-----|
| Path-tracing trong mot gio | https://iquilezles.org/articles/simplepathtracing/ |
| Bong mem hinh cau (Sphere soft shadow) | https://iquilezles.org/articles/sphereshadow/ |
| Raytracing co dien (Old school) | https://iquilezles.org/articles/raytracing/ |
| Raytracing GPU don gian | https://iquilezles.org/articles/simplegpurt/ |
| Tracing theo o (Tracing in tiles) | https://iquilezles.org/articles/cputiles/ |
| SSE cho CPU tracers | https://iquilezles.org/articles/sse/ |

### Fractal
| Bai viet | URL |
|----------|-----|
| Tinh SDF cua fractal | https://iquilezles.org/articles/distancefractals/ |
| Fractal Mandelbulb | https://iquilezles.org/articles/mandelbulb/ |
| Tap Julia 3D (3D Julia set) | https://iquilezles.org/articles/juliasets3d/ |
| Bay quy dao 3D (3D orbit traps) | https://iquilezles.org/articles/orbittraps3d/ |
| Bay quy dao thu tuc (Procedural orbit traps) | https://iquilezles.org/articles/ftrapsprocedural/ |
| Bay quy dao bitmap (Bitmaps orbit traps) | https://iquilezles.org/articles/ftrapsbitmap/ |
| Bay quy dao hinh hoc (Geometric orbit traps) | https://iquilezles.org/articles/ftrapsgeometric/ |
| Fractal Budhabrot | https://iquilezles.org/articles/budhabrot/ |
| Hinh anh Popcorn | https://iquilezles.org/articles/popcorns/ |
| Fractal IFS | https://iquilezles.org/articles/ifsfractals/ |
| Fractal Lyapunov | https://iquilezles.org/articles/lyapunovfractals/ |
| So dem lap lien tuc (Continuous iteration count) | https://iquilezles.org/articles/msetsmooth/ |

### Render/Engine
| Bai viet | URL |
|----------|-----|
| Dieu kien GPU (GPU Conditionals) | https://iquilezles.org/articles/gpuconditionals/ |
| Tranh luong giac I (Avoiding trigonometry I) | https://iquilezles.org/articles/noacos/ |
| Tranh luong giac II (Avoiding trigonometry II) | https://iquilezles.org/articles/sincos/ |
| Tranh luong giac III (Avoiding trigonometry III) | https://iquilezles.org/articles/noatan/ |
| Tinh thoi gian bang Ticks | https://iquilezles.org/articles/ticks/ |
| Sua loi frustum culling | https://iquilezles.org/articles/frustumcorrect/ |
| Render hop ly / thanh noi (Floating bar) | https://iquilezles.org/articles/floatingbar/ |
| Hack giao tia-tam giac (Hacking intersector) | https://iquilezles.org/articles/hackingintersector/ |
| Render lap the (Stereo rendering) | https://iquilezles.org/articles/stereo/ |
| VR co ban (Basic VR) | https://iquilezles.org/articles/basicvr/ |
| Lam mo dung gamma (Gamma correct blurring) | https://iquilezles.org/articles/gamma/ |
| Dong goi C++ (C++ encapsulation) | https://iquilezles.org/articles/cppencapsulation/ |

### Nen & Code nho (Compression & Size Coding)
| Bai viet | URL |
|----------|-----|
| Thuat toan di truyen (Genetic algorithm) | https://iquilezles.org/articles/genetic/ |
| Nen mesh (Mesh compression) | https://iquilezles.org/articles/meshcompression/ |
| Nen wavelet (Wavelet compression) | https://iquilezles.org/articles/wavelet/ |
| Do hoa thu tuc trong 4KB | https://iquilezles.org/articles/proceduralgfx/ |
| Behind Elevated | https://iquilezles.org/articles/function2009/ |
| Bang mau don gian (Simple color palettes) | https://iquilezles.org/articles/palettes/ |
| Luu tru float nho gon (Compact float storage) | https://iquilezles.org/articles/float4k/ |
| Bien dich nho (Compiling small) | https://iquilezles.org/articles/compilingsmall/ |
| Ghi PNG nho (Mini PNG writer) | https://iquilezles.org/articles/minipng64/ |

---

## Tom tat Nguyen ly Cot loi

1. **SDF = truong vo huong, gia tri = khoang cach co dau den be mat gan nhat**
   - Duong (+) = ngoai, Am (-) = trong, Khong (0) = tren be mat
   - Gradient co do dai don vi cho SDF that

2. **Hinh co ban la khoi xay dung** -- hinh cau, hop, hinh xuyen, vien nang, hinh non, v.v.
   Moi hinh co cong thuc dang dong nho gon.

3. **Phep toan Boolean ket hop hinh co ban**:
   - Hop = min(a,b) -- chinh xac ben ngoai
   - Tru = max(-a,b) -- chi xap xi
   - Giao = max(a,b) -- chi xap xi
   - Xor = max(min(a,b),-max(a,b)) -- chinh xac moi noi (da chung minh)

4. **Smooth minimum pha tron huu co** -- chia khoa de "nan" voi SDF.
   Bay bien the, tat ca chuan hoa theo don vi khoang cach.

5. **Phep toan mien MIEN PHI**: lap, doi xung, keo dai.
   Hinh hoc vo tan tu mot lan tinh.

6. **Raymarching = sphere tracing**: buoc theo gia tri SDF tai moi diem.
   Hoi tu trong O(log) buoc cho hinh hoc muot.

7. **Bong mem gan nhu MIEN PHI** voi SDF: `min(k*h/t)` doc theo tia bong.

8. **Phap tuyen = gradient cua SDF**. Ky thuat tu dien: 4 lan tinh, khong sai lech.

9. **Xoay tron va do SDF 2D cho SDF 3D chinh xac** -- tot hon phep toan boolean.

10. **Thu tu hieu suat**: SDF chinh xac > SDF xap xi > SDF bien dang.
    Giu chinh xac nhat co the de raymarching hieu qua toi da.

---

*Tai lieu nay trich tu https://iquilezles.org -- 144 bai viet cua Inigo Quilez.*
*Ban dich tieng Viet khong dau boi Nox, 2026-03-31.*
