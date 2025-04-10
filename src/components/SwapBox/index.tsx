import { Button } from '@/components/ui/button'
import TokenInputItem from './TokenInputItem'
import TransformButton from './TransformButton'

export default function SwapBox() {
  return (
    <div>
      <div className="w-[480px] mx-auto pt-12">
        <TokenInputItem label="Sell" />
        <TransformButton />
        <TokenInputItem className="mt-1" label="Buy" />
        <Button className="w-full mt-1 h-[50px] rounded-[20px] text-[18px]">Swap</Button>
      </div>
    </div>
  )
}
