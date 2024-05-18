
import { ethers } from "hardhat";

async function main() {
 // Deploy NFT contract on ETH
  const NFTContract = await ethers.getContractFactory("C168EthNFT");
  const nftContract = await NFTContract.deploy(await ethers.provider.getSigner());
  await nftContract.deploymentTransaction()?.wait();

  const nftContract1 = await NFTContract.deploy(await ethers.provider.getSigner());
  await nftContract1.deploymentTransaction()?.wait();

  console.log("NFT contract deployed to: ", await nftContract.getAddress());
  console.log("NFT contract1 deployed to: ", await nftContract1.getAddress());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
