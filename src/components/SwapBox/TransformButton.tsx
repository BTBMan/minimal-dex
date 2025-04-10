import { ArrowDown } from 'lucide-react'
import { Button } from '@/components/ui/button'

export default function TransformButton() {
  return (
    <div className="h-0 relative">
      <Button
        className="absolute left-1/2 -translate-x-1/2 top-1/2 -translate-y-1/2 shadow-none border-[5px] border-white box-content rounded-[15px]"
        variant="secondary"
        size="icon"
      >
        <ArrowDown className="!size-5" />
      </Button>
    </div>
  )
}
