import { cn } from '@/utils'

interface Props {
  title: string
  className?: string
}

export default function PageTitle({ title, className }: Props) {
  return (
    <div className={cn(className)}>
      <span className="text-2xl font-bold">{title}</span>
    </div>
  )
}
