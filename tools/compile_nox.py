#!/usr/bin/env python3
"""
Nox Bootstrap Compiler — Python → OLNG bytecode for VM v2
Compiles .ol source files to bytecode, appends to VM binary.

Usage:
  python3 tools/compile_nox.py source.ol [output_binary]

If output_binary not specified, creates source.olang
"""

import sys
import struct
import os

# ═══ Opcodes (matching vm_nox.S dispatch table) ═══

OP_NOP        = 0x00
OP_PUSH       = 0x01  # [len:2 LE][data:N]
OP_LOAD       = 0x02  # [name_len:1][name:N]
OP_EMIT       = 0x06
OP_CALL       = 0x07  # [name_len:1][name:N][argc:1]
OP_RET        = 0x08
OP_JMP        = 0x09  # [offset:4 LE signed]
OP_JZ         = 0x0A  # [offset:4 LE signed]
OP_DUP        = 0x0B
OP_POP        = 0x0C
OP_SWAP       = 0x0D
OP_LOOP       = 0x0E  # [offset:4 LE signed]
OP_HALT       = 0x0F
OP_STORE      = 0x13  # [name_len:1][name:N]
OP_PUSH_NUM   = 0x15  # [f64:8 LE]
OP_PUSH_MOL   = 0x19  # [5 bytes: S,R,V,A,T]
OP_TRY_BEGIN  = 0x1A  # [catch_offset:4]
OP_CATCH_END  = 0x1B
OP_LOAD_REG   = 0x26  # [slot:1]
OP_STORE_REG  = 0x27  # [slot:1]
OP_ENTER_FRAME = 0x28 # [count:1]
OP_LEAVE_FRAME = 0x29
OP_ADD        = 0x2A
OP_SUB        = 0x2B
OP_MUL        = 0x2C
OP_DIV        = 0x2D
OP_MOD        = 0x2E
OP_CLOSURE    = 0x25  # [params:1][body_len:4][body:N]
OP_CLOSURE_CAP = 0x30 # [params:1][caps:1][names...][body_len:4][body:N]
OP_EQ         = 0x31
OP_NE         = 0x32
OP_LT         = 0x33
OP_GT         = 0x34
OP_LE         = 0x35
OP_GE         = 0x36
OP_CALL_CLOSURE = 0x24 # [argc:1]

# ═══ Token types ═══

class TK:
    NUM = 'NUM'
    STR = 'STR'
    IDENT = 'IDENT'
    OP = 'OP'
    SEMI = 'SEMI'
    LPAREN = 'LPAREN'
    RPAREN = 'RPAREN'
    LBRACE = 'LBRACE'
    RBRACE = 'RBRACE'
    LBRACKET = 'LBRACKET'
    RBRACKET = 'RBRACKET'
    COMMA = 'COMMA'
    DOT = 'DOT'
    ASSIGN = 'ASSIGN'
    EOF = 'EOF'
    # Keywords
    LET = 'LET'
    FN = 'FN'
    IF = 'IF'
    ELSE = 'ELSE'
    WHILE = 'WHILE'
    RETURN = 'RETURN'
    EMIT = 'EMIT'
    TRUE = 'TRUE'
    FALSE = 'FALSE'

KEYWORDS = {
    'let': TK.LET, 'fn': TK.FN, 'if': TK.IF, 'else': TK.ELSE,
    'while': TK.WHILE, 'return': TK.RETURN, 'emit': TK.EMIT,
    'true': TK.TRUE, 'false': TK.FALSE,
}

# ═══ Lexer ═══

class Token:
    def __init__(self, kind, value, line=0):
        self.kind = kind
        self.value = value
        self.line = line
    def __repr__(self):
        return f"Token({self.kind}, {self.value!r})"

