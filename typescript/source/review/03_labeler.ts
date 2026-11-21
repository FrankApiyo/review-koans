/** Labels names with this labeler's prefix; `label` may be passed on its own as a callback. */
export class Labeler {
  prefix: string
  constructor(prefix: string) { this.prefix = prefix }
  // >>> guard
  label = (name: string) => `${this.prefix}-${name}`
  // === wrong: partial — a method gets its this from the call, so a detached call has none
  label(name: string) { return `${this.prefix}-${name}` }
  // === wrong: partial — a function expression gets its this from the call, so a detached call has none
  label = function (name: string) { return `${this.prefix}-${name}` }
  // <<<
}
