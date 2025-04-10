import { cn } from '@/utils'

interface Props {
  className?: string
  label: string
}

export default function TokenInputItem({ className, label }: Props) {
  return (
    <div className={cn('flex flex-col gap-2 border-[1px] border-gray-200 rounded-[20px] p-4', className)}>
      <div className="text-[16px] text-gray-500 leading-[20px]">{label}</div>
      <div className="flex items-center gap-2">
        <input type="text" className="flex-1 min-h-[40px] text-[35px] outline-none" placeholder="0" />
        <div>Select token</div>
      </div>
      <div className="flex items-center justify-between text-[14px] text-gray-500 leading-[18px]">
        <span>$0</span>
        <span>100 ETH</span>
      </div>
    </div>
  )
}
