'use client'

import { useState } from 'react'
import TokenSelector from '@/components/TokenSelector'
import { Button } from '@/components/ui/button'
import TokenInputItem from './TokenInputItem'
import TransformButton from './TransformButton'

export default function SwapBox() {
  const [tokenA, setTokenA] = useState<Nullable<string>>()
  const [tokenB, setTokenB] = useState<Nullable<string>>()
  const [amountA, setAmountA] = useState<Nullable<number>>(1)
  const [amountB, setAmountB] = useState<Nullable<number>>()
  const [activeToken, setActiveToken] = useState<'tokenA' | 'tokenB'>('tokenA')

  function switchToken() {
    const oldTokenA = tokenA
    const oldAmountA = amountA
    setTokenA(tokenB)
    setAmountA(amountB)
    setTokenB(oldTokenA)
    setAmountB(oldAmountA)
    setActiveToken(activeToken === 'tokenA' ? 'tokenB' : 'tokenA')
  }

  const canSwap = () => {
    return amountA && amountB && tokenA && tokenB
  }

  return (
    <div>
      <div className="w-[480px] mx-auto pt-12">
        <TokenInputItem
          label="Sell"
          value={amountA}
          active={activeToken === 'tokenA'}
          onChange={(v) => {
            setAmountA(v)
          }}
          tokenSelector={(
            <TokenSelector
              value={tokenA}
              onChange={setTokenA}
            />
          )}
          onClick={() => setActiveToken('tokenA')}
        />
        <TransformButton onClick={switchToken} />
        <TokenInputItem
          className="mt-1"
          label="Buy"
          value={amountB}
          active={activeToken === 'tokenB'}
          onChange={setAmountB}
          tokenSelector={(
            <TokenSelector
              value={tokenB}
              onChange={setTokenB}
            />
          )}
          onClick={() => setActiveToken('tokenB')}
        />
        <Button className="w-full mt-2 h-[50px] rounded-[20px] text-[18px]" disabled={!canSwap()}>Swap</Button>
      </div>
    </div>
  )
}
