import React from 'react'
import { useControllableValue } from '@/hooks/use-controllable-value'
import { cn, isNullable } from '@/utils'

interface Props {
  className?: string
  label: string
  defaultValue?: Nullable<number>
  value?: Nullable<number>
  disabled?: boolean
  active?: boolean
  tokenSelector?: React.ReactNode
  onChange?: (value: Nullable<number>) => void
  onClick?: () => void
}

export default function TokenInputItem(props: Props) {
  const {
    className,
    label,
    active,
    tokenSelector,
    onClick,
  } = props
  const [value, setValue] = useControllableValue(props)
  const onAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = e.target.value
    if (/^\d*(?:\.\d*)?$/.test(v)) {
      setValue(isNullable(v) || v === '' ? null : Number(v))
    }
  }

  return (
    <div
      className={cn('flex flex-col gap-2 border-[1px] rounded-[20px] py-5 px-4 bg-gray-50 border-gray-50', className, { 'bg-white border-gray-100': active })}
      onClick={onClick}
    >
      <div className="text-[16px] text-gray-500 leading-[20px]">{label}</div>
      <div className="flex items-center gap-2">
        <div className="flex-1">
          <input
            className="w-full min-h-[40px] text-[35px] outline-none bg-transparent"
            placeholder="0"
            value={value}
            onChange={onAmountChange}
          />
        </div>
        <div>{tokenSelector}</div>
      </div>
      <div className="flex items-center justify-between text-[14px] text-gray-500 leading-[18px]">
        <span>$0</span>
        <span>100 ETH</span>
      </div>
    </div>
  )
}