def lex(source):
    tokens = []
    i = 0
    line = 1
    while i < len(source):
        c = source[i]
        # Skip whitespace
        if c in ' \t\r':
            i += 1
            continue
        if c == '\n':
            line += 1
            i += 1
            continue
        # Comments
        if c == '#' or (c == '/' and i+1 < len(source) and source[i+1] == '/'):
            while i < len(source) and source[i] != '\n':
                i += 1
            continue
        # Block comments
        if c == '/' and i+1 < len(source) and source[i+1] == '*':
            i += 2
            while i+1 < len(source) and not (source[i] == '*' and source[i+1] == '/'):
                if source[i] == '\n': line += 1
                i += 1
            i += 2
            continue
        # Numbers (decimal or 0x hex)
        if c.isdigit() or (c == '-' and i+1 < len(source) and source[i+1].isdigit()):
            start = i
            if c == '-': i += 1
            if i+1 < len(source) and source[i] == '0' and source[i+1] in 'xX':
                i += 2  # skip 0x
                while i < len(source) and source[i] in '0123456789abcdefABCDEF':
                    i += 1
                tokens.append(Token(TK.NUM, float(int(source[start:i], 16)), line))
            else:
                while i < len(source) and (source[i].isdigit() or source[i] == '.'):
                    i += 1
                tokens.append(Token(TK.NUM, float(source[start:i]), line))
            continue
        # Strings
        if c == '"':
            i += 1
            s = ""
            while i < len(source) and source[i] != '"':
                if source[i] == '\\' and i+1 < len(source):
                    i += 1
                    esc = source[i]
                    if esc == 'n': s += '\n'
                    elif esc == 't': s += '\t'
                    elif esc == '\\': s += '\\'
                    elif esc == '"': s += '"'
                    else: s += esc
                else:
                    s += source[i]
                i += 1
            i += 1  # skip closing "
            tokens.append(Token(TK.STR, s, line))
            continue
        # Identifiers / keywords
        if c.isalpha() or c == '_':
            start = i
            while i < len(source) and (source[i].isalnum() or source[i] == '_'):
                i += 1
            word = source[start:i]
            kind = KEYWORDS.get(word, TK.IDENT)
            tokens.append(Token(kind, word, line))
            continue
        # Operators
        if c == '=' and i+1 < len(source) and source[i+1] == '=':
            tokens.append(Token(TK.OP, '==', line)); i += 2; continue
        if c == '!' and i+1 < len(source) and source[i+1] == '=':
            tokens.append(Token(TK.OP, '!=', line)); i += 2; continue
        if c == '<' and i+1 < len(source) and source[i+1] == '=':
            tokens.append(Token(TK.OP, '<=', line)); i += 2; continue
        if c == '>' and i+1 < len(source) and source[i+1] == '=':
            tokens.append(Token(TK.OP, '>=', line)); i += 2; continue
        if c == '&' and i+1 < len(source) and source[i+1] == '&':
            tokens.append(Token(TK.OP, '&&', line)); i += 2; continue
        if c == '|' and i+1 < len(source) and source[i+1] == '|':
            tokens.append(Token(TK.OP, '||', line)); i += 2; continue
        if c in '+-*/%<>':
            tokens.append(Token(TK.OP, c, line)); i += 1; continue
        if c == '=':
            tokens.append(Token(TK.ASSIGN, '=', line)); i += 1; continue
        if c == ';':
            tokens.append(Token(TK.SEMI, ';', line)); i += 1; continue
        if c == '(':
            tokens.append(Token(TK.LPAREN, '(', line)); i += 1; continue
        if c == ')':
            tokens.append(Token(TK.RPAREN, ')', line)); i += 1; continue
        if c == '{':
            tokens.append(Token(TK.LBRACE, '{', line)); i += 1; continue
        if c == '}':
            tokens.append(Token(TK.RBRACE, '}', line)); i += 1; continue
        if c == '[':
            tokens.append(Token(TK.LBRACKET, '[', line)); i += 1; continue
        if c == ']':
            tokens.append(Token(TK.RBRACKET, ']', line)); i += 1; continue
        if c == ',':
            tokens.append(Token(TK.COMMA, ',', line)); i += 1; continue
        if c == '.':
            tokens.append(Token(TK.DOT, '.', line)); i += 1; continue
        # Unknown char — skip
        i += 1
    tokens.append(Token(TK.EOF, None, line))
    return tokens

# ═══ Parser ═══

