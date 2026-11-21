/** True for a missing value (null or undefined) and for the empty string; every other value is not blank. */
export function isBlank(value: unknown): boolean {
  // >>> fix
  return value == null || value == ""
  // === fixed
  return value == null || value === ""
  // === alt: names both missing values with strict equality
  return value === null || value === undefined || value === ""
  // === alt: turns a missing value into the empty string, then compares strictly
  return (value ?? "") === ""
  // === wrong: refuses — no value is ever blank
  return false
  // === wrong: partial — any falsy value counts, so zero and false are blank
  return !value
  // === wrong: partial — only the empty string counts, so a missing value is not blank
  return value === ""
  // === wrong: partial — compares the value as text, so an empty list is blank
  return String(value ?? "").trim() === ""
  // === wrong: partial — excuses zero and false by name, so other falsy values are still blank
  return !value && value !== 0 && value !== false
  // <<<
}
