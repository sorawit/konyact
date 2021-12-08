// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './KayaCenter.sol';
import '../interfaces/IKaya.sol';

contract KayaReserve {
  address public commander;
  KayaCenter public center;
  IKaya public kaya;

  constructor(KayaCenter _center) {
    commander = msg.sender;
    center = _center;
    kaya = _center.kaya();
    kaya.approve(address(center), type(uint).max);
  }

  function send(address to, uint value) external {
    require(msg.sender == commander, '!commander');
    require(kaya.transfer(to, value));
  }

  function reward(address game, uint value) external {
    require(msg.sender == commander, '!commander');
    center.reward(game, value);
  }
}
