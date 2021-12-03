// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IKaya.sol";

interface IKayaCenter {
  function kaya() external view returns (IKaya);

  function isGame(address game) external view returns (bool);

  function reward(address game, uint256 value) external;
}
