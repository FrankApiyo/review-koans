export type BlankKind = "value" | "code" | "verdict"

const MESSAGES: Readonly<Record<BlankKind, (reviewPath?: string) => string>> = Object.freeze({
  value: () => "Replace __ with the value that makes this true.",
  code: () => "Replace __blank() with the code the meditation describes.",
  verdict: (reviewPath?: string) =>
    `Replace __ with "fine", or the number of the line with the bug in ${reviewPath}.`,
})

export class Blank extends Error {
  override name = "Blank"
  readonly kind: BlankKind
  readonly reviewPath?: string

  constructor(kind: BlankKind, reviewPath?: string) {
    super(MESSAGES[kind](reviewPath))
    this.kind = kind
    if (reviewPath !== undefined) this.reviewPath = reviewPath
  }
}

/** Vitest consults an expected value's `asymmetricMatch` in `toEqual` and `toStrictEqual`, so any comparison fails. */
export const __ = Object.freeze({
  asymmetricMatch(_actual: unknown): never {
    throw new Blank("value")
  },
  toString(): string {
    return "__"
  },
  toAsymmetricMatcher(): string {
    return "__"
  },
})

export function __blank(): never {
  throw new Blank("code")
}
