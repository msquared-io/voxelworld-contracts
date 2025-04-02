import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { foundry } from 'viem/chains';
import { getContractFactory } from './contractFactory'

const ownerPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const owner = privateKeyToAccount(ownerPrivateKey);

const publicClient = createPublicClient({
  chain: foundry,
  transport: http(),
});

const walletClient = createWalletClient({
  chain: foundry,
  transport: http(),
  account: owner,
});

export async function deployContract(basePath: string, contractName: string, args: any[] = []) {
  const factory = await getContractFactory(basePath, contractName);
  const deployHash = await walletClient.deployContract({
    ...factory,
    args,
    account: owner,
  });

  const receipt = await publicClient.waitForTransactionReceipt({ hash: deployHash });
  return receipt.contractAddress;
} 