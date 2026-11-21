/** The scores in ascending numeric order, as a new list; the caller's list is left as it was. */
export const rank = (scores: number[]): number[] => [...scores].sort((a, b) => a - b)
