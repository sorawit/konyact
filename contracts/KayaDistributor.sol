// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./WithGovernor.sol";
import "../interfaces/IKaya.sol";
import "../interfaces/IKayaGame.sol";

contract KayaDistributor is Initializable, WithGovernor {
  IKaya public kaya;
  address public soKaya;

  uint256 public accKayaPerPower;
  uint256 public totalPower;

  uint256 public inflation;
  uint256 public lastTick;

  mapping(address => uint256) public powers;
  mapping(address => uint256) public prevKayaPerPowers;

  function initialize(IKaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    initialize__WithGovernor(_gov);
  }

  function setSoKaya() external {
    require(soKaya == address(0), "!setSoKaya");
    soKaya = msg.sender;
  }

  function setInflation(uint256 _inflation) external onlyGov {
    require(_inflation <= 1e18, "!inflation");
    tick();
    inflation = _inflation;
  }

  function increasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower += power;
    powers[game] += power;
  }

  function decreasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower -= power;
    powers[game] -= power;
  }

  function transferPower(
    address src,
    address dst,
    uint256 power
  ) external {
    require(msg.sender == soKaya, "!SoKaya");
    require(src != dst, "!transfer");
    tick();
    flush(src);
    flush(dst);
    powers[src] -= power;
    powers[dst] += power;
  }

  function tick() public {
    uint256 timePast = block.timestamp - lastTick;
    lastTick = block.timestamp;
    if (timePast > 0 && inflation > 0 && totalPower > 1e18) {
      uint256 value = (kaya.totalSupply() * inflation * timePast) / 1e18 / 365 days;
      kaya.mint(address(this), value);
      accKayaPerPower += (value * 1e12) / totalPower;
    }
  }

  function flush(address game) public {
    uint256 dist = ((accKayaPerPower - prevKayaPerPowers[game]) * powers[game]) / 1e12;
    prevKayaPerPowers[game] = accKayaPerPower;
    if (dist > 0) {
      kaya.approve(game, dist);
      IKayaGame(game).reward(dist);
    }
  }
}
