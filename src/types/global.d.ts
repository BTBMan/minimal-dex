import type { PropsWithChildren } from 'react'

declare global {
  type PageProps<P = unknown, S = unknown> = Readonly<{
    params: Promise<P>
    searchParams: Promise<S>
  }>

  type PagePropsWithChildren<P = unknown, S = unknown> = Readonly<PropsWithChildren<PageProps<P, S>>>

  namespace NodeJS {
    interface ProcessEnv {
      // WalletConnect
      NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID: string

      // Foundry
      LOCAL_PRIVATE_KEY: string
      LOCAL_RPC_URL: string
      TEST_PRIVATE_KEY: string
      SEPOLIA_RPC_URL: string
      ETHERSCAN_API_KEY: string

      // Pinata
      PINATA_JWT: string
      NEXT_PUBLIC_GATEWAY_URL: string
    }
  }

  interface NFTMetadata {
    name: string
    description: string
    image: string
    attributes?: Record<string, any>[]
  }
}

export {}
