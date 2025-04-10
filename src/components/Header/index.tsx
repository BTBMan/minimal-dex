import Link from 'next/link'
import MainMenu from './MainMenu'
import MainNav from './MainNav'

export default function Header() {
  return (
    <header className="border-b-[1px]">
      <div className="main-content flex items-center justify-between">
        <div className="flex items-center">
          <div className="mr-6">
            <Link href="/">
              <div className="w-[40px] h-[40px] flex items-center justify-center text-[12px] font-bold bg-foreground text-background rounded-full">
                SWAP
              </div>
            </Link>
          </div>
          <MainNav />
        </div>
        <div>
          <MainMenu />
        </div>
      </div>
    </header>
  )
}
