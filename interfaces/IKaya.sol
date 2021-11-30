// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/IERC20.sol";

interface IKaya is IERC20 {
  function mint(address to, uint256 amount) external;
}
