import { createPublicClient, createWalletClient, http, parseAbi } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { somnia } from './somnia';


// ABI for the CraftingSystem contract
const craftingSystemAbi = parseAbi([
  'function addRecipe(uint256 outputItemId, uint256[] calldata inputItemIds, uint256[] calldata inputAmounts, uint256 outputAmount) external',
]);

async function main() {
  // Create wallet client with private key
  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
  
  const client = createWalletClient({
    account,
    chain: somnia,
    transport: http()
  });

  // Contract address
  const contractAddress = '0x5498eB0D1d83Eba58a33D1D6D62E7467409e751c';
//   const contractAddress = '0xB6efC0475503F676C751eEdacDBB9EA5229aC5b3';

  const gold = 266
  const diamond = 264
  const dirt = 3
  const sand = 12
  const iron = 265
  const grassBlock = 2

  // Define recipe parameters
  const outputItemId = BigInt(sand);
  const inputItemIds = [BigInt(grassBlock)];
  const inputAmounts = [BigInt(1)]; 
  const outputAmount = BigInt(5);

  try {
    // Add the recipe
    const hash = await client.writeContract({
      address: contractAddress,
      abi: craftingSystemAbi,
      functionName: 'addRecipe',
      args: [outputItemId, inputItemIds, inputAmounts, outputAmount],
    });
    
    console.log('Transaction sent:', hash);
    
    // Create public client to wait for transaction
    const publicClient = createPublicClient({
      chain: somnia,
      transport: http(),
    });
    
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log('Recipe added successfully!');
  } catch (error) {
    console.error('Error adding recipe:', error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 