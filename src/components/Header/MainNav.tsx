import Link from 'next/link'

export default function MainNav() {
  return (
    <nav className="flex items-center space-x-4 [&>a:hover]:text-primary">
      <Link href="/">
        Home
      </Link>
    </nav>
  )
}
