// eth = x, usdc = y
// current price: 1 eth = 5000 usdc
// tick lower: 1 eth = 4545 usdc
// tick upper: 1 eth = 5500 usdc

const ETH = 10 ** 18
const ETH_AMOUNT = 1 * ETH
const USDC_AMOUNT = 5000 * ETH
const CURRENT_PRICE = 5000
const MIN_PRICE = 4545
const MAX_PRICE = 5500
const Q96 = 2 ** 96

console.log('Calculate current/lower/upper sqrtp ---------------------------')

const currentSqrtP = Math.sqrt(CURRENT_PRICE / 1)
const lowerSqrtP = Math.sqrt(MIN_PRICE / 1)
const upperSqrtP = Math.sqrt(MAX_PRICE / 1)

console.log({
  currentSqrtP,
  lowerSqrtP,
  upperSqrtP,
})

console.log('Calculate current/lower/upper sqrtp with Q96 ---------------------------')

const currentSqrtPQ96 = Math.floor(currentSqrtP * Q96)
const lowerSqrtPQ96 = Math.floor(lowerSqrtP * Q96)
const upperSqrtPQ96 = Math.floor(upperSqrtP * Q96)

console.log({
  currentSqrtPQ96,
  lowerSqrtPQ96,
  upperSqrtPQ96,
})

console.log('Calculate the tick corresponding to the sqrtp ------------------------------------')

const currentTick = Math.floor(getLogBase(currentSqrtP, Math.sqrt(1.0001)))
const lowerTick = Math.floor(getLogBase(lowerSqrtP, Math.sqrt(1.0001)))
const upperTick = Math.floor(getLogBase(upperSqrtP, Math.sqrt(1.0001)))

console.log({
  currentTick,
  lowerTick,
  upperTick,
})

console.log('Calculate Lx Ly liquidity ------------------------------------')

const Lx = ETH_AMOUNT * (((currentSqrtPQ96 * upperSqrtPQ96) / Q96) / (upperSqrtPQ96 - currentSqrtPQ96))
const Ly = USDC_AMOUNT * Q96 / (currentSqrtPQ96 - lowerSqrtPQ96)
const Lf = Math.min(Lx, Ly)

console.log({
  Lx,
  Ly,
  Lf,
})

console.log('Calculate ETH(x) and USDC(y) token amount ------------------------------------')

const x = Lf * ((upperSqrtPQ96 - currentSqrtPQ96) / ((upperSqrtPQ96 * currentSqrtPQ96) / Q96))
const y = Lf * ((currentSqrtPQ96 - lowerSqrtPQ96) / Q96)

console.log({
  x,
  y,
})

console.log('Calculate first transaction ------------------------------------')

const AMOUNT_IN = 42
const amountInP = (AMOUNT_IN * Q96) / Lf
const newPriceQ96 = currentSqrtP + amountInP
const newPrice = (newPriceQ96 / Q96) ** 2

console.log({
  amountInP,
  newPriceQ96,
  newPrice,
})

// util
function getLogBase(n: number, b: number) {
  // log_b(n) = log_e(n) / log_e(b)
  return Math.log(n) / Math.log(b)
}

export {}
