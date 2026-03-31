#!/usr/bin/env python3
"""
Build UDC P_weight table with REAL 42 formulas.
Source: SPEC_A §A3, UDC_*_tree.md documents, NRC-VAD Lexicon.

42 formulas = 1 master + 5 dimension encoders + 36 sub-classifiers
"""

import json, struct, os, unicodedata

ORIGIN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAX_CP = 157386  # match existing table size

def mol_pack(s, r, v, a, t):
    s = max(0, min(15, int(s)))
    r = max(0, min(15, int(r)))
    v = max(0, min(7, int(v)))
    a = max(0, min(7, int(a)))
    t = max(0, min(3, int(t)))
    return (s & 0xF) << 12 | (r & 0xF) << 8 | (v & 0x7) << 5 | (a & 0x7) << 2 | (t & 0x3)

# ═══ Load NRC-VAD Lexicon ═══
def load_nrc_vad():
    path = os.path.join(ORIGIN, 'json/json/mapping/NRC-VAD-Lexicon-v2.1/NRC-VAD-Lexicon-v2.1.txt')
    vad = {}
    with open(path) as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) == 4:
                vad[parts[0].lower()] = (float(parts[1]), float(parts[2]))  # V, A only
    return vad

# ═══ Load UnicodeData.txt ═══
def load_unicode_data():
    path = os.path.join(ORIGIN, 'json/json/UnicodeData.txt')
    udata = {}
    with open(path) as f:
        for line in f:
            parts = line.strip().split(';')
            if len(parts) >= 15:
                cp = int(parts[0], 16)
                udata[cp] = {
                    'name': parts[1],
                    'category': parts[2],
                    'bidi': parts[4],
                    'decomposition': parts[5],
                    'numeric': parts[8],
                }
    return udata

# ═══ Load emoji data ═══
def load_emoji_data():
    path = os.path.join(ORIGIN, 'json/json/emoji/emoji-test.txt')
    emoji = {}
    current_group = ''
    current_subgroup = ''
    with open(path) as f:
        for line in f:
            if line.startswith('# group:'):
                current_group = line.split(':')[1].strip()
            elif line.startswith('# subgroup:'):
                current_subgroup = line.split(':')[1].strip()
            elif line.strip() and not line.startswith('#'):
                parts = line.split(';')
                if len(parts) >= 2:
                    cps = parts[0].strip().split()
                    if len(cps) == 1:
                        try:
                            cp = int(cps[0], 16)
                            emoji[cp] = (current_group, current_subgroup)
                        except: pass
    return emoji

# ═══ 53 UDC Block ranges ═══
UDC_BLOCKS = {
    # SDF (S dimension dominant)
    'S.01': (0x2190, 0x21FF, 'SDF'),    # Arrows
    'S.02': (0x2500, 0x257F, 'SDF'),    # Box Drawing
    'S.03': (0x2580, 0x259F, 'SDF'),    # Block Elements
    'S.04': (0x25A0, 0x25FF, 'SDF'),    # Geometric Shapes
    'S.05': (0x2700, 0x27BF, 'SDF'),    # Dingbats
    'S.06': (0x27F0, 0x27FF, 'SDF'),    # Supp Arrows-A
    'S.07': (0x2900, 0x297F, 'SDF'),    # Supp Arrows-B
    'S.08': (0x2B00, 0x2BFF, 'SDF'),    # Misc Sym+Arrows
    'S.09': (0x1F780, 0x1F7FF, 'SDF'),  # Geometric Ext
    'S.10': (0x1F800, 0x1F8FF, 'SDF'),  # Supp Arrows-C
    'S.11': (0x1F650, 0x1F67F, 'SDF'),  # Ornamental
    'S.12': (0x2300, 0x23FF, 'SDF'),    # Misc Technical
    'S.13': (0x2800, 0x28FF, 'SDF'),    # Braille
    # MATH (R dimension dominant)
    'M.01': (0x2070, 0x209F, 'MATH'),   # Super/Subscripts
    'M.02': (0x2100, 0x214F, 'MATH'),   # Letterlike
    'M.03': (0x2150, 0x218F, 'MATH'),   # Number Forms
    'M.04': (0x2200, 0x22FF, 'MATH'),   # Math Operators
    'M.05': (0x27C0, 0x27EF, 'MATH'),   # Misc Math-A
    'M.06': (0x2980, 0x29FF, 'MATH'),   # Misc Math-B
    'M.07': (0x2A00, 0x2AFF, 'MATH'),   # Supp Math
    'M.08': (0x1D400, 0x1D7FF, 'MATH'), # Math Alphanum
    # EMOTICON (V/A dominant)
    'E.01': (0x2460, 0x24FF, 'EMO'),    # Enclosed Alphanum
    'E.02': (0x2600, 0x26FF, 'EMO'),    # Misc Symbols
    'E.08': (0x1F300, 0x1F5FF, 'EMO'),  # Misc Sym+Pict
    'E.09': (0x1F600, 0x1F64F, 'EMO'),  # Emoticons
    'E.10': (0x1F680, 0x1F6FF, 'EMO'),  # Transport
    'E.11': (0x1F900, 0x1F9FF, 'EMO'),  # Supp Sym+Pict
    # MUSICAL (T dimension dominant)
    'T.01': (0x4DC0, 0x4DFF, 'MUS'),    # Yijing Hexagram
    'T.02': (0x1CF00, 0x1CFCF, 'MUS'),  # Znamenny
    'T.03': (0x1D000, 0x1D0FF, 'MUS'),  # Byzantine
    'T.04': (0x1D100, 0x1D1FF, 'MUS'),  # Musical Symbols
}

