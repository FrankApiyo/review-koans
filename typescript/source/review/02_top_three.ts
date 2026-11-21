/** The three highest scores, highest first; the caller's list is left as it was. */
// >>> fix
export const topThree = (scores: number[]): number[] => scores.sort((a, b) => b - a).slice(0, 3)
// === fixed
export const topThree = (scores: number[]): number[] => scores.toSorted((a, b) => b - a).slice(0, 3)
// === alt: sorts a spread copy
export const topThree = (scores: number[]): number[] => [...scores].sort((a, b) => b - a).slice(0, 3)
// === alt: sorts a copy made by slice
export const topThree = (scores: number[]): number[] => scores.slice().sort((a, b) => b - a).slice(0, 3)
// === wrong: refuses — returns no scores
export const topThree = (scores: number[]): number[] => []
// === wrong: partial — takes the first three before sorting, so a higher score later in the list is missed
export const topThree = (scores: number[]): number[] => scores.slice(0, 3).sort((a, b) => b - a)
// === wrong: partial — sorts with no comparator, which compares the scores as text
export const topThree = (scores: number[]): number[] => [...scores].sort().reverse().slice(0, 3)
// === wrong: partial — takes the three highest from the end, so they come back lowest first
export const topThree = (scores: number[]): number[] => [...scores].sort((a, b) => a - b).slice(-3)
// <<<
