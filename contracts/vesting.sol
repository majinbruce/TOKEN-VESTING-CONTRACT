// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract vesting is AccessControl, Ownable, ReentrancyGuard {
    bytes32 public constant ADVISOR = keccak256("Advisor");
    bytes32 public constant PARTNER = keccak256("Partner");
    bytes32 public constant MENTOR = keccak256("Mentor");

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 private immutable token;

    // role => address of role owner => total available tokens
    mapping(bytes32 => mapping(address => uint256))
        private availableTokensPerRoleAndAddress;

    struct VestingSchedule {
        address beneficiary;
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
        require(_token != address(0x0));
        token = _token;
        _setupRole(ADVISOR, advisor);
        _setupRole(PARTNER, partner);
        _setupRole(ADVISOR, mentor);
    }

    function createVestingSchedule(
        address _beneficiary,
        uint256 _cliff,
        uint256 _duration,
        uint256 _percentageOfTotalSupply
    ) {}
}
