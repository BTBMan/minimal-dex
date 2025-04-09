'use client'

import { DesktopIcon, MoonIcon, PersonIcon, SunIcon } from '@radix-ui/react-icons'
import { useTheme } from 'next-themes'
import Link from 'next/link'
import { normalize } from 'viem/ens'
import { useAccount, useEnsAvatar, useEnsName } from 'wagmi'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import ConnectButton from './ConnectButton'

export default function MainMenu() {
  const { address, isConnected } = useAccount()
  const { data: ensName } = useEnsName({ address })
  const { data: ensAvatar } = useEnsAvatar({ name: normalize(ensName || '') })

  const { setTheme, theme } = useTheme()
  const themes = [
    {
      key: 'light',
      icon: <SunIcon />,
    },
    {
      key: 'system',
      icon: <DesktopIcon />,
    },
    {
      key: 'dark',
      icon: <MoonIcon />,
    },
  ]

  return (
    <div className="flex items-center space-x-2">
      <DropdownMenu modal={false}>
        <DropdownMenuTrigger className="outline-none">
          <Avatar>
            <AvatarImage src={ensAvatar || ''} />
            <AvatarFallback>
              {address
                ? <div className="w-full h-full flex items-center justify-center text-[20px] bg-[#FAE388]">🙀</div>
                : <PersonIcon className="w-[20px] h-[20px]" />}
            </AvatarFallback>
          </Avatar>
        </DropdownMenuTrigger>
        <DropdownMenuContent className="w-[240px]">
          <DropdownMenuLabel>
            <ConnectButton />
          </DropdownMenuLabel>
          {isConnected && (
            <div className="[&>a[role='menuitem']]:leading-[30px] [&>a[role='menuitem']]:hover:cursor-pointer">
              <DropdownMenuSeparator />
              <DropdownMenuItem asChild>
                <Link href="/profile">
                  Profile
                </Link>
              </DropdownMenuItem>
            </div>
          )}
          <DropdownMenuSeparator />
          <DropdownMenuLabel>
            <Tabs
              defaultValue={theme}
              onValueChange={(value) => {
                setTheme(value)
              }}
            >
              <TabsList className="w-full">
                {themes.map(theme => (
                  <TabsTrigger className="flex-1" key={theme.key} value={theme.key}>
                    {theme.icon}
                  </TabsTrigger>
                ))}
              </TabsList>
            </Tabs>
          </DropdownMenuLabel>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  )
}
