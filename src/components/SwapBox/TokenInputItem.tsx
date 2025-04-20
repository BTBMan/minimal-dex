import React from 'react'
import { useDefault } from 'react-use'
import { cn } from '@/utils'

interface Props {
  className?: string
  label: string
  defaultValue?: string
  value?: string
  disabled?: boolean
  active?: boolean
  tokenSelector?: React.ReactNode
  onChange?: (value: string) => void
  onClick?: () => void
}

export default function TokenInputItem({
  className,
  label,
  defaultValue,
  value: _value,
  active,
  tokenSelector,
  onChange,
  onClick,
}: Props) {
  const [value, setValue] = useDefault(defaultValue, () => _value ?? defaultValue ?? '')
  const onAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = e.target.value
    if (/^\d*(?:\.\d*)?$/.test(v)) {
      setValue(v)
      onChange?.(v)
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
