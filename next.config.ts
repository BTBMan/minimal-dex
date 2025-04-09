import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  reactStrictMode: false,
  images: {
    remotePatterns: [
      {
        hostname: '*.mypinata.cloud',
      },
    ],
  },
}

export default nextConfig