class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.pos = 0

    def peek(self):
        return self.tokens[self.pos]

    def advance(self):
        t = self.tokens[self.pos]
        self.pos += 1
        return t

    def expect(self, kind):
        t = self.advance()
        if t.kind != kind:
            raise SyntaxError(f"Expected {kind}, got {t.kind} ({t.value!r}) at line {t.line}")
        return t

    def match(self, kind):
        if self.peek().kind == kind:
            return self.advance()
        return None

    def parse_program(self):
        stmts = []
        while self.peek().kind != TK.EOF:
            stmts.append(self.parse_statement())
        return ('program', stmts)

    def parse_statement(self):
        t = self.peek()
        if t.kind == TK.LET:
            return self.parse_let()
        elif t.kind == TK.FN:
            return self.parse_fn()
        elif t.kind == TK.IF:
            return self.parse_if()
        elif t.kind == TK.WHILE:
            return self.parse_while()
        elif t.kind == TK.RETURN:
            return self.parse_return()
        elif t.kind == TK.EMIT:
            return self.parse_emit()
        elif t.kind == TK.IDENT:
            # Check for assignment: ident = expr;
            if self.pos + 1 < len(self.tokens) and self.tokens[self.pos + 1].kind == TK.ASSIGN:
                name = self.advance().value
                self.advance()  # skip =
                value = self.parse_expr()
                self.match(TK.SEMI)
                return ('assign', name, value)
            # Otherwise expression statement
            expr = self.parse_expr()
            self.match(TK.SEMI)
            return ('expr_stmt', expr)
        else:
            expr = self.parse_expr()
            self.match(TK.SEMI)
            return ('expr_stmt', expr)

    def parse_let(self):
        self.expect(TK.LET)
        name = self.expect(TK.IDENT).value
        self.expect(TK.ASSIGN)
        value = self.parse_expr()
        self.match(TK.SEMI)
        return ('let', name, value)

    def parse_fn(self):
        self.expect(TK.FN)
        name = self.expect(TK.IDENT).value
        self.expect(TK.LPAREN)
        params = []
        while self.peek().kind != TK.RPAREN:
            params.append(self.expect(TK.IDENT).value)
            if not self.match(TK.COMMA):
                break
        self.expect(TK.RPAREN)
        body = self.parse_block()
        return ('fn', name, params, body)

    def parse_if(self):
        self.expect(TK.IF)
        cond = self.parse_expr()
        then = self.parse_block()
        else_ = None
        if self.match(TK.ELSE):
            if self.peek().kind == TK.IF:
                else_ = self.parse_if()
            else:
                else_ = self.parse_block()
        return ('if', cond, then, else_)

    def parse_while(self):
        self.expect(TK.WHILE)
        cond = self.parse_expr()
        body = self.parse_block()
        return ('while', cond, body)

    def parse_return(self):
        self.expect(TK.RETURN)
        if self.peek().kind == TK.SEMI or self.peek().kind == TK.RBRACE:
            self.match(TK.SEMI)
            return ('return', ('num', 0.0))
        expr = self.parse_expr()
        self.match(TK.SEMI)
        return ('return', expr)

    def parse_emit(self):
        self.expect(TK.EMIT)
        expr = self.parse_expr()
        self.match(TK.SEMI)
        return ('emit', expr)

    def parse_block(self):
        self.expect(TK.LBRACE)
        stmts = []
        while self.peek().kind != TK.RBRACE:
            stmts.append(self.parse_statement())
        self.expect(TK.RBRACE)
        self.match(TK.SEMI)  # optional ; after }
        return ('block', stmts)

    def parse_expr(self):
        return self.parse_or()

    def parse_or(self):
        left = self.parse_and()
        while self.peek().kind == TK.OP and self.peek().value == '||':
            self.advance()
            right = self.parse_and()
            left = ('or', left, right)
        return left

    def parse_and(self):
        left = self.parse_comparison()
        while self.peek().kind == TK.OP and self.peek().value == '&&':
            self.advance()
            right = self.parse_comparison()
            left = ('and', left, right)
        return left

    def parse_comparison(self):
        left = self.parse_addition()
        while self.peek().kind == TK.OP and self.peek().value in ('==', '!=', '<', '>', '<=', '>='):
            op = self.advance().value
            right = self.parse_addition()
            left = ('binop', op, left, right)
        return left

    def parse_addition(self):
        left = self.parse_multiplication()
        while self.peek().kind == TK.OP and self.peek().value in ('+', '-'):
            op = self.advance().value
            right = self.parse_multiplication()
            left = ('binop', op, left, right)
        return left

    def parse_multiplication(self):
        left = self.parse_unary()
        while self.peek().kind == TK.OP and self.peek().value in ('*', '/', '%'):
            op = self.advance().value
            right = self.parse_unary()
            left = ('binop', op, left, right)
        return left

    def parse_unary(self):
        if self.peek().kind == TK.OP and self.peek().value == '-':
            self.advance()
            expr = self.parse_primary()
            return ('binop', '-', ('num', 0.0), expr)
        return self.parse_primary()

    def parse_primary(self):
        t = self.peek()
        if t.kind == TK.NUM:
            self.advance()
            return ('num', t.value)
        elif t.kind == TK.STR:
            self.advance()
            return ('str', t.value)
        elif t.kind == TK.TRUE:
            self.advance()
            return ('num', 1.0)
        elif t.kind == TK.FALSE:
            self.advance()
            return ('num', 0.0)
        elif t.kind == TK.IDENT:
            name = self.advance().value
            # Function call?
            if self.peek().kind == TK.LPAREN:
                self.advance()
                args = []
                while self.peek().kind != TK.RPAREN:
                    args.append(self.parse_expr())
                    if not self.match(TK.COMMA):
                        break
                self.expect(TK.RPAREN)
                return ('call', name, args)
            return ('var', name)
        elif t.kind == TK.LPAREN:
            self.advance()
            expr = self.parse_expr()
            self.expect(TK.RPAREN)
            return expr
        elif t.kind == TK.LBRACKET:
            self.advance()
            elems = []
            while self.peek().kind != TK.RBRACKET:
                elems.append(self.parse_expr())
                if not self.match(TK.COMMA):
                    break
            self.expect(TK.RBRACKET)
            return ('array', elems)
        else:
            raise SyntaxError(f"Unexpected token {t.kind} ({t.value!r}) at line {t.line}")

