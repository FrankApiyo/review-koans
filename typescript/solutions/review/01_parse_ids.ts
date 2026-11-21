/** Reads a comma-separated list of decimal ids. */
export const parseIds = (csv: string): number[] => csv.split(",").map((s) => Number.parseInt(s, 10))
