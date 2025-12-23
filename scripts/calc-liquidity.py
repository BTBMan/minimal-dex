import math

amount_eth = 1
amount_usdc = 5000
q96 = 2**96

def price_to_tick(p):
    return math.floor(math.log(p, 1.0001))

print(price_to_tick(5000))

def price_to_sqrtp(p):
    return int(math.sqrt(p) * q96)

sqrtp_low = price_to_sqrtp(4545)
sqrtp_cur = price_to_sqrtp(5000)
sqrtp_upp = price_to_sqrtp(5500)

def liquidity0(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (amount * (pa * pb) / q96) / (pb - pa)

def liquidity1(amount, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return amount * q96 / (pb - pa)

liq0 = liquidity0(amount_eth, sqrtp_cur, sqrtp_upp)
liq1 = liquidity1(amount_usdc, sqrtp_cur, sqrtp_low)
liq = int(min(liq0, liq1))

print(liq0, liq1, liq)

def calc_amount0(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (liq * q96 * (pb - pa) / pa / pb)


def calc_amount1(liq, pa, pb):
    if pa > pb:
        pa, pb = pb, pa
    return (liq * (pb - pa) / q96)

amount0 = calc_amount0(liq, sqrtp_upp, sqrtp_cur)
amount1 = calc_amount1(liq, sqrtp_low, sqrtp_cur)
print(amount0, amount1)
