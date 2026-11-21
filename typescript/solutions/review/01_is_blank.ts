/** True for a missing value (null or undefined) and for the empty string; every other value is not blank. */
export function isBlank(value: unknown): boolean {
  return value == null || value === ""
}
