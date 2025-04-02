import { readFileSync } from 'fs';
import { join } from 'path';

interface ContractArtifact {
  abi: any[];
  bytecode: string;
}

export async function getContractFactory(basePath: string, contractName: string) {
  const artifactPath = join(__dirname, '../../artifacts/contracts', `${basePath}/${contractName}.sol/${contractName}.json`);
  const artifact = JSON.parse(readFileSync(artifactPath, 'utf8')) as ContractArtifact;

  return {
    abi: artifact.abi,
    bytecode: artifact.bytecode,
  };
} 