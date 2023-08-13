import { ethers } from "hardhat";

async function main() {
  const olameTokenAddress = "0x296d5bF623c2db0F54A373669E64D757C9A2e537";

  const AMM = await ethers.getContractFactory("AMM");
  const amm = await AMM.deploy(olameTokenAddress);

  await amm.deployed();

  console.log(
    `AMM contract deployed to ${amm.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/*
npx hardhat run scripts/deploy.ts --network alfajores
*/