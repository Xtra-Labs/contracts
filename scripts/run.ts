import { ethers } from "hardhat";

const main = async () => {
  const [owner] = await ethers.getSigners();
  const supplyLenderContractFactory = await ethers.getContractFactory(
    "SupplyLending"
  );
  const supplyLenderContract = await supplyLenderContractFactory.deploy();
  await supplyLenderContract.deployed();

  console.log("SupplyLending deployed to:", supplyLenderContract.address);

};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
