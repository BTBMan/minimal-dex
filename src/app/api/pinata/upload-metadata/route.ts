import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'
import { pinata } from '@/libs/pinata'

export interface UploadNftRequestData<Image = File> extends Omit<NFTMetadata, 'image'> {
  image: Image
}

export interface UploadNftResponseData {
  url: string
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const data: UploadNftRequestData = Object.entries(Object.fromEntries(formData.entries())).reduce((init, [key, value]) => {
      init[key] = value
      return init
    }, {} as any)

    const file = formData.get('image') as File
    const { cid: fileCid } = await pinata.upload.public.file(file)
    const fileUrl = await pinata.gateways.public.convert(fileCid)
    const { cid: metadataCid } = await pinata.upload.public.json({
      ...data,
      image: fileUrl,
    })
    const url = await pinata.gateways.public.convert(metadataCid)

    return NextResponse.json<UploadNftResponseData>({ url }, { status: 200 })
  }
  catch (error) {
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 },
    )
  }
}