# ═══ Code Generator ═══

class Codegen:
    def __init__(self):
        self.code = bytearray()

    def emit_byte(self, b):
        self.code.append(b & 0xFF)

    def emit_u16(self, v):
        self.code.extend(struct.pack('<H', v & 0xFFFF))

    def emit_u32(self, v):
        self.code.extend(struct.pack('<I', v & 0xFFFFFFFF))

    def emit_i32(self, v):
        self.code.extend(struct.pack('<i', v))

    def emit_f64(self, v):
        self.code.extend(struct.pack('<d', v))

    def emit_name(self, name):
        """Emit [len:1][name_bytes:N] — name as ASCII bytes (for Call dispatch)"""
        name_bytes = name.encode('ascii', errors='replace')
        self.emit_byte(len(name_bytes))
        self.code.extend(name_bytes)

    def emit_var_hash(self, name):
        """Emit 4-byte truncated hash of variable name (for Load/Store)"""
        h = 0xcbf29ce484222325
        for c in name.encode('ascii', errors='replace'):
            h ^= c
            h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
        # Emit lower 32 bits — VM reads 4 bytes via mov eax, [r12+r13]
        self.emit_u32(h & 0xFFFFFFFF)

    def emit_string(self, s):
        """Emit Push opcode with string as u16 molecule chain"""
        # Each character → 1 u16 molecule (codepoint)
        mols = [ord(c) for c in s]
        byte_len = len(mols) * 2
        self.emit_byte(OP_PUSH)
        self.emit_u16(byte_len)
        for mol in mols:
            self.emit_u16(mol)

    def current_offset(self):
        return len(self.code)

    def patch_i32(self, offset, value):
        """Patch a 4-byte signed integer at given offset"""
        packed = struct.pack('<i', value)
        self.code[offset:offset+4] = packed

    def compile_node(self, node):
        kind = node[0]

        if kind == 'program':
            for stmt in node[1]:
                self.compile_node(stmt)
            self.emit_byte(OP_HALT)

        elif kind == 'num':
            self.emit_byte(OP_PUSH_NUM)
            self.emit_f64(node[1])

        elif kind == 'str':
            self.emit_string(node[1])

        elif kind == 'var':
            self.emit_byte(OP_LOAD)
            self.emit_name(node[1])

        elif kind == 'let':
            _, name, value = node
            self.compile_node(value)
            self.emit_byte(OP_STORE)
            self.emit_name(name)

        elif kind == 'assign':
            _, name, value = node
            self.compile_node(value)
            self.emit_byte(OP_STORE)
            self.emit_name(name)

        elif kind == 'emit':
            self.compile_node(node[1])
            self.emit_byte(OP_EMIT)

        elif kind == 'expr_stmt':
            self.compile_node(node[1])
            self.emit_byte(OP_POP)

        elif kind == 'binop':
            _, op, left, right = node
            self.compile_node(left)
            self.compile_node(right)
            op_map = {
                '+': OP_ADD, '-': OP_SUB, '*': OP_MUL,
                '/': OP_DIV, '%': OP_MOD,
                '==': OP_EQ, '!=': OP_NE,
                '<': OP_LT, '>': OP_GT,
                '<=': OP_LE, '>=': OP_GE,
            }
            self.emit_byte(op_map[op])

        elif kind == 'call':
            _, name, args = node
            # Push args left-to-right
            for arg in args:
                self.compile_node(arg)
            # Emit Call
            self.emit_byte(OP_CALL)
            self.emit_name(name)
            self.emit_byte(len(args))

        elif kind == 'fn':
            _, name, params, body = node
            # Emit Closure
            self.emit_byte(OP_CLOSURE)
            self.emit_byte(len(params))
            # Placeholder for body length
            body_len_offset = self.current_offset()
            self.emit_u32(0)  # will be patched
            body_start = self.current_offset()
            # Store parameters from stack into variables (reverse order)
            # Args are pushed left-to-right, so topmost = last param
            for p in reversed(params):
                self.emit_byte(OP_STORE)
                self.emit_name(p)
            # Compile body
            self.compile_node(body)
            # Add trailing Ret only if body doesn't end with one
            if not self.code or self.code[-1] != OP_RET:
                self.emit_byte(OP_RET)
            body_end = self.current_offset()
            # Patch body length
            self.patch_i32(body_len_offset, body_end - body_start)
            # Store closure as named variable
            self.emit_byte(OP_STORE)
            self.emit_name(name)

        elif kind == 'block':
            for stmt in node[1]:
                self.compile_node(stmt)

        elif kind == 'if':
            _, cond, then, else_ = node
            self.compile_node(cond)
            # Jz to else
            self.emit_byte(OP_JZ)
            jz_offset = self.current_offset()
            self.emit_i32(0)  # placeholder
            jz_target = self.current_offset()
            # Then block
            self.compile_node(then)
            if else_:
                # Jmp past else
                self.emit_byte(OP_JMP)
                jmp_offset = self.current_offset()
                self.emit_i32(0)  # placeholder
                jmp_target = self.current_offset()
                # Patch Jz to here
                self.patch_i32(jz_offset, self.current_offset() - jz_target)
                # Else block
                self.compile_node(else_)
                # Patch Jmp to here
                self.patch_i32(jmp_offset, self.current_offset() - jmp_target)
            else:
                # Patch Jz to here
                self.patch_i32(jz_offset, self.current_offset() - jz_target)

        elif kind == 'while':
            _, cond, body = node
            loop_start = self.current_offset()
            self.compile_node(cond)
            # Jz to end
            self.emit_byte(OP_JZ)
            jz_offset = self.current_offset()
            self.emit_i32(0)
            jz_target = self.current_offset()
            # Body
            self.compile_node(body)
            # Loop back
            self.emit_byte(OP_LOOP)
            loop_delta = loop_start - (self.current_offset() + 4)
            self.emit_i32(loop_delta)
            # Patch Jz to here
            self.patch_i32(jz_offset, self.current_offset() - jz_target)

        elif kind == 'return':
            self.compile_node(node[1])
            self.emit_byte(OP_RET)

        elif kind == 'array':
            elems = node[1]
            if len(elems) == 0:
                # Empty array: __array_with_cap(16)
                self.emit_byte(OP_PUSH_NUM)
                self.emit_f64(16.0)
                self.emit_byte(OP_CALL)
                self.emit_name('__array_with_cap')
                self.emit_byte(1)
            else:
                # Non-empty: push elements then call __array_new
                for elem in elems:
                    self.compile_node(elem)
                self.emit_byte(OP_PUSH_NUM)
                self.emit_f64(float(len(elems)))
                self.emit_byte(OP_CALL)
                self.emit_name('__array_new')
                self.emit_byte(len(elems) + 1)

        elif kind == 'and':
            # Short-circuit: if left is false, skip right
            self.compile_node(node[1])
            self.emit_byte(OP_DUP)
            self.emit_byte(OP_JZ)
            jz_off = self.current_offset()
            self.emit_i32(0)
            jz_target = self.current_offset()
            self.emit_byte(OP_POP)
            self.compile_node(node[2])
            self.patch_i32(jz_off, self.current_offset() - jz_target)

        elif kind == 'or':
            # Short-circuit: if left is true, skip right
            self.compile_node(node[1])
            self.emit_byte(OP_DUP)
            # If truthy, skip right
            self.emit_byte(OP_JZ)
            jz_off = self.current_offset()
            self.emit_i32(0)
            jz_target = self.current_offset()
            # Left was truthy — skip right
            self.emit_byte(OP_JMP)
            jmp_off = self.current_offset()
            self.emit_i32(0)
            jmp_target = self.current_offset()
            # Left was falsy — evaluate right
            self.patch_i32(jz_off, self.current_offset() - jz_target)
            self.emit_byte(OP_POP)
            self.compile_node(node[2])
            self.patch_i32(jmp_off, self.current_offset() - jmp_target)

        else:
            raise ValueError(f"Unknown AST node: {kind}")

