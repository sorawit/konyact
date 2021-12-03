// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IKaya.sol";

interface IKayaCenter {
  function kaya() external view returns (IKaya);

  function notifyReward(uint256 value) external;

  //   function reward(uint256 value) external;
  // TODO
}
