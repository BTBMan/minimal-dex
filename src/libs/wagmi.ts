import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { metaMaskWallet } from '@rainbow-me/rainbowkit/wallets'
import { hardhat, mainnet, sepolia } from 'viem/chains'
import { http } from 'wagmi'
import '@rainbow-me/rainbowkit/styles.css'

export const wagmiConfig = getDefaultConfig({
  appName: 'nextjs-foundry-scaffold',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID!,
  wallets: [
    {
      groupName: 'Recommended',
      wallets: [
        metaMaskWallet,
      ],
    },
  ],
  ssr: true,
  chains: [
    mainnet,
    sepolia,
    hardhat,
  ],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [hardhat.id]: http(),
  },
})
