import fs from 'node:fs'
import path from 'node:path'

const OUTPUT_DIR = './src/contract-data'
const scriptPath = process.argv[2]

// Ensure script path is provided
if (!scriptPath) {
  console.error('Script path is required')
  process.exit(1)
}

const contractName = scriptPath.replace(/.*\/([^/]+)\.s\.sol.*/, '$1')

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true })
}

console.log('Generating ABI for ', contractName)

try {
  // Find the latest broadcast log
  const broadcastDir = path.join(path.join(process.cwd(), 'contract'), 'broadcast')
  const runLatestFiles = findFiles(broadcastDir, 'run-latest.json')

  if (runLatestFiles.length === 0) {
    throw new Error('No broadcast logs found')
  }

  // Get the latest broadcast log
  const latestBroadcast = runLatestFiles
    .map(file => ({ file, mtime: fs.statSync(file).mtime }))
    .sort((a, b) => b.mtime.getTime() - a.mtime.getTime())[0]
    .file

  // Parse the broadcast log
  const broadcastLog = JSON.parse(fs.readFileSync(latestBroadcast, 'utf8'))

  // Find the contract creation transaction
  const createTx = broadcastLog.transactions.find(
    (tx: any) => tx.transactionType === 'CREATE' && tx.contractName === contractName,
  )

  if (!createTx) {
    throw new Error(`Could not find deployment transaction for ${contractName}`)
  }

  const contractAddress = createTx.contractAddress
  console.log(`Contract deployed at: ${contractAddress}`)

  // Find the ABI file
  const outDir = path.join(path.join(process.cwd(), 'contract'), 'forge-artifacts')
  const abiFiles = findFiles(outDir, `${contractName}.json`)

  if (abiFiles.length === 0) {
    throw new Error('No ABI file found')
  }

  const abiFile = abiFiles[0]
  const abi = JSON.parse(fs.readFileSync(abiFile, 'utf8')).abi

  // Create ABI file
  const jsonData = JSON.stringify({
    address: contractAddress,
    abi,
  }, null, 2)
  const contractData = `export const ${contractName} = ${jsonData} as const`
  const outputFile = path.join(OUTPUT_DIR, `${contractName}.ts`)
  fs.writeFileSync(outputFile, contractData)

  console.log(`ABI file saved to ${outputFile}`)
}
catch (error) {
  console.error('Deployment failed:', error)
  process.exit(1)
}

// Recursively find files
function findFiles(dir: string, pattern: string): string[] {
  let results: string[] = []
  const list = fs.readdirSync(dir)

  for (const file of list) {
    const filePath = path.join(dir, file)
    const stat = fs.statSync(filePath)

    if (stat.isDirectory()) {
      results = results.concat(findFiles(filePath, pattern))
    }
    else if (file === pattern || file.match(pattern)) {
      results.push(filePath)
    }
  }

  return results
}
