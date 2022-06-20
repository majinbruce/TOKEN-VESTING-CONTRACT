const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber");

describe("Staking", () => {
  let owner;
  let addr1;
  let addr2;

  let token;
  let TOKEN;
  let totalSupply = 1000000000;

  let VESTING;
  let vesting;

  beforeEach(async () => {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Deploy the Token contract.
    TOKEN = await ethers.getContractFactory("MyToken");
    token = await TOKEN.deploy(totalSupply);
    await token.deployed();

    // Deploy the VESTING contract.
    VESTING = await ethers.getContractFactory("vesting");
    vesting = await VESTING.deploy(token.address);
    await vesting.deployed();

    //give vesting contract total supply
    await token.transfer(vesting.address, totalSupply);
  });

  describe("schedule Vesting", async function () {
    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await token.balanceOf(vesting.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });

    it("should let owner create a vesting schedule", async function () {
      const _beneficiary = addr1.address;
      const _role = "Advisor";
      const _startInMonths = 0;
      const _cliffInMonths = 1;
      const _durationInMonths = 1;
      const _percentageOfTotalSupply = 2;

      await vesting.createVestingSchedule(
        _beneficiary,
        _role,
        _startInMonths,
        _cliffInMonths,
        _durationInMonths,
        _percentageOfTotalSupply
      );

      const _roleInBytes = await vesting.getRoleInBytesFromString(_role);
      const _totalTokensReleased = await vesting.calculateTotalTokensReleased(
        _percentageOfTotalSupply
      );

      // correct amount of tokens are released
      expect(await _totalTokensReleased).to.equal(20000000);

      // token mapping is set correctly
      const tokenMapping = vesting.availableTokensPerRoleAndAddress(
        _roleInBytes,
        _beneficiary
      );
      expect(await tokenMapping).to.equal(_totalTokensReleased);

      const tokenPercentage = await vesting.availableTokenPercentagePerRole(
        _roleInBytes
      );
      // percentage per role mapping is set correctly
      expect(await tokenPercentage).to.equal(1);

      const vestingschedule = await vesting.VestingSchedulePerRoleAndAddress(
        _roleInBytes,
        _beneficiary
      );

      expect(await vestingschedule.isVested).to.equal(true);

      const tokenBalanceBefore = await token.balanceOf(addr1.address);

      // increase evm time BY A MONTH AND A DAY
      await ethers.provider.send("evm_increaseTime", [2629743 + 86401]);

      await vesting.releaseVestedTokens(_beneficiary, _role);

      const tokenBalanceAfter = await token.balanceOf(addr1.address);
      expect(tokenBalanceBefore).to.not.equal(tokenBalanceAfter);

      await ethers.provider.send("evm_increaseTime", [100]);

      await expect(
        vesting.releaseVestedTokens(_beneficiary, _role)
      ).to.be.revertedWith("VESTING : you can only claim tokens every 24hours");
    });
  });

  describe("schedule Vesting validation", async function () {
    it("should throw correct errors while scheduling vesting", async function () {
      const _beneficiary = addr1.address;
      const _role = "Advisor";
      const _startInMonths = 1;
      const _cliffInMonths = 1;
      const _durationInMonths = 22;
      const _percentageOfTotalSupply = 2;

      await expect(
        vesting.createVestingSchedule(
          _beneficiary,
          _role,
          _startInMonths,
          _cliffInMonths,
          _durationInMonths,
          100
        )
      ).to.be.revertedWith(
        "VESTING: cannot allocate entered percentage of tokens for this role"
      );

      await expect(
        vesting.createVestingSchedule(
          _beneficiary,
          "SastaAdvisor",
          _startInMonths,
          _cliffInMonths,
          _durationInMonths,
          _percentageOfTotalSupply
        )
      ).to.be.revertedWith("VESTING: enter correct role");

      // tokens for same role & benificiary are not assigned twice

      // first create a schedule
      await vesting.createVestingSchedule(
        _beneficiary,
        _role,
        _startInMonths,
        _cliffInMonths,
        _durationInMonths,
        _percentageOfTotalSupply
      );

      // expect error here
      await expect(
        vesting.createVestingSchedule(
          _beneficiary,
          _role,
          _startInMonths,
          _cliffInMonths,
          _durationInMonths,
          _percentageOfTotalSupply
        )
      ).to.be.revertedWith(
        "VESTING : tokens for this address and role already vested"
      );
    });
  });
});
