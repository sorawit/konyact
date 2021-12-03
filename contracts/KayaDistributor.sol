// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./WithGovernor.sol";
import "../interfaces/IKaya.sol";
import "../interfaces/IKayaGame.sol";
import "../interfaces/IKayaCenter.sol";

contract KayaDistributor is Initializable, WithGovernor {
  IKaya public kaya;
  IKayaCenter public center;
  address public soKaya;

  uint256 public accKayaPerPower;
  uint256 public totalPower;

  uint256 public inflation;
  uint256 public lastTick;

  mapping(address => uint256) public powers;
  mapping(address => uint256) public prevKayaPerPowers;

  function initialize(IKayaCenter _center, address _gov) external initializer {
    kaya = _center.kaya();
    center = _center;
    kaya.approve(address(center), type(uint256).max);
    lastTick = block.timestamp;
    initialize__WithGovernor(_gov);
  }

  /// @dev Initializes SoKAYA address to the invoker. Can and must only be called once.
  function setSoKaya() external {
    require(soKaya == address(0), "!setSoKaya");
    soKaya = msg.sender;
  }

  /// @dev Updates inflation rate per year imposed on KAYA for game distribution.
  /// @param _inflation Inflation rate per year, multiplied by 1e18.
  function setInflation(uint256 _inflation) external onlyGov {
    require(_inflation <= 1e18, "!inflation");
    tick();
    inflation = _inflation;
  }

  /// @dev Increases allocation power to the given game. Must be called by SoKAYA.
  /// @param game The game contract address to add power.
  /// @param power The power to increase.
  function increasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower += power;
    powers[game] += power;
  }

  /// @dev Decreases allocation power from the given game. Must be called by SoKAYA.
  /// @param game The game contract address to reduct power.
  /// @param power The power to decrease.
  function decreasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower -= power;
    powers[game] -= power;
  }

  /// @dev Transfers allocation power from one game to another. Must be called by SoKAYA.
  /// @param src The game contract address to move allocation from.
  /// @param dst The game contract address to send allocation to.
  /// @param power The power to decrease.
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

  /// @dev Triggers inflation logic to mint more KAYA and accumulate to the games.
  function tick() public {
    uint256 timePast = block.timestamp - lastTick;
    lastTick = block.timestamp;
    if (timePast > 0 && inflation > 0 && totalPower > 1e18) {
      uint256 value = (kaya.totalSupply() * inflation * timePast) / 1e18 / 365 days;
      kaya.mint(address(this), value);
      accKayaPerPower += (value * 1e12) / totalPower;
    }
  }

  /// @dev Flushes KAYA rewards to a specific game.
  /// @param game The game contract address to flush rewards to.
  function flush(address game) public {
    uint256 dist = ((accKayaPerPower - prevKayaPerPowers[game]) * powers[game]) / 1e12;
    prevKayaPerPowers[game] = accKayaPerPower;
    if (dist > 0) {
      center.reward(game, dist);
    }
  }
}
