# Inigo Quilez SDF Reference -- Complete Formulas & Techniques

Source: https://iquilezles.org (144 articles total)
Extracted: 2026-03-31

This document captures every key SDF formula and technique from Inigo Quilez's
website. Quilez is THE authority on Signed Distance Fields for computer graphics.
His work is the mathematical foundation for all SDF-based rendering, modeling,
and increasingly, non-graphics applications.

---

## Table of Contents

1. [3D Distance Functions (Primitives)](#1-3d-distance-functions)
2. [2D Distance Functions (Primitives)](#2-2d-distance-functions)
3. [Boolean Operations (Union, Subtraction, Intersection, Xor)](#3-boolean-operations)
4. [Smooth Minimum / Smooth Union](#4-smooth-minimum)
5. [Domain Operations (Repetition, Symmetry, Elongation)](#5-domain-operations)
6. [Deformations (Twist, Bend, Displacement)](#6-deformations)
7. [Constructing 3D from 2D (Revolution, Extrusion)](#7-constructing-3d-from-2d)
8. [Normals / Gradient Computation](#8-normals-and-gradients)
9. [Raymarching SDFs](#9-raymarching-sdfs)
10. [Soft Shadows from SDF](#10-soft-shadows)
11. [Ambient Occlusion from SDF](#11-ambient-occlusion)
12. [Fog and Atmospheric Effects](#12-fog-and-atmospheric)
13. [Terrain Raymarching](#13-terrain-raymarching)
14. [FBM Detail in SDFs](#14-fbm-detail-in-sdfs)
15. [Fractal Distance Fields](#15-fractal-distance-fields)
16. [Interior SDFs](#16-interior-sdfs)
17. [SDF Bounding Volumes (Acceleration)](#17-sdf-bounding-volumes)
18. [Outdoors Lighting Rig](#18-outdoors-lighting)
19. [Performance Tips](#19-performance-tips)
20. [Non-Graphics SDF Applications](#20-non-graphics-applications)
21. [Complete Article Index](#21-complete-article-index)

---

## 1. 3D Distance Functions

URL: https://iquilezles.org/articles/distfunctions/
Shadertoy playlist: https://www.shadertoy.com/playlist/43cXRl

Convention: `dot2(v) = dot(v,v)` (squared length).
All primitives centered at origin. Transform point p for placement.

### Exact SDFs (true Euclidean distance)

**Sphere**
```glsl
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}
```

**Box** (https://www.youtube.com/watch?v=62-pRVZuS5c)
```glsl
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
```

**Round Box**
```glsl
float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}
```

**Box Frame**
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

**Torus**
```glsl
float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x, p.y);
    return length(q) - t.y;
}
```

**Capped Torus**
```glsl
float sdCappedTorus(vec3 p, vec2 sc, float ra, float rb) {
    p.x = abs(p.x);
    float k = (sc.y*p.x > sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
    return sqrt(dot(p,p) + ra*ra - 2.0*ra*k) - rb;
}
```

**Link**
```glsl
float sdLink(vec3 p, float le, float r1, float r2) {
    vec3 q = vec3(p.x, max(abs(p.y)-le,0.0), p.z);
    return length(vec2(length(q.xy)-r1, q.z)) - r2;
}
```

**Infinite Cylinder**
```glsl
float sdCylinder(vec3 p, vec3 c) {
    return length(p.xz - c.xy) - c.z;
}
```

**Cone** (exact, with height h, sin/cos angle c)
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

**Plane** (n must be normalized)
```glsl
float sdPlane(vec3 p, vec3 n, float h) {
    return dot(p,n) + h;
}
```

**Hexagonal Prism**
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

**Capsule / Line** (between points a and b, radius r)
```glsl
float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}
```

**Vertical Capsule**
```glsl
float sdVerticalCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}
```

**Capped Cylinder** (vertical)
```glsl
float sdCappedCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
```

**Capped Cylinder** (arbitrary orientation, between a and b)
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

**Rounded Cylinder**
```glsl
float sdRoundedCylinder(vec3 p, float ra, float rb, float h) {
    vec2 d = vec2(length(p.xz)-ra+rb, abs(p.y)-h+rb);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}
```

**Capped Cone** (vertical)
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

**Solid Angle**
```glsl
float sdSolidAngle(vec3 p, vec2 c, float ra) {
    vec2 q = vec2(length(p.xz), p.y);
    float l = length(q) - ra;
    float m = length(q - c*clamp(dot(q,c),0.0,ra));
    return max(l, m*sign(c.y*q.x-c.x*q.y));
}
```

**Cut Sphere**
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

**Death Star** (sphere with spherical bite)
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

**Round Cone** (vertical, radii r1,r2, height h)
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

**Vesica Segment** (between points a,b with width w)
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

**Rhombus**
```glsl
float sdRhombus(vec3 p, float la, float lb, float h, float ra) {
    p = abs(p);
    float f = clamp((la*p.x-lb*p.z+lb*lb)/(la*la+lb*lb), 0.0, 1.0);
    vec2  w = p.xz - vec2(la,lb)*vec2(f,1.0-f);
    vec2  q = vec2(length(w)*sign(w.x)-ra, p.y-h);
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}
```

**Octahedron** (exact)
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

**Octahedron** (bound, fast)
```glsl
float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}
```

**Pyramid** (unit base, height h)
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

**Triangle** (unsigned distance, given vertices a,b,c)
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

**Quad** (unsigned distance, given vertices a,b,c,d)
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

### Approximate / Bound SDFs

**Ellipsoid** (lower bound)
```glsl
float sdEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}
```

**Triangular Prism** (lower bound)
```glsl
float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z-h.y, max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}
```

---

## 2. 2D Distance Functions

URL: https://iquilezles.org/articles/distfunctions2d/
Shadertoy playlist: https://www.shadertoy.com/playlist/MXdSRf

All exact SDFs unless noted. Convention: `dot2(v) = dot(v,v)`.

### Complete 2D Primitive List

| Primitive | Key Formula Pattern |
|-----------|-------------------|
| Circle | `length(p) - r` |
| Box | `length(max(abs(p)-b, 0)) + min(max(d.x,d.y), 0)` |
| Rounded Box | Box with per-corner radii via `r.xy/r.zw` selection |
| Chamfer Box | Box with chamfered corners |
| Oriented Box | Box rotated by angle between two points |
| Segment | Point-to-line-segment: `length(pa - ba*clamp(dot(pa,ba)/dot(ba,ba), 0, 1))` |
| Rhombus | Exact signed distance |
| Isosceles Trapezoid | Exact signed distance |
| Parallelogram | Exact signed distance |
| Equilateral Triangle | Mirror + edge clamp technique |
| Isosceles Triangle | Exact signed distance |
| Triangle (arbitrary) | Edge distances + winding number sign |
| Uneven Capsule | Two radii capsule |
| Regular Pentagon | Reflection technique with cos/sin constants |
| Regular Hexagon | Reflection technique: `k = vec3(-0.866025404, 0.5, 0.577350269)` |
| Regular Octagon | Double reflection technique |
| Hexagram (Star of David) | Two reflections |
| Pentagram | Three reflections |
| Regular Star (n-pointed) | Angle-based with `atan` |
| Pie (sector) | Arc sector of circle |
| Cut Disk | Circle with flat cut |
| Arc | Circular arc with thickness |
| Ring | Ring sector |
| Horseshoe | Open arc with thickness |
| Vesica | Lens shape |
| Oriented Vesica | Between two points |
| Moon | Sphere difference |
| Circle Cross (Rounded) | Cross inscribed in circle |
| Egg | Asymmetric egg shape |
| Heart | Classic heart shape |
| Cross | Cross/plus shape |
| Rounded X | X shape with rounding |
| Polygon (arbitrary N) | Edge iteration + winding number |
| Ellipse | Quartic equation solver (exact!) |
| Parabola | Cubic equation solver |
| Parabola Segment | Bounded parabola |
| Quadratic Bezier | Cubic solver for closest point on curve |
| Blobby Cross | Smooth cross shape |
| Tunnel | Tunnel/corridor shape |
| Stairs | Step function shape |
| Quadratic Circle | `|x|^0.5 + |y|^0.5 = 1` |
| Hyperbola | Exact signed distance |
| Cool S | The "cool S" everyone drew in school |

### Key 2D Formula: Arbitrary Polygon SDF
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

### Key 2D Formula: Ellipse SDF (exact)
Uses quartic equation, Cardano's formula. One of the most complex 2D SDFs.
See: https://iquilezles.org/articles/ellipsedist/

---

## 3. Boolean Operations

URL: https://iquilezles.org/articles/distfunctions/ (section)
Also: https://iquilezles.org/articles/sdfxor/
Also: https://iquilezles.org/articles/interiordistance/

### Basic Operations
```glsl
// Union -- exact exterior, incorrect interior
float opUnion(float a, float b) { return min(a,b); }

// Subtraction -- bound (not exact), NOT commutative
float opSubtraction(float a, float b) { return max(-a,b); }

// Intersection -- bound (not exact)
float opIntersection(float a, float b) { return max(a,b); }

// Xor -- EXACT everywhere (proven by Quilez!)
float opXor(float a, float b) { return max(min(a,b), -max(a,b)); }
```

**Critical insight**: Union (min) is exact in the exterior but WRONG in the
interior. Subtraction (max) and Intersection (max) are bounds, not exact SDFs.
Only Xor produces a correct SDF unconditionally -- Quilez proved this formally.

### The 8 Possible Combinations of Two SDFs
There are exactly 2^3 = 8 ways to combine two overlapping shapes (three
overlap regions, each can be interior or exterior). Four are union/sub/int/xor.
Three are trivial (just a, just b, empty set). The eighth is xor.

---

## 4. Smooth Minimum

URL: https://iquilezles.org/articles/smin/

The smooth minimum blends two SDFs together within distance k (in world units).
Enables organic, clay-like modeling. All variants below are normalized so k
maps to the same blending thickness.

### Seven Smooth Minimum Variants

```glsl
// Exponential smooth min
float smin(float a, float b, float k) {
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

// Root smooth min
float smin(float a, float b, float k) {
    k *= 2.0;
    float x = b-a;
    return 0.5*(a+b-sqrt(x*x+k*k));
}

// Sigmoid smooth min (new)
float smin(float a, float b, float k) {
    k *= log(2.0);
    float x = b-a;
    return a + x/(1.0-exp2(x/k));
}

// Quadratic polynomial smooth min (MOST POPULAR)
float smin(float a, float b, float k) {
    k *= 4.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*k*(1.0/4.0);
}

// Cubic polynomial smooth min
float smin(float a, float b, float k) {
    k *= 6.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*h*k*(1.0/6.0);
}

// Quartic polynomial smooth min
float smin(float a, float b, float k) {
    k *= 16.0/3.0;
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - h*h*h*(4.0-h)*k*(1.0/16.0);
}

// Circular smooth min
float smin(float a, float b, float k) {
    k *= 1.0/(1.0-sqrt(0.5));
    float h = max(k-abs(a-b), 0.0)/k;
    return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
}
```

### Smooth Subtraction and Intersection
Derived from smooth union via negation:
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

**Key insight**: All smooth operations produce bounds, not exact SDFs.
The normalization factors ensure k maps to actual distance units of blend width.

---

## 5. Domain Operations

### Positioning
URL: https://iquilezles.org/articles/distfunctions/ (section)

```glsl
// Rotation/Translation -- exact
// Just transform the point with inverse of object's transform
vec3 opTx(vec3 p, transform t, sdf3d primitive) {
    return primitive(invert(t)*p);
}

// Scale -- exact (uniform only!)
float opScale(vec3 p, float s, sdf3d primitive) {
    return primitive(p/s)*s;
}
```

### Symmetry
```glsl
// X-axis symmetry -- exact if object doesn't cross mirror plane
float opSymX(vec3 p, sdf3d primitive) {
    p.x = abs(p.x);
    return primitive(p);
}

// XZ symmetry (quarter symmetry)
float opSymXZ(vec3 p, sdf3d primitive) {
    p.xz = abs(p.xz);
    return primitive(p);
}
```

### Domain Repetition
URL: https://iquilezles.org/articles/sdfrepetition/

```glsl
// Infinite repetition (spacing s)
float opRepetition(vec3 p, vec3 s, sdf3d primitive) {
    vec3 q = p - s*round(p/s);
    return primitive(q);
}

// Limited repetition (l = max instances per axis)
vec3 opLimitedRepetition(vec3 p, float s, vec3 l, sdf3d primitive) {
    vec3 q = p - s*clamp(round(p/s), -l, l);
    return primitive(q);
}
```

**Critical**: Only works correctly for symmetric shapes by default.
For non-symmetric shapes, must evaluate 2^d neighbors (see full article).
Use instance ID `round(p/s)` for per-instance variation (color, size, rotation).

### Elongation
```glsl
// Elongation -- exact, splits primitive and connects pieces
float opElongate(sdf3d primitive, vec3 p, vec3 h) {
    vec3 q = p - clamp(p, -h, h);
    return primitive(q);
}
```

### Rounding (Inflation)
```glsl
// Subtract distance = jump to outer isosurface
float opRound(sdf3d primitive, float rad) {
    return primitive(p) - rad;
}
```

### Onion (Hollowing)
```glsl
// Create shell of given thickness
float opOnion(float sdf, float thickness) {
    return abs(sdf) - thickness;
}
```

---

## 6. Deformations

URL: https://iquilezles.org/articles/distfunctions/ (section)

**Warning**: All deformations break the SDF (make it non-Euclidean). Must reduce
raymarching step size. Keep deformations small for best performance.

```glsl
// Displacement -- add arbitrary function to SDF
float opDisplace(sdf3d primitive, vec3 p) {
    float d1 = primitive(p);
    float d2 = displacement(p);  // e.g., sin(20*p.x)*sin(20*p.y)*sin(20*p.z)
    return d1 + d2;
}

// Twist around Y axis
float opTwist(sdf3d primitive, vec3 p) {
    float k = 10.0;  // twist rate
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz, p.y);
    return primitive(q);
}

// Bend along X axis
float opCheapBend(sdf3d primitive, vec3 p) {
    float k = 10.0;  // bend rate
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy, p.z);
    return primitive(q);
}
```

---

## 7. Constructing 3D from 2D

URL: https://iquilezles.org/articles/distfunctions/ (section)

**Key advantage**: If the 2D SDF is exact, the resulting 3D SDF is also exact.
This is better than boolean operations which produce only bounds.

```glsl
// Revolution -- rotate 2D SDF around Y axis with offset o
float opRevolution(vec3 p, sdf2d primitive, float o) {
    vec2 q = vec2(length(p.xz) - o, p.y);
    return primitive(q);
}

// Extrusion -- extend 2D SDF along Z axis with height h
float opExtrusion(vec3 p, sdf2d primitive, float h) {
    float d = primitive(p.xy);
    vec2 w = vec2(d, abs(p.z) - h);
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
```

---

## 8. Normals and Gradients

URL: https://iquilezles.org/articles/normalsSDF/
Also: https://iquilezles.org/articles/distgradfunctions2d/
Also: https://iquilezles.org/articles/distgradfunctions3d/

### Central Differences (6 evaluations)
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

### Tetrahedron Technique (4 evaluations -- PREFERRED)
First seen by Paulo Falcao (Pouet, 2008), then Paul Malin (Shadertoy).
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

**Why it works**: The four sample points form a tetrahedron. The weighted sum
produces cancellations that yield four directional derivatives, which reconstruct
the gradient. After normalization, this equals the surface normal.

### Forward Differences (4 evaluations, biased)
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

### Analytic Gradients (2D + 3D)
For maximum performance and accuracy, Quilez provides analytic gradient formulas
for all 2D and 3D primitives. These compute both SDF value and gradient in one
pass, reusing intermediate terms.

URL: https://iquilezles.org/articles/distgradfunctions2d/
URL: https://iquilezles.org/articles/distgradfunctions3d/

### Implementation Warning
The compiler may inline the four `f()` calls and merge them, preventing the GPU
from computing them in parallel. Workaround: use a global or trick to prevent
inlining, or accept the performance hit.

---

## 9. Raymarching SDFs

URL: https://iquilezles.org/articles/raymarchingdf/

### Basic Sphere Tracing Algorithm
```glsl
float raymarch(vec3 ro, vec3 rd, float tmax) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS && t < tmax; i++) {
        float h = map(ro + rd*t);
        if (h < EPSILON) return t;  // hit
        t += h;  // step by distance to nearest surface
    }
    return -1.0;  // miss
}
```

**Key principle**: At each point, the SDF tells you the distance to the nearest
surface. You can safely step that far without missing anything. This is why it
is called "sphere tracing" (stepping by radius of empty sphere around point).

### History
- 1972: Ricci -- boolean operations on implicits via min/max
- 1989: Wyvill & Wyvill -- soft objects
- 1988: Hart, Sandin, Kauffman -- first raymarched SDF (fractals)
- 1995: Hart -- documented technique (miscalled "Sphere Tracing")
- 2001-2007: Quilez + demoscene -- modern SDF techniques
- 2005-2006: Keenan Crane, Alex Evans -- key contributions
- 2007: Quilez -- first art-directed SDF scenes with soft shadows, smooth blending, domain repetition
- 2008: NVscene presentation "Rendering Worlds with Two Triangles"
- 2012+: Academia notices
- 2017+: Industry adoption (commercial SDF tools)

### Binary Search Refinement
URL: https://iquilezles.org/articles/binarysearchsdf/

After initial hit detection, binary search between last two steps refines
intersection point for more accurate normals and texturing.

---

## 10. Soft Shadows

URL: https://iquilezles.org/articles/rmshadows/

### Hard Shadows (basic)
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

### Soft Shadows (Quilez's breakthrough technique)
**Key insight**: `shadow = closest_miss / distance_to_closest_miss`

During raymarching toward light, both quantities are available:
- `h` = distance to nearest surface at current step
- `t` = distance traveled from shading point

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

- `k` controls shadow hardness (8 = soft, 128 = hard)
- Shadows are naturally sharper near contact (physically correct penumbra)
- k relates to physical light size: `k = 1/tan(lightAngularRadius)`
- Cost: essentially FREE on top of shadow ray

### Improved Soft Shadows (2020)
Quilez improved the technique to reduce artifacts (light leaking at contact
points) by tracking the closest approach more carefully. Uses intersection of
cone with sphere rather than point sampling.

---

## 11. Ambient Occlusion

### Sphere AO (Analytic)
URL: https://iquilezles.org/articles/sphereao/

For a sphere of radius r at distance d from a surface point with normal n,
the occlusion without cosine weighting is:

```
occlusion = 1 - sqrt(1 - (r/d)^2)    (for d > r)
```

With cosine-weighted hemisphere (for diffuse lighting):
```
AO = 1 - (r^2 * dot(n, sphereDir)) / d^2
```

The result is surprisingly simple and elegant.

### Box AO (Analytic)
URL: https://iquilezles.org/articles/boxocclusion/
Analytic ambient occlusion from an oriented box.

### Multi-Resolution AO
URL: https://iquilezles.org/articles/multiresaocc/

Three frequency bands:
- **High frequency**: Per-vertex AO, baked into mesh
- **Medium frequency**: SSAO (screen-space, 16 kernel samples)
- **Low frequency**: Analytic (sphere/box AO for large occluders)

Combine all three for physically plausible occlusion at all scales.

### SDF-Based AO
When raymarching SDFs, AO can be estimated by sampling the SDF along the normal:
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

## 12. Fog and Atmospheric

URL: https://iquilezles.org/articles/fog/

### Basic Fog
```glsl
vec3 applyFog(vec3 col, float t) {
    float fogAmount = 1.0 - exp(-t*b);
    vec3  fogColor  = vec3(0.5, 0.6, 0.7);
    return mix(col, fogColor, fogAmount);
}
```

### Colored Fog (sun-direction dependent)
```glsl
vec3 applyFog(vec3 col, float t, vec3 rd, vec3 lig) {
    float fogAmount = 1.0 - exp(-t*b);
    float sunAmount = max(dot(rd, lig), 0.0);
    vec3  fogColor  = mix(vec3(0.5,0.6,0.7),   // blue
                          vec3(1.0,0.9,0.7),    // yellow
                          pow(sunAmount, 8.0));
    return mix(col, fogColor, fogAmount);
}
```

### Extinction + Inscattering (physically based)
Split fog into two independent terms:
```glsl
// Independent RGB extinction and inscattering coefficients
vec3 extColor = vec3(exp(-distance*be.x), exp(-distance*be.y), exp(-distance*be.z));
vec3 insColor = vec3(exp(-distance*bi.x), exp(-distance*bi.y), exp(-distance*bi.z));
finalColor = pixelColor*(1.0-extColor) + fogColor*insColor;
```

Six independent coefficients (3 extinction RGB + 3 inscattering RGB) enable
rich atmospheric effects: glow, bloom, scattering, sunset colors -- all from
a simple fog equation modification.

### Height Fog
For non-uniform density varying with altitude:
```
density(y) = a * exp(-b*y)
```
Integrate along ray analytically for correct height fog.

---

## 13. Terrain Raymarching

URL: https://iquilezles.org/articles/terrainmarching/

### Concept
Given height function `y = f(x,z)`, step along ray checking if current y < f(x,z).

### Basic Algorithm
```glsl
float castRay(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + t*rd;
        float h = p.y - terrain(p.xz);
        if (h < EPSILON) return t;
        t += max(h * 0.5, MIN_STEP);  // step proportional to height above terrain
    }
    return -1.0;
}
```

### Optimizations
1. **Adaptive step size**: Step proportional to distance above terrain
2. **Binary search refinement**: After crossing, bisect for exact intersection
3. **LOD**: Reduce terrain detail (fewer FBM octaves) for distant samples
4. **Cone step**: Use terrain derivative to compute safe step size

---

## 14. FBM Detail in SDFs

URL: https://iquilezles.org/articles/fbmsdf/

### The Problem
Adding fBM (fractal noise) to an SDF via simple addition breaks the SDF property
(gradient magnitude != 1). This causes raymarcher artifacts and slowdowns.

### The Solution: Smooth Union FBM
Instead of arithmetically adding noise octaves, use smooth-minimum to
combine them. Each fBM octave is a separate SDF "layer" combined with smin.

Key insight: Replace `+` with `smin()` in the fBM accumulation loop.
This preserves the SDF property while achieving fractal detail.

```
// Traditional fBM (breaks SDF):
d = sdf(p);
d += noise(p*freq) * amp;  // BAD: breaks SDF

// SDF-compatible fBM:
d = sdf(p);
for each octave:
    d = smin(d, -noise(p*freq)*amp, k);  // GOOD: valid SDF
```

---

## 15. Fractal Distance Fields

URL: https://iquilezles.org/articles/distancefractals/

### Distance to Julia/Mandelbrot Sets
For polynomial map `z_{n+1} = z_n^p + c`:

1. Compute Boettcher map: `phi_c(z_0) = lim_{n->inf} z_n^{p^{-n}}`
2. Hubbard-Douady potential: `G_c(z_0) = log|phi_c(z_0)|`
3. Distance estimate: `d = G / |grad(G)| = |z_n| * log|z_n| / |z'_n|`

Track both `z_n` and derivative `z'_n` during iteration:
```
z'_{n+1} = p * z_n^{p-1} * z'_n        (Julia)
z'_{n+1} = p * z_n^{p-1} * z'_n + 1    (Mandelbrot)
```

This works for 3D fractals too (Mandelbulb, Julia 3D sets).

---

## 16. Interior SDFs

URL: https://iquilezles.org/articles/interiordistance/

### The Problem
`min(a,b)` union gives correct exterior SDF but WRONG interior distances.
This breaks: volumetric rendering, physics, negative-space modeling (rooms).

### Solutions
1. **Ignore it**: Fine for basic opaque raymarching
2. **Correct formula**: For two shapes, compute actual interior distance analytically
3. **Flip trick**: Model the negative space directly instead of subtracting from positive

### Key Formula for Correct Interior Union
When both a and b are negative (inside both shapes):
```
d_correct = -sqrt(a^2 + b^2)  // inside intersection region
```

---

## 17. SDF Bounding Volumes

URL: https://iquilezles.org/articles/sdfbounding/

### Basic Bounding Sphere
```glsl
float sdCharacter(vec3 pos, float minDist) {
    // Early skip with bounding sphere
    float dB = sdSphere(pos, boundingRadius);
    if (dB > minDist) return minDist;

    // Full evaluation only if potentially closer
    float d1 = sdHead(pos);
    float d2 = sdBody(pos);
    // ...
    return min(minDist, min(d1, d2));
}
```

### Bounding Volume Hierarchy (BVH)
Nest bounding spheres hierarchically:
```
Character
  +-- Upper body (bounding sphere)
  |     +-- Head
  |     +-- Torso
  +-- Lower body (bounding sphere)
        +-- Left leg
        +-- Right leg
```

### KD-Tree for SDF
Split SDF evaluation spatially. Each leaf contains a subset of primitives.
Achieved 8x speedup in Quilez's tests.

### Trick: Reuse Primitive as Bounding Volume
Take an existing primitive (e.g., body's main sphere), inflate it slightly.
Use as bounding volume -- zero extra cost for the bounding check.

---

## 18. Outdoors Lighting

URL: https://iquilezles.org/articles/outdoorslighting/

### The Rig (3-4 lights)
1. **Key light** (sun): Directional, warm color, casts shadows
2. **Fill/sky light**: From above, cool/blue, represents sky hemisphere
3. **Bounce light**: From below, warm, represents ground bounce
4. **Back light** (optional): Rim lighting

### Critical Rules
1. **ALWAYS work in linear color space** with gamma correction at the end
2. `finalColor = pow(color, vec3(1.0/2.2))`
3. Ambient/fill should be much smaller than key light in linear space
4. Diffuse BRDF = plain `max(dot(N,L), 0.0)` -- gamma curve handles the rest

### AO Integration
```glsl
col = sun_color * shadow * max(dot(nor,sun_dir), 0.0);
col += sky_color * (0.5 + 0.5*nor.y) * ao;
col += bounce_color * max(-nor.y, 0.0) * ao;
```

---

## 19. Performance Tips

Gathered across all Quilez articles:

1. **Use exact SDFs when possible** -- bounds require more raymarching steps
2. **Revolution/extrusion > boolean** -- produces exact SDFs AND faster code
3. **Rounding = subtraction** -- `sdf(p) - r` is cheaper than smooth union
4. **Onion = abs** -- `abs(sdf) - thickness` is very cheap
5. **Bounding volumes** -- skip complex SDF when clearly far away
6. **Reuse primitives as bounds** -- inflate existing SDF for bounding check
7. **Tetrahedron normals** -- 4 evaluations vs 6 for central differences
8. **Avoid trigonometry** -- use algebraic alternatives (3 articles on this!)
9. **Keep deformations small** -- large twist/bend = many extra raymarching steps
10. **LOD for noise** -- fewer FBM octaves for distant surfaces
11. **Change of metric (Ln norms)** -- cute but slow, avoid in production
12. **Domain repetition** -- infinite geometry at cost of ONE evaluation
13. **Symmetry** -- `abs(p.x)` halves your world for free
14. **GPU conditionals** -- structure code to minimize divergence
15. **Binary search for final refinement** -- coarse raymarch then bisect

---

## 20. Non-Graphics SDF Applications

Quilez's work demonstrates SDFs are useful beyond rendering:

1. **Collision detection**: SDF gives exact distance to surface. Negative = penetration.
   Normal from gradient gives collision response direction.

2. **Physics simulation**: SDF-based collision is simpler than mesh-based.
   Distance + gradient = all you need for contact.

3. **Procedural modeling**: SDFs naturally describe shapes mathematically.
   Entire scenes in < 1KB of code (demoscene 4K/64K intros).

4. **Shape compression**: Mathematical SDF < mesh data for smooth objects.

5. **Font rendering**: SDFs widely used for GPU text rendering
   (distance textures for resolution-independent glyphs).

6. **Robotics path planning**: SDF of obstacles = safe movement distance.

7. **2D/3D design tools**: Adobe Project Neo uses SDFs for design.
   SDFs enable smooth boolean operations that polygons struggle with.

8. **Machine learning**: Neural SDFs (DeepSDF, etc.) learned from Quilez's
   mathematical SDFs. The primitives + operations framework maps to neural
   network operations.

9. **Audio**: FM synthesis article shows Quilez thinking about SDFs
   as general mathematical building blocks, not just geometry.

---

## 21. Complete Article Index

### Indices of Useful Functions
| Article | URL |
|---------|-----|
| Remapping functions | https://iquilezles.org/articles/functions/ |
| 3D SDFs | https://iquilezles.org/articles/distfunctions/ |
| 2D SDFs | https://iquilezles.org/articles/distfunctions2d/ |
| 2D SDFs and gradients | https://iquilezles.org/articles/distgradfunctions2d/ |
| 3D SDFs and gradients | https://iquilezles.org/articles/distgradfunctions3d/ |
| 2D SDFs in L-infinity norm | https://iquilezles.org/articles/distfunctions2dlinf/ |
| 2D Bounding Boxes | https://iquilezles.org/articles/bboxes2d/ |
| 3D Bounding Boxes | https://iquilezles.org/articles/bboxes3d/ |
| Ray-Surface intersectors | https://iquilezles.org/articles/intersectors/ |
| Sphere functions | https://iquilezles.org/articles/spherefunctions/ |
| Box functions | https://iquilezles.org/articles/boxfunctions/ |
| Smoothstep functions | https://iquilezles.org/articles/smoothsteps/ |
| Sigmoid functions | https://iquilezles.org/articles/sigmoids/ |
| Trigonometric functions | https://iquilezles.org/articles/trigfunctions/ |
| Filterable procedurals | https://iquilezles.org/articles/filterableprocedurals/ |

### Procedural Noises
| Article | URL |
|---------|-----|
| FBM | https://iquilezles.org/articles/fbm/ |
| Gradient noise derivatives | https://iquilezles.org/articles/gradientnoise/ |
| Value noise derivatives | https://iquilezles.org/articles/morenoise/ |
| Domain warping | https://iquilezles.org/articles/warp/ |
| Voronoise | https://iquilezles.org/articles/voronoise/ |
| Smooth voronoi | https://iquilezles.org/articles/smoothvoronoi/ |
| Voronoi edges | https://iquilezles.org/articles/voronoilines/ |

### SDFs & Raymarching
| Article | URL |
|---------|-----|
| Raymarching SDFs | https://iquilezles.org/articles/raymarchingdf/ |
| Smooth minimum for SDFs | https://iquilezles.org/articles/smin/ |
| Domain Repetition | https://iquilezles.org/articles/sdfrepetition/ |
| Soft Shadows | https://iquilezles.org/articles/rmshadows/ |
| Numerical normals for SDFs | https://iquilezles.org/articles/normalsSDF/ |
| Smooth Rounded Boxes | https://iquilezles.org/articles/roundedboxes/ |
| Interior SDFs | https://iquilezles.org/articles/interiordistance/ |
| Xor operator for SDFs | https://iquilezles.org/articles/sdfxor/ |
| SDF Bounding Volumes | https://iquilezles.org/articles/sdfbounding/ |
| Binary-search raycasting | https://iquilezles.org/articles/binarysearchsdf/ |
| FBM detail in SDFs | https://iquilezles.org/articles/fbmsdf/ |
| Ellipsoid SDF | https://iquilezles.org/articles/ellipsoids/ |
| Approximating distance to implicits | https://iquilezles.org/articles/distance/ |
| Menger fractal | https://iquilezles.org/articles/menger/ |
| Raymarching terrains | https://iquilezles.org/articles/terrainmarching/ |
| Depth buffer with raymarching | https://iquilezles.org/articles/raypolys/ |
| Intro to SDF raymarching (2008) | https://iquilezles.org/articles/nvscene2008/ |

### Lighting
| Article | URL |
|---------|-----|
| Outdoors lighting | https://iquilezles.org/articles/outdoorslighting/ |
| Better fog | https://iquilezles.org/articles/fog/ |
| Multiresolution ambient occlusion | https://iquilezles.org/articles/multiresaocc/ |
| Directional derivative | https://iquilezles.org/articles/derivative/ |
| Screen space AO | https://iquilezles.org/articles/ssao/ |
| Per vertex AO | https://iquilezles.org/articles/pervertexao/ |
| Simple global illumination | https://iquilezles.org/articles/simplegi/ |

### Useful Maths
| Article | URL |
|---------|-----|
| Sphere ambient occlusion | https://iquilezles.org/articles/sphereao/ |
| Box ambient occlusion | https://iquilezles.org/articles/boxocclusion/ |
| Sphere density | https://iquilezles.org/articles/spheredensity/ |
| Sphere visibility | https://iquilezles.org/articles/sphereocc/ |
| Sphere projection | https://iquilezles.org/articles/sphereproj/ |
| Sphere soft shadow | https://iquilezles.org/articles/sphereshadow/ |
| Simple IK without trig | https://iquilezles.org/articles/simpleik/ |
| Inverse bilinear interpolation | https://iquilezles.org/articles/ibilinear/ |
| Distance to triangle | https://iquilezles.org/articles/triangledistance/ |
| Bezier bounding box | https://iquilezles.org/articles/bezierbbox/ |
| Disk/cylinder bounding box | https://iquilezles.org/articles/diskbbox/ |
| Distance to ellipse | https://iquilezles.org/articles/ellipsedist/ |
| Working with ellipses | https://iquilezles.org/articles/ellipses/ |
| Normal/areas for polygons | https://iquilezles.org/articles/areas/ |
| Area of a triangle | https://iquilezles.org/articles/trianglearea/ |
| Computing mesh normals | https://iquilezles.org/articles/normals/ |
| Patched sphere | https://iquilezles.org/articles/patchedsphere/ |
| Fourier series | https://iquilezles.org/articles/fourier/ |
| Smoothstep integral | https://iquilezles.org/articles/smoothstepintegral/ |
| Reflect and Clip | https://iquilezles.org/articles/dontflip/ |
| FM synthesis | https://iquilezles.org/articles/fm/ |
| Thinking with quaternions | https://iquilezles.org/articles/quaternions/ |
| Fast trisect() in GLSL | https://iquilezles.org/articles/trisect/ |
| Inverse smoothstep | https://iquilezles.org/articles/ismoothstep/ |
| Float and random | https://iquilezles.org/articles/sfrand/ |

### Texturing and Filtering
| Article | URL |
|---------|-----|
| Premultiplied Alpha | https://iquilezles.org/articles/premultipliedalpha/ |
| Biplanar mapping | https://iquilezles.org/articles/biplanar/ |
| Texture repetition | https://iquilezles.org/articles/texturerepetition/ |
| Filtering procedural textures | https://iquilezles.org/articles/filtering/ |
| Band-limiting procedurals | https://iquilezles.org/articles/bandlimiting/ |
| Ray differentials and textures | https://iquilezles.org/articles/filteringrm/ |
| Analytic checkers filtering | https://iquilezles.org/articles/checkerfiltering/ |
| Improved checkers filtering | https://iquilezles.org/articles/morecheckerfiltering/ |
| Improved bilinear filtering | https://iquilezles.org/articles/texture/ |
| Improved hardware interpolation | https://iquilezles.org/articles/hwinterpolation/ |
| Cylinder seams | https://iquilezles.org/articles/tunnel/ |

### Raytracing
| Article | URL |
|---------|-----|
| Path-tracing in one hour | https://iquilezles.org/articles/simplepathtracing/ |
| Sphere soft shadow | https://iquilezles.org/articles/sphereshadow/ |
| Old school raytracing | https://iquilezles.org/articles/raytracing/ |
| Simple GPU raytracing | https://iquilezles.org/articles/simplegpurt/ |
| Tracing in tiles | https://iquilezles.org/articles/cputiles/ |
| SSE for CPU tracers | https://iquilezles.org/articles/sse/ |

### Fractals
| Article | URL |
|---------|-----|
| Computing SDF of fractals | https://iquilezles.org/articles/distancefractals/ |
| Mandelbulb fractal | https://iquilezles.org/articles/mandelbulb/ |
| 3D Julia set fractals | https://iquilezles.org/articles/juliasets3d/ |
| 3D orbit traps | https://iquilezles.org/articles/orbittraps3d/ |
| Procedural orbit traps | https://iquilezles.org/articles/ftrapsprocedural/ |
| Bitmaps orbit traps | https://iquilezles.org/articles/ftrapsbitmap/ |
| Geometric orbit traps | https://iquilezles.org/articles/ftrapsgeometric/ |
| Budhabrot fractals | https://iquilezles.org/articles/budhabrot/ |
| Popcorn images | https://iquilezles.org/articles/popcorns/ |
| IFS fractals | https://iquilezles.org/articles/ifsfractals/ |
| Lyapunov fractals | https://iquilezles.org/articles/lyapunovfractals/ |
| Continuous iteration count | https://iquilezles.org/articles/msetsmooth/ |

### Renderer/Engine
| Article | URL |
|---------|-----|
| GPU Conditionals | https://iquilezles.org/articles/gpuconditionals/ |
| Avoiding trigonometry I | https://iquilezles.org/articles/noacos/ |
| Avoiding trigonometry II | https://iquilezles.org/articles/sincos/ |
| Avoiding trigonometry III | https://iquilezles.org/articles/noatan/ |
| Timing in Ticks | https://iquilezles.org/articles/ticks/ |
| Fixing frustum culling | https://iquilezles.org/articles/frustumcorrect/ |
| Rational rendering / floating bar | https://iquilezles.org/articles/floatingbar/ |
| Hacking ray-triangle intersector | https://iquilezles.org/articles/hackingintersector/ |
| Stereo rendering | https://iquilezles.org/articles/stereo/ |
| Basic VR | https://iquilezles.org/articles/basicvr/ |
| Gamma correct blurring | https://iquilezles.org/articles/gamma/ |
| C++ encapsulation | https://iquilezles.org/articles/cppencapsulation/ |

### Compression & Size Coding
| Article | URL |
|---------|-----|
| Genetic algorithm | https://iquilezles.org/articles/genetic/ |
| Mesh compression | https://iquilezles.org/articles/meshcompression/ |
| Wavelet compression | https://iquilezles.org/articles/wavelet/ |
| Procedural graphics in 4KB | https://iquilezles.org/articles/proceduralgfx/ |
| Behind Elevated | https://iquilezles.org/articles/function2009/ |
| Simple color palettes | https://iquilezles.org/articles/palettes/ |
| Compact storage of floats | https://iquilezles.org/articles/float4k/ |
| Compiling small | https://iquilezles.org/articles/compilingsmall/ |
| Mini PNG writer | https://iquilezles.org/articles/minipng64/ |

---

## Summary of Core Principles

1. **SDF = scalar field where value = signed distance to nearest surface**
   - Positive = outside, Negative = inside, Zero = on surface
   - Gradient has unit length for true SDFs

2. **Primitives are building blocks** -- sphere, box, torus, capsule, cone, etc.
   Each has a compact closed-form formula.

3. **Boolean operations combine primitives**:
   - Union = min(a,b) -- exact exterior
   - Subtraction = max(-a,b) -- bound only
   - Intersection = max(a,b) -- bound only
   - Xor = max(min(a,b),-max(a,b)) -- exact everywhere (proven)

4. **Smooth minimum blends organically** -- the key to sculpting with SDFs.
   Seven variants, all normalized to distance units.

5. **Domain operations are free**: repetition, symmetry, elongation.
   Infinite geometry from one evaluation.

6. **Raymarching = sphere tracing**: step by SDF value at each point.
   Converges in O(log) steps for smooth geometry.

7. **Soft shadows are essentially free** with SDFs: `min(k*h/t)` along shadow ray.

8. **Normals = gradient of SDF**. Tetrahedron technique: 4 evaluations, unbiased.

9. **Revolution and extrusion of 2D SDFs produce exact 3D SDFs** -- better than
   boolean operations.

10. **Performance hierarchy**: exact SDF > bound SDF > deformed SDF.
    Keep as exact as possible for maximum raymarching efficiency.

---

*This document extracted from https://iquilezles.org -- 144 articles by Inigo Quilez.*
*All code snippets are MIT licensed. Mathematical/shader art is protected.*