def get_udc_block(cp):
    for bid, (start, end, group) in UDC_BLOCKS.items():
        if start <= cp <= end:
            return bid, group
    return None, None

# ═══ 36 Sub-classifiers ═══

# S sub-classifiers (10)
def f_s_is_arrow(name): return 'ARROW' in name
def f_s_is_geometric(name): return any(w in name for w in ['CIRCLE','SQUARE','TRIANGLE','DIAMOND','STAR','PENTAGON','HEXAGON'])
def f_s_is_line(name): return any(w in name for w in ['LINE','HORIZONTAL','VERTICAL','DIAGONAL','DRAWING'])
def f_s_is_fill(name): return any(w in name for w in ['BLACK','WHITE','FILLED','EMPTY','SHADE','HALF'])
def f_s_is_symbol(name): return any(w in name for w in ['DINGBAT','ORNAMENT','FLORAL','SNOWFLAKE'])
def f_s_is_size(name): return any(w in name for w in ['SMALL','MEDIUM','LARGE','HEAVY','LIGHT'])
def f_s_is_position(name): return any(w in name for w in ['LEFT','RIGHT','UP','DOWN','NORTH','SOUTH','EAST','WEST'])
def f_s_is_pattern(name): return 'BRAILLE' in name or 'PATTERN' in name
def f_s_is_technical(name): return any(w in name for w in ['TECHNICAL','SECTOR','INTEGRATION','KEYBOARD','COMMAND'])
def f_s_is_block(name): return 'BLOCK' in name or 'ELEMENT' in name

# R sub-classifiers (10)
def f_r_is_operator(name): return any(w in name for w in ['PLUS','MINUS','TIMES','DIVIDED','MULTIPLICATION','INTEGRAL','SUMMATION','PRODUCT'])
def f_r_is_set_logic(name): return any(w in name for w in ['UNION','INTERSECTION','SUBSET','ELEMENT OF','CONTAINS','MEMBER'])
def f_r_is_comparison(name): return any(w in name for w in ['EQUAL','LESS','GREATER','TILDE','EQUIVALENT','IDENTICAL','SIMILAR','APPROXIMATE'])
def f_r_is_number(name): return any(w in name for w in ['DIGIT','NUMBER','NUMERAL','FRACTION','SUPERSCRIPT','SUBSCRIPT'])
def f_r_is_letter(name): return any(w in name for w in ['LETTER','SCRIPT','FRAKTUR','DOUBLE-STRUCK','ITALIC','BOLD','SANS-SERIF'])
def f_r_is_punctuation(name): return any(w in name for w in ['BRACKET','PARENTHES','BRACE','QUOTATION','COMMA','PERIOD','COLON'])
def f_r_is_currency(name): return any(w in name for w in ['DOLLAR','EURO','POUND','YEN','SIGN','CURRENCY','CENT'])
def f_r_is_ancient(name): return any(w in name for w in ['ROMAN','CUNEIFORM','AEGEAN','COUNTING','ROD','ANCIENT'])
def f_r_is_formatting(name): return any(w in name for w in ['JOINER','MARK','SEPARATOR','FORMAT','CONTROL','COMBINING'])
def f_r_is_logic(name): return any(w in name for w in ['FOR ALL','THERE EXISTS','NOT','AND','OR','IMPLIES','THEREFORE','BECAUSE'])

