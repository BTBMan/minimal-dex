// eth = x, usdc = y
// current price: 1 eth = 5000 usdc
// tick lower: 1 eth = 4545 usdc
// tick upper: 1 eth = 5500 usdc

const ETH = 10 ** 18
const Q96 = 2 ** 96
const ETH_AMOUNT = 1 * ETH
const USDC_AMOUNT = 5000 * ETH
const CURRENT_PRICE = 5000
const MIN_PRICE = 4545
const MAX_PRICE = 5500

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

const x = Math.floor(Lf * ((upperSqrtPQ96 - currentSqrtPQ96) / ((upperSqrtPQ96 * currentSqrtPQ96) / Q96)))
const y = Math.floor(Lf * ((currentSqrtPQ96 - lowerSqrtPQ96) / Q96))

console.log({
  x,
  y,
})

console.log('Calculate first transaction ------------------------------------')

const AMOUNT_IN = 42
const AMOUNT_IN_ETH = AMOUNT_IN * ETH
const amountInPQ96 = (AMOUNT_IN_ETH * Q96) / Lf
const newPriceQ96 = currentSqrtPQ96 + amountInPQ96
const newPrice = (newPriceQ96 / Q96) ** 2
const newTick = Math.floor(getLogBase(newPriceQ96 / Q96, Math.sqrt(1.0001)))
const usdcIn = Math.floor(Lf * ((newPriceQ96 - currentSqrtPQ96) / Q96)) / ETH // Loss of precision
const ethOut = Math.floor(Lf * ((newPriceQ96 - currentSqrtPQ96) / ((newPriceQ96 * currentSqrtPQ96) / Q96))) / ETH
const validateEthOut = ((1 / (newPriceQ96 / Q96)) - (1 / (currentSqrtPQ96 / Q96))) * Lf / ETH

console.log({
  AMOUNT_IN,
  amountInPQ96,
  newPriceQ96,
  newPrice,
  newTick,
  usdcIn,
  ethOut,
  validateEthOut,
})

console.log('Calculate second transaction ------------------------------------')

const AMOUNT_IN_2 = 0.01337337
const AMOUNT_IN_ETH_2 = AMOUNT_IN_2 * ETH
const newPriceQ96_2 = (((currentSqrtPQ96 * Lf * Q96)) / ((AMOUNT_IN_ETH_2 * currentSqrtPQ96) + Lf * Q96))
const newPrice_2 = (newPriceQ96_2 / Q96) ** 2
const newTick_2 = Math.floor(getLogBase(newPriceQ96_2 / Q96, Math.sqrt(1.0001)))
const ethIn_2 = Math.floor(Lf * ((currentSqrtPQ96 - newPriceQ96_2) / ((newPriceQ96_2 * currentSqrtPQ96) / Q96))) / ETH
const usdcOut_2 = Math.floor(Lf * ((currentSqrtPQ96 - newPriceQ96_2) / Q96)) / ETH // Loss of precision

console.log({
  AMOUNT_IN_2,
  newPriceQ96_2,
  newPrice_2,
  newTick_2,
  ethIn_2,
  usdcOut_2,
})

// util
function getLogBase(n: number, b: number) {
  // log_b(n) = log_e(n) / log_e(b)
  return Math.log(n) / Math.log(b)
}

export {}
