'use client'

import { useState } from 'react'
import TokenSelector from '@/components/TokenSelector'
import { Button } from '@/components/ui/button'
import TokenInputItem from './TokenInputItem'
import TransformButton from './TransformButton'

export default function SwapBox() {
  const [tokenA, setTokenA] = useState<string>()
  const [tokenB, setTokenB] = useState<string>()
  const [amountA, setAmountA] = useState<string>()
  const [amountB, setAmountB] = useState<string>()
  const [disableToken, setDisableToken] = useState<'tokenA' | 'tokenB'>('tokenB')

  return (
    <div>
      <div className="w-[480px] mx-auto pt-12">
        <TokenInputItem
          label="Sell"
          value={amountA}
          disabled={disableToken === 'tokenA'}
          onChange={setAmountA}
          tokenSelector={(
            <TokenSelector
              value={tokenA}
              onChange={setTokenA}
            />
          )}
        />
        <TransformButton />
        <TokenInputItem
          className="mt-1"
          label="Buy"
          value={amountB}
          disabled={disableToken === 'tokenB'}
          onChange={setAmountB}
          tokenSelector={(
            <TokenSelector
              value={tokenB}
              onChange={setTokenB}
            />
          )}
        />
        <Button className="w-full mt-2 h-[50px] rounded-[20px] text-[18px]">Swap</Button>
      </div>
    </div>
  )
}
