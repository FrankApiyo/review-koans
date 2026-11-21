/** Labels names with this labeler's prefix; `label` may be passed on its own as a callback. */
export class Labeler {
  prefix: string
  constructor(prefix: string) { this.prefix = prefix }
  label = (name: string) => `${this.prefix}-${name}`
}
