/** Reads a comma-separated list of decimal ids. */
// >>> fix
export const parseIds = (csv: string): number[] => csv.split(",").map(parseInt)
// === fixed
export const parseIds = (csv: string): number[] => csv.split(",").map((s) => Number.parseInt(s, 10))
// === alt: converts each id with Number
export const parseIds = (csv: string): number[] => csv.split(",").map(Number)
// === alt: passes parseInt only the text, so it never sees the index
export const parseIds = (csv: string): number[] => csv.split(",").map((s) => parseInt(s))
// === wrong: refuses — returns no ids
export const parseIds = (csv: string): number[] => []
// === wrong: partial — Number.parseInt is the same function, so the index is still the radix
export const parseIds = (csv: string): number[] => csv.split(",").map(Number.parseInt)
// === wrong: partial — reads each id in a base that grows with its position
export const parseIds = (csv: string): number[] => csv.split(",").map((s, i) => parseInt(s, i + 10))
// <<<
