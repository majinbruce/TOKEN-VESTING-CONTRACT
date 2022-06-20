const { ethers } = require("hardhat");

async function main() {
  const totalSupply = 10000000;
  const TOKEN = await ethers.getContractFactory("MyToken");
  const token = await TOKEN.deploy(totalSupply);
  await token.deployed();

  console.log("\n token deployed at", token.address);

  const VESTING = await ethers.getContractFactory("vesting");
  const vesting = await VESTING.deploy(token.address);
  await vesting.deployed();

  console.log("\n VESTING deployed at", vesting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
