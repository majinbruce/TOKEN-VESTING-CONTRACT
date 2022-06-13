// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

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
    mapping(bytes32 => mapping(address => VestingSchedule))
        public VestingSchedulePerRoleAndAddress;

    struct VestingSchedule {
        address beneficiary;
        bytes32 role;
        bool isVested;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 percentageOfTotalSupply;
        uint256 totalTokensReleased;
    }

    constructor(IERC20 _token) {
        token = _token;
    }

    function getVestingSchedule(string memory _role, address _beneficiary)
        public
        view
        returns (VestingSchedule memory)
    {
        bytes32 _roleInBytes = getRole(_role);
        return VestingSchedulePerRoleAndAddress[_roleInBytes][_beneficiary];
    }

    function calculateTotalTokensReleased(uint256 _percentageOfTotalSupply)
        private
        view
        returns (uint256)
    {}

    function validateClaimVestedTokens() private view {}

    function claimVestedTokens() public view {}

    function getRole(string memory _role) public pure returns (bytes32) {
        return keccak256(abi.encode(_role));
    }

    function validateVestingSchedule() private {}

    function createVestingSchedule(
        address _beneficiary,
        string memory _role,
        uint256 _startInMonths,
        uint256 _cliffInMonths,
        uint256 _durationInMonths,
        uint256 _percentageOfTotalSupply
    ) external onlyOwner {
        bytes32 _roleInBytes = getRole(_role);

        uint256 _totalTokensReleased = calculateTotalTokensReleased(
            _percentageOfTotalSupply
        );

        // create schedule in mapping
        VestingSchedulePerRoleAndAddress[_roleInBytes][
            _beneficiary
        ] = VestingSchedule(
            _beneficiary,
            _roleInBytes,
            true,
            _startInMonths,
            _cliffInMonths,
            _durationInMonths,
            _percentageOfTotalSupply,
            _totalTokensReleased
        );
    }
}
