import { useState } from 'react'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useControllableValue } from '@/hooks/use-controllable-value'

interface Props {
  defaultValue?: Nullable<string>
  value?: Nullable<string>
  disabled?: boolean
  onChange?: (value: Nullable<string>) => void
}

interface TokenItem {
  name: string
  symbol: string
  image?: string
  address: string
}

export default function TokenSelector(props: Props) {
  const {
    disabled,
    onChange,
  } = props
  const [value, setValue] = useControllableValue(props)

  const [tokenList] = useState<TokenItem[]>([
    {
      name: 'Ethereum',
      symbol: 'ETH',
      address: '0x0',
    },
    {
      name: 'Bitcoin',
      symbol: 'BTC',
      address: '0x1',
    },
  ])
  const onTokenChange = (value: string) => {
    setValue(value)
    onChange?.(value)
  }

  return (
    <Select value={value} onValueChange={onTokenChange} disabled={disabled}>
      <SelectTrigger className="rounded-[20px] font-[500] focus:!shadow-[none] data-[placeholder]:text-white data-[placeholder]:bg-primary">
        <SelectValue placeholder="Select token" />
      </SelectTrigger>
      <SelectContent>
        {tokenList.map(token => (
          <SelectItem key={token.address} value={token.address}>
            {token.symbol}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