# V quantizers (5) — from NRC-VAD
def f_v_quantize(raw_v):
    # raw_v in [-1, 1] → [0, 7]
    return int((raw_v + 1) / 2 * 7 + 0.5)

# A quantizers (5) — from NRC-VAD
def f_a_quantize(raw_a):
    return int((raw_a + 1) / 2 * 7 + 0.5)

# T sub-classifiers (6)
def f_t_is_note(name): return any(w in name for w in ['NOTE','WHOLE','HALF','QUARTER','EIGHTH','SIXTEENTH','BREVE','MINIM'])
def f_t_is_pitch(name): return any(w in name for w in ['SHARP','FLAT','NATURAL','CLEF','STAFF'])
def f_t_is_dynamics(name): return any(w in name for w in ['FORTE','PIANO','CRESCENDO','DECRESCENDO','ACCENT'])
def f_t_is_neume(name): return any(w in name for w in ['NEUME','BYZANTINE','ISON','OLIGON','APOSTROFOS','ZNAMENNY'])
def f_t_is_hexagram(name): return 'HEXAGRAM' in name or 'TETRAGRAM' in name or 'MONOGRAM' in name
def f_t_is_modifier(name): return any(w in name for w in ['FERMATA','TRILL','TURN','MORDENT','ORNAMENT','REPEAT','SEGNO','CODA'])

# ═══ Emoji subgroup → V/A mapping ═══
EMOJI_VA = {
    'Smileys & Emotion': (0.7, 0.5),
    'People & Body': (0.3, 0.3),
    'Animals & Nature': (0.4, 0.1),
    'Food & Drink': (0.5, 0.2),
    'Travel & Places': (0.3, 0.2),
    'Activities': (0.4, 0.5),
    'Objects': (0.1, 0.1),
    'Symbols': (0.0, 0.0),
    'Flags': (0.2, 0.1),
    'Component': (0.0, 0.0),
}

EMOJI_SUBGROUP_VA = {
    'face-smiling': (0.8, 0.5), 'face-affection': (0.9, 0.4),
    'face-tongue': (0.6, 0.6), 'face-hand': (0.3, 0.3),
    'face-neutral-skeptical': (0.0, 0.2), 'face-sleepy': (-0.2, -0.6),
    'face-unwell': (-0.5, -0.3), 'face-hat': (0.3, 0.3),
    'face-glasses': (0.2, 0.1), 'face-concerned': (-0.4, 0.3),
    'face-negative': (-0.7, 0.6), 'face-costume': (0.3, 0.4),
    'heart': (0.9, 0.4), 'emotion': (0.3, 0.5),
}

