import type { ColumnDef } from '@tanstack/react-table'
import { PlusIcon } from 'lucide-react'
import { BasicTable } from '@/components/BasicTable'
import PageTitle from '@/components/PageTitle'
import { Button } from '@/components/ui/button'

interface PoolItem {
  pool: string
  token: string
}

const columns: ColumnDef<PoolItem>[] = [
  {
    accessorKey: 'pool',
    header: 'Pool',
  },
  {
    accessorKey: 'token',
    header: 'Token',
  },
]

export default function PoolPage() {
  const data: PoolItem[] = [
    {
      pool: 'Pool 1',
      token: 'Token 1',
    },
    {
      pool: 'Pool 2',
      token: 'Token 2',
    },
  ]

  return (
    <div className="pt-10">
      <PageTitle className="mb-1" title="Pool" />
      <Button><PlusIcon />New</Button>
      <BasicTable className="mt-8" columns={columns} data={data} />
    </div>
  )
}
