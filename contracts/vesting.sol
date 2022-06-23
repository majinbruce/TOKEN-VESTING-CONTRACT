// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract vesting is Ownable, ReentrancyGuard {
    bytes32 public constant ADVISOR = keccak256("Advisor");
    bytes32 public constant PARTNER = keccak256("Partner");
    bytes32 public constant MENTOR = keccak256("Mentor");

    using SafeERC20 for IERC20;

    IERC20 private immutable token;
    uint256 private immutable oneMonthInSeconds = 2629743;
    uint256 private immutable oneDayInSeconds = 86400;

    // role => address of role owner => total available tokens
    mapping(bytes32 => mapping(address => uint256))
        public availableTokensPerRoleAndAddress;

    // benificiary => vesting schedule of the address
    mapping(bytes32 => mapping(address => VestingSchedule))
        public VestingSchedulePerRoleAndAddress;
    // tracks available token percentage per role
    mapping(bytes32 => uint256) public availableTokenPercentagePerRole;

    struct VestingSchedule {
        address beneficiary;
        bytes32 role;
        bool isVested;
        uint256 createVestingScheduleTime;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 percentageOfTotalSupply;
        uint256 totalTokensReleased;
        uint256 lastClaim;
    }

    event vestingScheduleCreated(
        address beneficiary,
        bytes32 role,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 percentageOfTotalSupply
    );

    event tokensReleased(
        address beneficiary,
        bytes32 role,
        uint256 amountOfTokensClaimed
    );

    constructor(IERC20 _token) {
        token = _token;
        availableTokenPercentagePerRole[ADVISOR] = 3;
        availableTokenPercentagePerRole[PARTNER] = 5;
        availableTokenPercentagePerRole[MENTOR] = 4;
    }

    function getCreatedSchedule(string memory _role, address beneficiary)
       external
        view
        returns (VestingSchedule memory)
    {
        bytes32 roleinString = getRoleInBytesFromString(_role);
        return VestingSchedulePerRoleAndAddress[roleinString][beneficiary];
    }

    function calculateTotalTokensReleased(uint256 _percentageOfTotalSupply)
        public
        view
        returns (uint256)
    {
        return (token.totalSupply() * (_percentageOfTotalSupply)) / (100);
    }

    function getRoleInBytesFromString(string memory _role)
       public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_role));
    }

    function preVestingScheduleValidation(
        address _beneficiary,
        bytes32 _roleInBytes,
        uint256 _percentageOfTotalSupply
    ) internal view {
        VestingSchedule
            storage vestingSchedule = VestingSchedulePerRoleAndAddress[
                _roleInBytes
            ][_beneficiary];

        require(
            !vestingSchedule.isVested,
            "VESTING : tokens for this address and role already vested"
        );
        require(
            _beneficiary != address(0x00),
            "VESTING: benificiary cannot be 0 address"
        );

        require(
            _roleInBytes == ADVISOR ||
                _roleInBytes == PARTNER ||
                _roleInBytes == MENTOR,
            "VESTING: enter correct role"
        );

        require(
            _percentageOfTotalSupply <=
                availableTokenPercentagePerRole[_roleInBytes],
            "VESTING: cannot allocate entered percentage of tokens for this role"
        );
    }

    function convertFromMonthToSeconds(uint256 _time)
        internal 
        pure
        returns (uint256)
    {
        return _time * (oneMonthInSeconds);
    }

    function createVestingSchedule(
        address _beneficiary,
        string memory _role,
        uint256 _startInMonths,
        uint256 _cliffInMonths,
        uint256 _durationInMonths,
        uint256 _percentageOfTotalSupply
    ) external onlyOwner {
        bytes32 _roleInBytes = getRoleInBytesFromString(_role);

        preVestingScheduleValidation(
            _beneficiary,
            _roleInBytes,
            _percentageOfTotalSupply
        );

        uint256 _totalTokensReleased = calculateTotalTokensReleased(
            _percentageOfTotalSupply
        );

        // sets available Tokens per role & address
        availableTokensPerRoleAndAddress[_roleInBytes][
            _beneficiary
        ] = _totalTokensReleased;

        // update available percentace per role
        availableTokenPercentagePerRole[_roleInBytes] =
            availableTokenPercentagePerRole[_roleInBytes] -
            _percentageOfTotalSupply;

        uint256 createVestingScheduleTime = block.timestamp;
        uint256 startInSeconds = createVestingScheduleTime +
            convertFromMonthToSeconds(_startInMonths);
        uint256 cliffInSeconds = convertFromMonthToSeconds(_cliffInMonths) +
            startInSeconds;
        uint256 durationInSeconds = convertFromMonthToSeconds(
            _durationInMonths
        ) + (cliffInSeconds);

        // create schedule in mapping
        VestingSchedulePerRoleAndAddress[_roleInBytes][
            _beneficiary
        ] = VestingSchedule(
            _beneficiary,
            _roleInBytes,
            true,
            createVestingScheduleTime,
            startInSeconds,
            cliffInSeconds,
            durationInSeconds,
            _percentageOfTotalSupply,
            _totalTokensReleased,
            0
        );

        emit vestingScheduleCreated(
            _beneficiary,
            _roleInBytes,
            startInSeconds,
            cliffInSeconds,
            durationInSeconds,
            _percentageOfTotalSupply
        );
    }

    function calculateTimeElapsed(bytes32 _roleInBytes, address _beneficiary)
       internal
        view
        returns (uint256)
    {
        VestingSchedule
            storage vestingSchedule = VestingSchedulePerRoleAndAddress[
                _roleInBytes
            ][_beneficiary];

        uint256 timeElapsed;
        uint256 currentTime = block.timestamp;

        if (vestingSchedule.lastClaim == 0) {
            timeElapsed = currentTime - vestingSchedule.cliff;
        } else {
            timeElapsed = currentTime - vestingSchedule.lastClaim;
        }

        return (timeElapsed);
    }

    function prereleaseVestedTokensValidation(
        address _beneficiary,
        bytes32 _roleInBytes
    ) internal  view {
        VestingSchedule
            storage vestingSchedule = VestingSchedulePerRoleAndAddress[
                _roleInBytes
            ][_beneficiary];

        require(
            vestingSchedule.lastClaim == 0 ||
                vestingSchedule.lastClaim <=
                block.timestamp - vestingSchedule.lastClaim,
            "VESTING : you can only claim tokens every 24hours"
        );
        require(
            vestingSchedule.isVested,
            "VESTING : tokens for this address and role are not vested"
        );

        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "VESTING: only beneficiary and owner can claim vested tokens"
        );

        require(
            _roleInBytes == ADVISOR ||
                _roleInBytes == PARTNER ||
                _roleInBytes == MENTOR,
            "VESTING: enter correct role"
        );

        require(block.timestamp >= vestingSchedule.cliff);
    }

    function releaseVestedTokens(
        address _beneficiary,
        string memory _roleInString
    ) external {
        bytes32 _roleInBytes = getRoleInBytesFromString(_roleInString);

        VestingSchedule
            storage vestingSchedule = VestingSchedulePerRoleAndAddress[
                _roleInBytes
            ][_beneficiary];

        prereleaseVestedTokensValidation(_beneficiary, _roleInBytes);

        uint256 timeElapsedSinceClaim = calculateTimeElapsed(
            _roleInBytes,
            _beneficiary
        );
        require(
            timeElapsedSinceClaim > oneDayInSeconds,
            "VESTING: YOU CANNOT CLAIM TOKENS WITHIN 24 HOURS"
        );
        uint256 totalVestingTime = vestingSchedule.duration -
            vestingSchedule.cliff;

        uint256 tokensToRelease = (vestingSchedule.totalTokensReleased *
            (timeElapsedSinceClaim)) / (totalVestingTime);

        require(
            availableTokensPerRoleAndAddress[_roleInBytes][_beneficiary] >=
                tokensToRelease,
            "VESTING: you claimed all your tokens bro"
        );

        // update mapping
        availableTokensPerRoleAndAddress[_roleInBytes][_beneficiary] =
            availableTokensPerRoleAndAddress[_roleInBytes][_beneficiary] -
            tokensToRelease;
        // update lastclaim timestamp in mapping
        VestingSchedulePerRoleAndAddress[_roleInBytes][_beneficiary]
            .lastClaim = block.timestamp;

        token.safeTransfer(_beneficiary, tokensToRelease);
        emit tokensReleased(_beneficiary, _roleInBytes, tokensToRelease);
    }
}
