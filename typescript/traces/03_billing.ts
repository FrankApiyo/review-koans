class Billing {
  private rate: number

  constructor(rate: number) {
    this.rate = rate
  }

  charge(amount: number): number {
    return amount * this.rate
  }
}

const billing = new Billing(1.16)
const { charge } = billing
console.log([100, 250].map(charge))
