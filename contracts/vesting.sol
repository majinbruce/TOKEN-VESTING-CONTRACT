// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract vesting is AccessControl {
    bytes32 public constant Advisor = keccak256("Advisor");
    bytes32 public constant Partnerships = keccak256("Partnerships");
    bytes32 public constant Mentorsr = keccak256("Mentorsr");

    using SafeERC20 for IERC20;
    IERC20 private token;

    constructor(IERC20 _token) {}
}
