// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract vesting is AccessControl, Ownable, ReentrancyGuard {
    bytes32 public constant ADVISOR = keccak256("Advisor");
    bytes32 public constant PARTNER = keccak256("Partner");
    bytes32 public constant MENTOR = keccak256("Mentor");

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 private immutable token;
    uint256 private immutable oneMonthInSeconds = 2629743;

    // role => address of role owner => total available tokens
    mapping(bytes32 => mapping(address => uint256))
        private availableTokensPerRoleAndAddress;

    // benificiary => vesting schedule of the address
    mapping(address => VestingSchedule) public VestingSchedulePerAddress;

    struct VestingSchedule {
        address beneficiary;
        bytes32 role;
        bool isVested;
        uint256 cliff;
        uint256 duration;
        uint256 percentageOfTotalSupply;
        uint256 totalTokensReleased;
    }

    constructor(
        IERC20 _token,
        address advisor,
        address partner,
        address mentor
    ) {
        token = _token;
        _setupRole(ADVISOR, advisor);
        _setupRole(PARTNER, partner);
        _setupRole(ADVISOR, mentor);
    }

    function getVestingSchedule(address _beneficiary)
        public
        view
        returns (VestingSchedule memory)
    {
        return VestingSchedulePerAddress[_beneficiary];
    }

    function createVestingSchedule(
        address _beneficiary,
        bytes32 _role,
        uint256 _cliff,
        uint256 _duration,
        uint256 _percentageOfTotalSupply
    ) public onlyOwner {
        _setupRole(_role, _beneficiary);
    }
}