# ═══ Binary Builder ═══

def build_olng(bytecode, vm_path, output_path):
    """Create OLNG binary: VM binary + bc_size + bytecode + trailer"""
    # Read VM binary
    with open(vm_path, 'rb') as f:
        vm_data = f.read()

    vm_size = len(vm_data)
    bc_size = len(bytecode)

    # VM v2 boot sequence reads:
    #   1. Seek -8 from EOF → read 8 bytes = header_offset
    #   2. Seek to header_offset → read 4 bytes = bc_size
    #   3. Read bc_size bytes of bytecode
    #
    # Layout: [VM binary][bc_size:4 LE][bytecode:N][trailer:8 LE = offset of bc_size]

    bc_size_offset = vm_size
    bc_size_bytes = struct.pack('<I', bc_size)
    trailer = struct.pack('<Q', bc_size_offset)

    with open(output_path, 'wb') as f:
        f.write(vm_data)           # VM binary (ELF)
        f.write(bc_size_bytes)     # 4-byte bytecode size
        f.write(bytecode)          # Compiled bytecode
        f.write(trailer)           # 8-byte offset to bc_size

    os.chmod(output_path, 0o755)
    return vm_size + 4 + bc_size + 8

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 compile_nox.py source.ol [output]")
        sys.exit(1)

    source_path = sys.argv[1]
    vm_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'vm', 'x86_64', 'vm_nox')

    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = source_path.replace('.ol', '.olang')

    # Read source
    with open(source_path, 'r') as f:
        source = f.read()

    # Lex
    tokens = lex(source)

    # Parse
    parser = Parser(tokens)
    ast = parser.parse_program()

    # Codegen
    codegen = Codegen()
    codegen.compile_node(ast)
    bytecode = bytes(codegen.code)

    # Build binary
    total_size = build_olng(bytecode, vm_path, output_path)

    print(f"Compiled: {source_path}")
    print(f"  Bytecode: {len(bytecode)} bytes")
    print(f"  Output: {output_path} ({total_size} bytes)")

if __name__ == '__main__':
    main()
