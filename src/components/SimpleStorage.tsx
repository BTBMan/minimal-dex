'use client'

import { useEffect } from 'react'
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi'
import { Button } from '@/components/ui/button'
import { SimpleStorage } from '@/contract-data/SimpleStorage'

export default function SimpleStorageComp() {
  const { isConnected } = useAccount()

  const { data: favoriteNumber, refetch: refetchFavoriteNumber } = useReadContract({
    ...SimpleStorage,
    functionName: 'favoriteNumber',
  })

  const { writeContract, data } = useWriteContract()
  const onStore = () => {
    writeContract({
      ...SimpleStorage,
      functionName: 'store',
      args: [(favoriteNumber ?? 0n) + 1n],
    })
  }

  const { isSuccess } = useWaitForTransactionReceipt({
    hash: data,
  })
  useEffect(() => {
    if (isSuccess) {
      refetchFavoriteNumber()
    }
  }, [isSuccess, refetchFavoriteNumber])

  return (
    <div>
      <p>The favorite number is {favoriteNumber}</p>
      {
        isConnected
          ? <Button onClick={onStore}>Store</Button>
          : 'Please connect your wallet to store a number'
      }
    </div>
  )
}
