const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BlazeToken", () => {
  const tokenName = "MyToken";
  const tokenSymbol = "MTKN";
  const tokenSupply = 10000;

  let owner;
  let MYTOKEN;
  let mytoken;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    MYTOKEN = await ethers.getContractFactory("MyToken");
    mytoken = await MYTOKEN.deploy(tokenSupply);
    await mytoken.deployed();
  });

  it("Sets correct name and symbol", async () => {
  });

  it("Sets correct initial supply", async () => {
    const totalSupply = await mytoken.totalSupply();
    expect(totalSupply).to.equal(tokenSupply);
  });

  it("Mints all tokens to owner", async () => {
    const ownerBalance = await mytoken.balanceOf(owner.address);
    const totalSupply = await mytoken.totalSupply();
    expect(ownerBalance).to.equal(totalSupply);
  });
});
