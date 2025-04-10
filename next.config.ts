import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  redirects: async () => [
    {
      source: '/',
      destination: '/swap',
      permanent: true,
    },
  ],
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
