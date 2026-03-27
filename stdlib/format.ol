// stdlib/format.ol — String formatting utilities

pub fn int_to_str(val) {
  if val == 0 { return "0"; }
  let neg = val < 0;
  if neg { val = 0 - val; }
  let digits = "";
  while val > 0 {
    let d = val - (val / 10) * 10;  // val % 10
    digits = __chr(48 + d) + digits;
    val = val / 10;
  }
  if neg { return "-" + digits; }
  return digits;
}

pub fn f64_to_str(val, decimals) {
  if decimals <= 0 { decimals = 2; }
  let neg = val < 0.0;
  if neg { val = 0.0 - val; }

  let int_part = __floor(val);
  let frac_part = val - int_part;

  let result = int_to_str(int_part);

  // Fractional part
  result = result + ".";
  let i = 0;
  while i < decimals {
    frac_part = frac_part * 10.0;
    let digit = __floor(frac_part);
    if digit > 9 { digit = 9; }
    result = result + int_to_str(digit);
    frac_part = frac_part - digit;
    i = i + 1;
  }

  if neg { return "-" + result; }
  return result;
}

pub fn pad_left(s, width, ch) {
  while len(s) < width {
    s = ch + s;
  }
  return s;
}

pub fn pad_right(s, width, ch) {
  while len(s) < width {
    s = s + ch;
  }
  return s;
}

pub fn hex(val) {
  if val == 0 { return "0"; }
  let hex_chars = "0123456789abcdef";
  let result = "";
  while val > 0 {
    let d = val - (val / 16) * 16;
    result = char_at(hex_chars, d) + result;
    val = val / 16;
  }
  return result;
}

pub fn to_string(val) {
  // Generic to_string: detect type and convert
  if type_of(val) == "number" {
    if val == __floor(val) { return int_to_str(val); }
    return f64_to_str(val, 6);
  }
  return "" + val;
}

fn __chr(code) {
  return __chr(code);
}
