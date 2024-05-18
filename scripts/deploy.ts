import { keccak256 } from "@ethersproject/keccak256";
import { toUtf8Bytes } from "@ethersproject/strings";
import { ethers, upgrades } from "hardhat";
import { writeAddresses } from "../utils/utils";

async function main() {
  // Get env variables
  const approvedNFTContract = process.env.approvedNFTContract!.split(", ");
  const usdtAddress = process.env.usdtAddress!;
  const treasuryAddress = process.env.treasuryAddress!;
  const targetGrowthRatePerRebase = process.env.targetGrowthRatePerRebase!;

  // Deploy Ronix contract
  const Ronix = await ethers.getContractFactory("Ronix");
  const ronix = await Ronix.deploy();
  await ronix.deploymentTransaction()?.wait();
  const ronixAddress = await ronix.getAddress();
  console.log("Ronix contract deployed to:", ronixAddress);

  // Deploy Staking contract
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await upgrades.deployProxy(Staking, [
    approvedNFTContract,
    usdtAddress,
    ronixAddress,
    // collateralContract,
  ]);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("Staking contract deployed to:", stakingAddress);

  // Deploy Collateral contract
  const Collateral = await ethers.getContractFactory("Collateral");
  const collateral = await upgrades.deployProxy(Collateral, [
    treasuryAddress,
    ronixAddress,
    usdtAddress,
    stakingAddress,
    targetGrowthRatePerRebase,
  ]);
  await collateral.waitForDeployment();
  const collateralAddress = await collateral.getAddress();
  console.log("Collateral contract deployed to:", collateralAddress);

  // Grant minter role for Ronix contract to collateral contract
  const minterRole = keccak256(toUtf8Bytes("MINTER_ROLE"));
  const tx = await ronix.grantRole(minterRole, collateralAddress);
  const grantReceipt = await tx.wait();
  const hasRole = await ronix.hasRole(minterRole, collateralAddress);
  console.log("Minter role granted at tx: ", grantReceipt?.hash);
  console.log("Minter role is set: ", hasRole);

  // Grant collateral role for staking to collateral contract
  const collateralRole = keccak256(toUtf8Bytes("COLLATERAL_ROLE"));
  const tx1 = await staking.grantRole(collateralRole, collateralAddress);
  const grantReceipt1 = await tx1.wait();
  const hasRole1 = await staking.hasRole(collateralRole, collateralAddress);
  console.log("Collateral role granted at tx: ", grantReceipt1?.hash);
  console.log("Collateral role is set: ", hasRole1);

  // Deploy NFT contract on L2
  const NFTContract = await ethers.getContractFactory("C168L2NFT");
  const nftContract = await NFTContract.deploy(
    await ethers.provider.getSigner()
  );
  await nftContract.deploymentTransaction()?.wait();
  const nftContractAddress = await nftContract.getAddress();
  console.log("NFT contract deployed to: ", nftContractAddress);

  // Write deployed address to file
  writeAddresses(
    Number((await ethers.provider.getNetwork()).chainId.toString()),
    {
      ronixAddress: ronixAddress,
      stakingAddress: stakingAddress,
      collateralAddress: collateralAddress,
      l2NftAddress: nftContractAddress
    }
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
