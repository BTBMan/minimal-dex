import type { Metadata } from 'next'
import Header from '@/components/Header'
import Providers from '@/components/Providers'
import { Toaster } from '@/components/ui/sonner'
import '../styles/globals.css'

export const metadata: Metadata = {
  title: 'Minimal DEX',
  description: 'Minimal implementation of Uniswap V3',
}

export default function RootLayout({
  children,
}: PagePropsWithChildren) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="">
        <Providers>
          <div className="app">
            <Header />
            <main>
              <div className="w-[var(--main-min-width)] mx-auto">
                {children}
              </div>
            </main>
          </div>
        </Providers>
        <Toaster richColors />
      </body>
    </html>
  )
}
