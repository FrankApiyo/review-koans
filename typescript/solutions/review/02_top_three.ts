/** The three highest scores, highest first; the caller's list is left as it was. */
export const topThree = (scores: number[]): number[] => scores.toSorted((a, b) => b - a).slice(0, 3)
