# MATCH BYPASS — Systematic conversion to if/__match_enum

> Nox: match codegen broken in self-hosted compiler ("match-inception").
> Fix root cause = complex. Bypass ALL match = mechanical, guaranteed.
> Nox đã bypass token check functions → works. Scale cái này lên.

---

## PATTERN (Nox đã biết)

```olang
// TRƯỚC (match — broken in self-compiled):
match tok.kind {
    TokenKind::Keyword { name } => { do_something(name); },
    TokenKind::Ident { name } => { do_other(name); },
    TokenKind::Number { value } => { use(value); },
    _ => { default_action(); },
}

// SAU (if/__match_enum — works everywhere):
if __match_enum(tok.kind, "TokenKind::Keyword") == 1 {
    let name = __enum_field(tok.kind, 0);
    do_something(name);
} else { if __match_enum(tok.kind, "TokenKind::Ident") == 1 {
    let name = __enum_field(tok.kind, 0);
    do_other(name);
} else { if __match_enum(tok.kind, "TokenKind::Number") == 1 {
    let value = __enum_field(tok.kind, 0);
    use(value);
} else {
    default_action();
}; }; };
```

**Field extraction:**
- 1 field: `__enum_field(val, 0)` → first field
- 2 fields: `__enum_field(val, 0)` + `__enum_field(val, 1)` → first + second
- No fields (bare variant): just `__match_enum(val, "Tag") == 1`

---

## PARSER.OL — 26 match blocks

### Priority: HIGH (parser must work for eval)

**Token kinds used in parser.ol:**
```
TokenKind::Keyword { name }    → __enum_field(tok.kind, 0)
TokenKind::Ident { name }      → __enum_field(tok.kind, 0)
TokenKind::Number { value }    → __enum_field(tok.kind, 0)
TokenKind::StringLit { value } → __enum_field(tok.kind, 0)
TokenKind::Symbol { ch }       → __enum_field(tok.kind, 0)
TokenKind::Eof                 → no fields
```

**Expr kinds used in parser.ol:**
```
Expr::Ident { name }           → __enum_field(expr, 0)
Expr::CallExpr { callee, args }→ __enum_field(expr, 0), __enum_field(expr, 1)
```

### Conversion order:
1. `is_ident_tok` (dòng ~197) — simple, 1 arm
2. `parse_primary` matches (dòng ~229, ~290) — big, nhiều arms
3. `is_binop` (dòng ~685) — medium
4. `parse_expr_prec` (dòng ~707) — medium
5. `parse_match_arms` (dòng ~779) — medium
6. `parse_stmt` matches (dòng ~1140, ~1162, ~1219, ~1223) — medium
7. Other small matches

---

## SEMANTIC.OL — 18 match blocks

### Priority: HIGH (compiler must work for eval)

**Main match blocks:**
```
compile_stmts: match stmt { Stmt::LetStmt => ..., Stmt::FnDef => ..., ... }
compile_expr:  match expr { Expr::NumLit => ..., Expr::StrLit => ..., ... }
```

**Stmt kinds:**
```
Stmt::LetStmt { name, value }
Stmt::FnDef { name, params, body }
Stmt::IfStmt { condition, then, else }
Stmt::WhileStmt { condition, body }
Stmt::ForStmt { var, iter, body }
Stmt::EmitStmt { expr }
Stmt::ReturnStmt { value }
Stmt::ExprStmt { expr }
Stmt::AssignStmt { name, value }
Stmt::FieldAssign { object, field, value }
Stmt::MatchStmt { subject, arms }
Stmt::TryStmt { body, catch }
Stmt::PubStmt { stmt }
Stmt::ConstStmt { name, value }
```

**Expr kinds:**
```
Expr::NumLit { value }
Expr::StrLit { value }
Expr::Ident { name }
Expr::BinOp { op, lhs, rhs }
Expr::UnaryOp { op, expr }
Expr::CallExpr { callee, args }
Expr::IndexExpr { object, index }
Expr::FieldExpr { object, field }
Expr::ArrayLit { items }
Expr::DictLit { pairs }
Expr::LambdaExpr { params, body }
Expr::MatchExpr { subject, arms }
Expr::MolLit { packed }
Expr::ListComp { ... }
```

---

## SHORTCUT: Start with parser.ol

Parser match blocks are the ones that crash parse_stmt.
Fix parser.ol → parse_stmt works → analyze works → eval works.
semantic.ol match blocks run AFTER parse → less urgent.

---

## EFFORT

```
parser.ol:   26 blocks × ~5 min each = ~2 giờ
semantic.ol: 18 blocks × ~5 min each = ~1.5 giờ
Total: ~3.5 giờ mechanical work

Mỗi block: đọc match arms → viết if/else chain → test
Không cần suy nghĩ. Chỉ cần chính xác.
```

---

## TEST SAU MỖI FILE

```bash
# Sau bypass parser.ol:
make build
echo 'emit 42;' | ./origin.olang              # Rust binary OK
./origin.olang --build
chmod +x origin_new.olang
echo 'emit 42;' | ./origin_new.olang           # Self-built: should work now!

# Sau bypass semantic.ol:
echo 'fn f(x) { return x + 1; }; emit f(5);' | ./origin_new.olang  # 6
echo 'let a = [1,2,3]; emit len(a);' | ./origin_new.olang          # 3
```

---

## ALTERNATIVE: Fix match codegen root cause

Nếu muốn fix thay vì bypass — root cause suspects:

```
1. Match body re-parses from __g_ma_tokens → re-parse may produce
   different AST than original parse → different bytecodes
   
2. Jump target calculation: match bodies have Jmp to end-jump slot,
   end-jump slot Jmp to _m_end. If offsets wrong → infinite loop/crash

3. __match_enum in compiled code pushes tag as Push(str).
   If str encoding different between Rust/Olang compiler → tag mismatch

Test: emit bytecode diff for simple match between both compilers:
  echo 'dump_match' | ./origin.olang       (Rust-compiled)
  echo 'dump_match' | ./origin_new.olang   (self-compiled)
  Compare byte-by-byte.
```

Nhưng bypass = chắc chắn work, 3.5 giờ. Fix root cause = có thể 1 giờ hoặc 1 ngày.

---

*Sora — 2026-03-29. Bypass là con đường chắc chắn. Self-build SẮP XONG.*
