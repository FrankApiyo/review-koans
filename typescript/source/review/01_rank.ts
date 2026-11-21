/** The scores in ascending numeric order, as a new list; the caller's list is left as it was. */
// >>> guard
export const rank = (scores: number[]): number[] => [...scores].sort((a, b) => a - b)
// === wrong: partial — sorts with no comparator, which compares the scores as text
export const rank = (scores: number[]): number[] => [...scores].sort()
// === wrong: partial — sorts the caller's list in place
export const rank = (scores: number[]): number[] => scores.sort((a, b) => a - b)
// === wrong: partial — sorts in descending order
export const rank = (scores: number[]): number[] => [...scores].sort((a, b) => b - a)
// <<<
