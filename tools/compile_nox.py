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
OP_STORE      = 0x13  # [name_len:1][name:N] — bare assign (global mutation)
OP_STORE_LOCAL = 0x16 # [name_len:1][name:N] — let statement (local, undo on return)
OP_PUSH_NUM   = 0x15  # [f64:8 LE]
OP_PUSH_MOL   = 0x19  # [5 bytes: S,R,V,A,T]
OP_TRY_BEGIN  = 0x1A  # [catch_offset:4]
OP_CATCH_END  = 0x1B
OP_THROW      = 0x78
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
    COLON = 'COLON'
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
    IMPORT = 'IMPORT'
    FOR = 'FOR'
    IN = 'IN'
    MATCH = 'MATCH'
    ARROW = 'ARROW'     # =>
    TRY = 'TRY'
    CATCH = 'CATCH'
    THROW = 'THROW'
    BREAK = 'BREAK'
    CONTINUE = 'CONTINUE'

KEYWORDS = {
    'let': TK.LET, 'fn': TK.FN, 'if': TK.IF, 'else': TK.ELSE,
    'while': TK.WHILE, 'return': TK.RETURN, 'emit': TK.EMIT,
    'true': TK.TRUE, 'false': TK.FALSE, 'import': TK.IMPORT,
    'for': TK.FOR, 'in': TK.IN, 'match': TK.MATCH,
    'try': TK.TRY, 'catch': TK.CATCH, 'throw': TK.THROW,
    'break': TK.BREAK, 'continue': TK.CONTINUE,
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
                    elif esc == 'r': s += '\r'
                    elif esc == 't': s += '\t'
                    elif esc == '0': s += '\0'
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
        if c == '=' and i+1 < len(source) and source[i+1] == '>':
            tokens.append(Token(TK.ARROW, '=>', line)); i += 2; continue
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
        if c in '+-*/%<>!':
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
        if c == ':':
            tokens.append(Token(TK.COLON, ':', line)); i += 1; continue
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
            line = self.peek().line
            stmt = self.parse_statement()
            if stmt[0] == 'import':
                stmts.append(stmt)  # import handled by resolve_imports, no line wrap
            else:
                stmts.append(('line', line, stmt))
        return ('program', stmts)

    def parse_for(self):
        """for x in arr { body } → desugar to while loop"""
        self.expect(TK.FOR)
        var = self.expect(TK.IDENT).value
        self.expect(TK.IN)
        iterable = self.parse_expr()
        self.expect(TK.LBRACE)
        body = []
        while self.peek().kind != TK.RBRACE:
            body.append(self.parse_statement())
        self.expect(TK.RBRACE)
        # Desugar:
        # let __iter = iterable;
        # let __i = 0;
        # while __i < len(__iter) { let var = __array_get(__iter, __i); body...; let __i = __i + 1; }
        idx = f'__for_i_{id(body)}'
        arr = f'__for_arr_{id(body)}'
        while_body = ([('let', var, ('call', '__array_get', [('var', arr), ('var', idx)]))] +
                      body +
                      [('let', idx, ('binop', '+', ('var', idx), ('num', 1.0)))])
        return ('block', [
            ('let', arr, iterable),
            ('let', idx, ('num', 0.0)),
            ('while',
                ('binop', '<', ('var', idx), ('call', 'len', [('var', arr)])),
                ('block', while_body)
            )
        ])

    def parse_match(self):
        """match x { val => stmt; _ => stmt; } → desugar to if/else chain"""
        self.expect(TK.MATCH)
        expr = self.parse_expr()
        self.expect(TK.LBRACE)
        arms = []
        default = None
        while self.peek().kind != TK.RBRACE:
            if self.peek().kind == TK.IDENT and self.peek().value == '_':
                self.advance()
                self.expect(TK.ARROW)
                body = self.parse_statement()
                default = body
            else:
                pattern = self.parse_expr()
                self.expect(TK.ARROW)
                body = self.parse_statement()
                arms.append((pattern, body))
        self.expect(TK.RBRACE)
        # Desugar to if/else chain
        # let __match_val = expr;
        # if __match_val == arm0.pattern { arm0.body }
        # else { if __match_val == arm1.pattern { arm1.body } else { default } }
        val_name = f'__match_{id(arms)}'
        result = default if default else ('expr_stmt', ('num', 0.0))
        for pattern, body in reversed(arms):
            result = ('if', ('binop', '==', ('var', val_name), pattern),
                      ('block', [body]), ('block', [result]))
        return ('block', [
            ('let', val_name, expr),
            result
        ])

    def parse_try(self):
        """try { body } catch(var) { handler }"""
        self.expect(TK.TRY)
        body = self.parse_block()
        self.expect(TK.CATCH)
        # Optional: catch(e) or just catch
        var = '_err'
        if self.peek().kind == TK.LPAREN:
            self.advance()
            var = self.expect(TK.IDENT).value
            self.expect(TK.RPAREN)
        handler = self.parse_block()
        return ('try', body, var, handler)

    def parse_statement(self):
        t = self.peek()
        if t.kind == TK.FOR:
            result = self.parse_for()
            self.match(TK.SEMI)  # optional trailing ;
            return result
        elif t.kind == TK.MATCH:
            result = self.parse_match()
            self.match(TK.SEMI)  # optional trailing ;
            return result
        elif t.kind == TK.TRY:
            return self.parse_try()
        elif t.kind == TK.THROW:
            self.advance()
            expr = self.parse_expr()
            self.match(TK.SEMI)
            return ('throw', expr)
        elif t.kind == TK.BREAK:
            self.advance()
            self.match(TK.SEMI)
            return ('break',)
        elif t.kind == TK.CONTINUE:
            self.advance()
            self.match(TK.SEMI)
            return ('continue',)
        elif t.kind == TK.IMPORT:
            self.advance()
            path = self.expect(TK.STR).value
            self.match(TK.SEMI)
            return ('import', path)
        elif t.kind == TK.LET:
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
            # Parse expression (might be call, dot access, etc.)
            expr = self.parse_expr()
            # Check for dot/index assignment
            if (expr[0] in ('dot', 'index')) and self.peek().kind == TK.ASSIGN:
                self.advance()  # skip =
                val = self.parse_expr()
                self.match(TK.SEMI)
                if expr[0] == 'dot':
                    _, obj_expr, field = expr
                    return ('dot_set', obj_expr, field, val)
                else:  # index
                    _, arr_expr, idx_expr = expr
                    return ('index_set', arr_expr, idx_expr, val)
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
        if self.peek().kind == TK.OP and self.peek().value == '!':
            self.advance()
            expr = self.parse_primary()
            return ('binop', '==', expr, ('num', 0.0))  # !x → x == 0
        return self.parse_primary()

    def parse_primary(self):
        t = self.peek()
        if t.kind == TK.NUM:
            self.advance()
            result = ('num', t.value)
        elif t.kind == TK.STR:
            self.advance()
            result = ('str', t.value)
        elif t.kind == TK.TRUE:
            self.advance()
            result = ('num', 1.0)
        elif t.kind == TK.FALSE:
            self.advance()
            result = ('num', 0.0)
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
                result = ('call', name, args)
            else:
                result = ('var', name)
        elif t.kind == TK.LPAREN:
            self.advance()
            result = self.parse_expr()
            self.expect(TK.RPAREN)
        elif t.kind == TK.LBRACKET:
            self.advance()
            elems = []
            while self.peek().kind != TK.RBRACKET:
                elems.append(self.parse_expr())
                if not self.match(TK.COMMA):
                    break
            self.expect(TK.RBRACKET)
            result = ('array', elems)
        elif t.kind == TK.LBRACE:
            # Dict literal: {key: val, key2: val2, ...}
            self.advance()
            pairs = []
            while self.peek().kind != TK.RBRACE:
                key = self.expect(TK.IDENT).value
                self.expect(TK.COLON)
                val = self.parse_expr()
                pairs.append((key, val))
                if not self.match(TK.COMMA):
                    break
            self.expect(TK.RBRACE)
            result = ('dict', pairs)
        else:
            raise SyntaxError(f"Unexpected token {t.kind} ({t.value!r}) at line {t.line}")
            return None  # unreachable

        # Postfix: dot access (expr.field) and array index (expr[i])
        while self.peek().kind in (TK.DOT, TK.LBRACKET):
            if self.peek().kind == TK.DOT:
                self.advance()
                field = self.expect(TK.IDENT).value
                result = ('dot', result, field)
            elif self.peek().kind == TK.LBRACKET:
                self.advance()
                index = self.parse_expr()
                self.expect(TK.RBRACKET)
                result = ('index', result, index)
        return result

# ═══ Code Generator ═══

class Codegen:
    def __init__(self):
        self.code = bytearray()
        self.break_targets = []
        self.continue_targets = []
        self.loop_stack = []
        self.enclosing_locals = set()
        self.line_table = []  # [(bytecode_offset, source_line), ...]

    def _collect_lets(self, node):
        """Collect all variable names defined by 'let' in this node (non-recursive into fn)."""
        names = set()
        if not isinstance(node, tuple) or len(node) == 0:
            return names
        kind = node[0]
        if kind == 'let':
            names.add(node[1])
        elif kind == 'fn':
            return names  # don't recurse into nested functions
        elif kind == 'block':
            for stmt in node[1]:
                names |= self._collect_lets(stmt)
        elif kind in ('if',):
            names |= self._collect_lets(node[2])  # then
            if node[3]:
                names |= self._collect_lets(node[3])  # else
        elif kind in ('while',):
            names |= self._collect_lets(node[2])  # body
        elif kind in ('try',):
            names |= self._collect_lets(node[1])  # body
            names.add(node[2])  # catch var
            names |= self._collect_lets(node[3])  # handler
        return names

    def _find_free_vars(self, node, bound):
        """Find variables referenced in node that are not in bound set
        AND not in global scope. Returns list of free variable names."""
        free = set()
        self._walk_free(node, bound, set(), free)
        # Filter out global-scope names (they're accessible without capture)
        return [v for v in free if v in self.enclosing_locals]

    def _walk_free(self, node, bound, defined, free):
        """Walk AST, collect free variables."""
        if not isinstance(node, tuple) or len(node) == 0:
            return
        kind = node[0]
        if kind == 'var':
            name = node[1]
            if name not in bound and name not in defined:
                free.add(name)
        elif kind == 'let':
            _, name, val = node
            self._walk_free(val, bound, defined, free)
            defined.add(name)
        elif kind == 'assign':
            _, name, val = node
            self._walk_free(val, bound, defined, free)
            if name not in bound and name not in defined:
                free.add(name)
        elif kind == 'fn':
            # Nested function: its params are bound, don't recurse into body
            # (nested closures will do their own capture)
            pass
        elif kind in ('call',):
            _, name, args = node
            # Function name MAY need capture if it's a variable (not a builtin)
            if name not in bound and name not in defined and not name.startswith('__'):
                free.add(name)
            for arg in args:
                self._walk_free(arg, bound, defined, free)
        elif kind == 'block':
            for stmt in node[1]:
                self._walk_free(stmt, bound, defined, free)
        elif kind in ('if',):
            _, cond, then, else_ = node
            self._walk_free(cond, bound, defined, free)
            self._walk_free(then, bound, defined, free)
            if else_:
                self._walk_free(else_, bound, defined, free)
        elif kind in ('while',):
            _, cond, body = node
            self._walk_free(cond, bound, defined, free)
            self._walk_free(body, bound, defined, free)
        elif kind in ('return', 'emit', 'throw', 'expr_stmt'):
            self._walk_free(node[1], bound, defined, free)
        elif kind in ('binop',):
            self._walk_free(node[2], bound, defined, free)
            self._walk_free(node[3], bound, defined, free)
        elif kind in ('dot',):
            self._walk_free(node[1], bound, defined, free)
        elif kind in ('index',):
            self._walk_free(node[1], bound, defined, free)
            self._walk_free(node[2], bound, defined, free)
        elif kind in ('dot_set',):
            self._walk_free(node[1], bound, defined, free)
            self._walk_free(node[3], bound, defined, free)
        elif kind in ('index_set',):
            self._walk_free(node[1], bound, defined, free)
            self._walk_free(node[2], bound, defined, free)
            self._walk_free(node[3], bound, defined, free)
        elif kind in ('dict',):
            for _, val in node[1]:
                self._walk_free(val, bound, defined, free)
        elif kind in ('array',):
            for elem in node[1]:
                self._walk_free(elem, bound, defined, free)
        elif kind in ('try',):
            _, body, var, handler = node
            self._walk_free(body, bound, defined, free)
            defined.add(var)
            self._walk_free(handler, bound, defined, free)
        elif kind in ('for',):
            # for is desugared, shouldn't appear here
            pass
        elif kind in ('and', 'or'):
            self._walk_free(node[1], bound, defined, free)
            self._walk_free(node[2], bound, defined, free)

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

        elif kind == 'line':
            _, line_no, inner = node
            self.line_table.append((self.current_offset(), line_no))
            self.compile_node(inner)

        elif kind == 'block':
            for stmt in node[1]:
                self.compile_node(stmt)

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
            self.emit_byte(OP_STORE_LOCAL)
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
            # Free variable analysis: capture vars from enclosing function scope
            old_enclosing = self.enclosing_locals
            # Collect ALL locals in this function (params + let-defined vars)
            fn_locals = set(params) | self._collect_lets(body)
            self.enclosing_locals = old_enclosing | fn_locals
            captures = self._find_free_vars(body, set(params))

            if captures:
                # Emit ClosureCapture with captures
                self.emit_byte(OP_CLOSURE_CAP)
                self.emit_byte(len(params))
                self.emit_byte(len(captures))
                for cap in captures:
                    self.emit_name(cap)
            else:
                # No captures: simple closure
                self.emit_byte(OP_CLOSURE)
                self.emit_byte(len(params))
            # Placeholder for body length
            body_len_offset = self.current_offset()
            self.emit_u32(0)  # will be patched
            body_start = self.current_offset()
            # Store parameters from stack into variables (reverse order)
            for p in reversed(params):
                self.emit_byte(OP_STORE_LOCAL)
                self.emit_name(p)
            # Compile body
            self.compile_node(body)
            # Add trailing Ret only if body doesn't end with one
            if not self.code or self.code[-1] != OP_RET:
                self.emit_byte(OP_RET)
            body_end = self.current_offset()
            # Patch body length
            self.patch_i32(body_len_offset, body_end - body_start)
            # Restore enclosing locals
            self.enclosing_locals = old_enclosing
            # Store closure as named variable (fn name is like let)
            self.emit_byte(OP_STORE_LOCAL)
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
            # Save outer break/continue targets
            outer_breaks = self.break_targets
            outer_continues = self.continue_targets
            self.break_targets = []
            self.continue_targets = []
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
            loop_end = self.current_offset()
            # Patch Jz to here
            self.patch_i32(jz_offset, loop_end - jz_target)
            # Patch break targets to loop_end
            for boff in self.break_targets:
                self.patch_i32(boff, loop_end - (boff + 4))
            # Patch continue targets to loop_start
            for coff in self.continue_targets:
                self.patch_i32(coff, loop_start - (coff + 4))
            # Restore outer targets
            self.break_targets = outer_breaks
            self.continue_targets = outer_continues

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

        elif kind == 'dict':
            # Dict literal: {key: val, ...}
            # Compile as: __dict_new() then __dict_set for each pair
            pairs = node[1]
            self.emit_byte(OP_CALL)
            self.emit_name('__dict_new')
            self.emit_byte(0)  # 0 args
            for key, val in pairs:
                # Stack: [dict]. Push key string, then value, then call __dict_set
                self.emit_string(key)
                self.compile_node(val)
                self.emit_byte(OP_CALL)
                self.emit_name('__dict_set')
                self.emit_byte(3)  # (dict, key, val)

        elif kind == 'dot':
            # expr.field → __dict_get(expr, "field")
            _, expr, field = node
            self.compile_node(expr)
            self.emit_string(field)
            self.emit_byte(OP_CALL)
            self.emit_name('__dict_get')
            self.emit_byte(2)  # (dict, key)

        elif kind == 'dot_set':
            # expr.field = val → __dict_set(expr, "field", val)
            _, expr, field, val = node
            self.compile_node(expr)
            self.emit_string(field)
            self.compile_node(val)
            self.emit_byte(OP_CALL)
            self.emit_name('__dict_set')
            self.emit_byte(3)  # (dict, key, val)
            self.emit_byte(OP_POP)  # discard returned dict

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

        elif kind == 'try':
            # try { body } catch(var) { handler }
            _, body, var, handler = node
            # Emit TRY_BEGIN with offset to catch
            self.emit_byte(OP_TRY_BEGIN)
            try_off = self.current_offset()
            self.emit_i32(0)  # placeholder: offset to catch
            try_target = self.current_offset()
            # Body
            self.compile_node(body)
            # End of try: emit CATCH_END to pop try frame
            self.emit_byte(OP_CATCH_END)
            # Jump past catch block
            self.emit_byte(OP_JMP)
            jmp_off = self.current_offset()
            self.emit_i32(0)
            jmp_target = self.current_offset()
            # Catch: patch TRY_BEGIN with ABSOLUTE bytecode offset to catch handler
            self.patch_i32(try_off, self.current_offset())
            # The error value is on stack (VM pushes it on throw? Actually VM just restores stack)
            # For now, catch var = 0 (placeholder)
            self.emit_byte(OP_PUSH_NUM)
            self.emit_f64(0.0)
            self.emit_byte(OP_STORE_LOCAL)
            self.emit_name(var)
            # Handler body
            self.compile_node(handler)
            # Patch jump past catch
            self.patch_i32(jmp_off, self.current_offset() - jmp_target)

        elif kind == 'throw':
            self.compile_node(node[1])
            self.emit_byte(OP_THROW)

        elif kind == 'break':
            # Emit JMP placeholder — patched by enclosing while/for loop
            self.emit_byte(OP_JMP)
            off = self.current_offset()
            self.emit_i32(0)
            self.break_targets.append(off)

        elif kind == 'continue':
            # Emit LOOP (backward jump) to loop start
            self.emit_byte(OP_LOOP)
            off = self.current_offset()
            self.emit_i32(0)
            self.continue_targets.append(off)

        elif kind == 'index':
            # arr[i] → __array_get(arr, i)
            _, arr_expr, idx_expr = node
            self.compile_node(arr_expr)
            self.compile_node(idx_expr)
            self.emit_byte(OP_CALL)
            self.emit_name('__array_get')
            self.emit_byte(2)

        elif kind == 'index_set':
            # arr[i] = v → __set_at(arr, i, v)
            _, arr_expr, idx_expr, val_expr = node
            self.compile_node(arr_expr)
            self.compile_node(idx_expr)
            self.compile_node(val_expr)
            self.emit_byte(OP_CALL)
            self.emit_name('__set_at')
            self.emit_byte(3)
            self.emit_byte(OP_POP)

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

def resolve_imports(ast, base_dir, imported=None):
    """Expand import statements by inlining imported file ASTs. Dedup by path."""
    if imported is None:
        imported = set()
    if ast[0] != 'program':
        return ast
    new_stmts = []
    for stmt in ast[1]:
        if stmt[0] == 'import':
            path = stmt[1]
            # Resolve relative to base_dir
            full_path = os.path.normpath(os.path.join(base_dir, path))
            if full_path in imported:
                continue  # dedup: already imported
            imported.add(full_path)
            if not os.path.exists(full_path):
                print(f"Warning: import '{path}' not found at {full_path}")
                continue
            with open(full_path, 'r') as f:
                imp_source = f.read()
            imp_tokens = lex(imp_source)
            imp_parser = Parser(imp_tokens)
            imp_ast = imp_parser.parse_program()
            # Recursively resolve imports in the imported file
            imp_dir = os.path.dirname(full_path)
            imp_ast = resolve_imports(imp_ast, imp_dir, imported)
            # Inline all statements (skip the 'program' wrapper)
            new_stmts.extend(imp_ast[1][:-1] if imp_ast[1] and imp_ast[1][-1] == ('halt',) else imp_ast[1])
        else:
            new_stmts.append(stmt)
    return ('program', new_stmts)

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

    # Resolve imports (inline imported files, dedup)
    base_dir = os.path.dirname(os.path.abspath(source_path))
    ast = resolve_imports(ast, base_dir)

    # Codegen
    codegen = Codegen()
    codegen.compile_node(ast)

    # Append line table after bytecode (after HALT — VM ignores it)
    # Format: [code_size:4][MAGIC "LN":2][count:4][(offset:4, line:4)×N]
    code_size = len(codegen.code)
    line_section = bytearray()
    line_section += struct.pack('<I', 0xDEAD4C4E)  # magic
    line_section += struct.pack('<I', len(codegen.line_table))
    for bc_off, src_line in codegen.line_table:
        line_section += struct.pack('<II', bc_off, src_line)

    bytecode = bytes(codegen.code) + bytes(line_section)

    # Build binary
    total_size = build_olng(bytecode, vm_path, output_path)

    print(f"Compiled: {source_path}")
    print(f"  Bytecode: {len(codegen.code)} bytes (+{len(line_section)} line table)")
    print(f"  Output: {output_path} ({total_size} bytes)")

if __name__ == '__main__':
    main()
