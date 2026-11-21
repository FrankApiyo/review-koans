/** Sends `text` and returns its length. */
export function note(text: string, send: (text: string) => Promise<void>): number {
  send(text).then(() => undefined)
  return text.length
}