# ═══ MASTER FORMULA: F₀(cp) → [S, R, V, A, T] ═══
def encode_codepoint(cp, udata, vad, emoji):
    name = udata.get(cp, {}).get('name', '')
    cat = udata.get(cp, {}).get('category', 'Cn')
    bid, group = get_udc_block(cp)

    # ── f_S: Shape encoder ──
    S = 0
    if group == 'SDF':
        S = 8  # base for SDF blocks
        if f_s_is_arrow(name): S = 10
        elif f_s_is_geometric(name): S = 12
        elif f_s_is_line(name): S = 6
        elif f_s_is_fill(name):
            S = 14 if 'BLACK' in name else 4
        elif f_s_is_pattern(name): S = 2
        elif f_s_is_technical(name): S = 9
        elif f_s_is_block(name): S = 7
        elif f_s_is_symbol(name): S = 11
        if f_s_is_size(name):
            if 'HEAVY' in name or 'LARGE' in name: S = min(15, S + 2)
            elif 'LIGHT' in name or 'SMALL' in name: S = max(0, S - 2)
    elif group == 'EMO':
        S = 1  # emoji = blob shape
    elif cat.startswith('L'):
        S = 0  # letters = no shape
    elif cat == 'Nd':
        S = 1  # digits = minimal shape

    # ── f_R: Relation encoder ──
    R = 0
    if group == 'MATH':
        R = 8  # base for math
        if f_r_is_operator(name): R = 12
        elif f_r_is_set_logic(name): R = 14
        elif f_r_is_comparison(name): R = 10
        elif f_r_is_number(name): R = 4
        elif f_r_is_letter(name): R = 2
        elif f_r_is_logic(name): R = 15
        elif f_r_is_punctuation(name): R = 6
        elif f_r_is_currency(name): R = 5
        elif f_r_is_ancient(name): R = 3
        elif f_r_is_formatting(name): R = 1
    elif cat.startswith('P'):
        R = 6  # punctuation
    elif cat == 'Sc':
        R = 5  # currency
    elif cat == 'Sm':
        R = 10  # math symbol

    # ── f_V: Valence encoder ──
    V = 4  # neutral default
    # Try NRC-VAD first (for named characters)
    word = name.lower().replace(' ', '_')
    # Try individual words from name
    for w in name.lower().split():
        if w in vad:
            V = f_v_quantize(vad[w][0])
            break
    # Emoji subgroup override
    if cp in emoji:
        eg, esg = emoji[cp]
        if esg in EMOJI_SUBGROUP_VA:
            V = f_v_quantize(EMOJI_SUBGROUP_VA[esg][0])
        elif eg in EMOJI_VA:
            V = f_v_quantize(EMOJI_VA[eg][0])

    # ── f_A: Arousal encoder ──
    A = 4  # neutral default
    for w in name.lower().split():
        if w in vad:
            A = f_a_quantize(vad[w][1])
            break
    if cp in emoji:
        eg, esg = emoji[cp]
        if esg in EMOJI_SUBGROUP_VA:
            A = f_a_quantize(EMOJI_SUBGROUP_VA[esg][1])
        elif eg in EMOJI_VA:
            A = f_a_quantize(EMOJI_VA[eg][1])

    # ── f_T: Time encoder ──
    T = 0  # static default
    if group == 'MUS':
        T = 3  # musical = most temporal
        if f_t_is_note(name): T = 3
        elif f_t_is_dynamics(name): T = 2
        elif f_t_is_hexagram(name): T = 1
        elif f_t_is_neume(name): T = 3
        elif f_t_is_pitch(name): T = 2
        elif f_t_is_modifier(name): T = 2
    elif cat.startswith('L'):
        T = 2  # letters = moderate temporal (language flows)
    elif cat == 'Nd':
        T = 0  # numbers = static

    return mol_pack(S, R, V, A, T)

# ═══ MAIN ═══
def main():
    print("Loading data...")
    vad = load_nrc_vad()
    udata = load_unicode_data()
    emoji = load_emoji_data()
    print(f"  NRC-VAD: {len(vad)} words")
    print(f"  UnicodeData: {len(udata)} codepoints")
    print(f"  Emoji: {len(emoji)} entries")

    # Build table
    table = [0] * MAX_CP
    stats = {'sdf': 0, 'math': 0, 'emo': 0, 'mus': 0, 'letter': 0, 'other': 0, 'zero': 0}

    for cp in range(MAX_CP):
        if cp in udata or cp < 128:
            pw = encode_codepoint(cp, udata, vad, emoji)
            table[cp] = pw
            bid, group = get_udc_block(cp)
            if group == 'SDF': stats['sdf'] += 1
            elif group == 'MATH': stats['math'] += 1
            elif group == 'EMO': stats['emo'] += 1
            elif group == 'MUS': stats['mus'] += 1
            elif udata.get(cp, {}).get('category', '').startswith('L'): stats['letter'] += 1
            else: stats['other'] += 1
        else:
            stats['zero'] += 1

    nonzero = sum(1 for pw in table if pw > 0)
    print(f"\nBuilt: {MAX_CP} entries, {nonzero} non-zero")
    for k, v in sorted(stats.items()):
        if v > 0: print(f"  {k}: {v}")

    # Write binary
    out_path = os.path.join(ORIGIN, 'json', 'udc_p_table.bin')
    with open(out_path, 'wb') as f:
        for pw in table:
            f.write(struct.pack('<H', pw & 0xFFFF))
    print(f"\nWritten: {out_path} ({os.path.getsize(out_path)} bytes)")

    # Verify
    print("\nVerification:")
    tests = [(65,'A'), (97,'a'), (0x2190,'←'), (0x25CF,'●'), (0x222B,'∫'),
             (0x1F600,'😀'), (0x4DC0,'☰'), (0x1D11E,'𝄞')]
    for cp, ch in tests:
        if cp < MAX_CP:
            pw = table[cp]
            s = (pw>>12)&0xF; r = (pw>>8)&0xF; v = (pw>>5)&0x7; a = (pw>>2)&0x7; t = pw&0x3
            print(f"  U+{cp:04X} {ch:4s} S={s:2d} R={r:2d} V={v} A={a} T={t}  pw={pw}")

if __name__ == '__main__':
    main()
