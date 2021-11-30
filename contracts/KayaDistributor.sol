// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

interface ISoKaya {
  function kaya() external view returns (IERC20);
}

contract KayaDistributor is Initializable {
  address public soKaya;
  IERC20 public kaya;

  uint256 public accKayaPerPower;
  uint256 public totalPower;

  mapping(address => uint256) public powers;
  mapping(address => uint256) public prevKayaPerPowers;

  function initialize(IERC20 _kaya) external initializer {
    kaya = _kaya;
  }

  function setSoKaya() external {
    require(soKaya == address(0), "!setSoKaya");
    soKaya = msg.sender;
  }

  function inject(uint256 value) external {
    require(totalPower > 1e18, "!power");
    require(kaya.transferFrom(msg.sender, address(this), value));
    accKayaPerPower += (value * 1e12) / totalPower;
  }

  function increasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    flush(game);
    totalPower += power;
    powers[game] += power;
  }

  function decreasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
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
    flush(src);
    flush(dst);
    powers[src] -= power;
    powers[dst] += power;
  }

  function flush(address game) public {
    uint256 dist = ((accKayaPerPower - prevKayaPerPowers[game]) * powers[game]) / 1e12;
    prevKayaPerPowers[game] = accKayaPerPower;
    if (dist > 0) {
      kaya.approve(game, dist);
      // TODO: reward
    }
  }
}
