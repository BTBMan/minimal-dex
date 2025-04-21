import Link from 'next/link'

export default function MainNav() {
  return (
    <nav className="flex items-center space-x-4 [&>a:hover]:text-primary">
      <Link href="/swap">
        Swap
      </Link>
      <Link href="/pool">
        Pool
      </Link>
      <Link href="/position">
        Position
      </Link>
      <Link href="/faucet">
        Faucet
      </Link>
    </nav>
  )
}
