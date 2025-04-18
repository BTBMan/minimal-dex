import React from 'react'
import { useDefault } from 'react-use'
import { cn } from '@/utils'

interface Props {
  className?: string
  label: string
  defaultValue?: string
  value?: string
  onChange?: (value: string) => void
  disabled?: boolean
  tokenSelector?: React.ReactNode
}

export default function TokenInputItem({
  className,
  label,
  defaultValue,
  value: _value,
  onChange,
  disabled,
  tokenSelector,
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
    <div className={cn('flex flex-col gap-2 border-[1px] border-gray-100 rounded-[20px] py-5 px-4', className, { 'bg-gray-50 border-gray-50': disabled })}>
      <div className="text-[16px] text-gray-500 leading-[20px]">{label}</div>
      <div className="flex items-center gap-2">
        <div className="flex-1">
          <input
            className="w-full min-h-[40px] text-[35px] outline-none disabled:bg-transparent"
            placeholder="0"
            value={value}
            onChange={onAmountChange}
            disabled={disabled}
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
