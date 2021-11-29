pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/utils/math/Math.sol";

struct Data {
  uint256 value;
  uint256 until;
  address delegate;
}

contract SoKaya is ERC20("Super Owner of KAYA", "SoKaya") {
  IERC20 public kaya;
  mapping(address => Data) public users;
  mapping(address => uint256) public powers;

  function lock(uint256 value, uint256 commitment) external {
    require(kaya.transferFrom(msg.sender, address(this), value));
    Data storage user = users[msg.sender];
    user.value += value;
    user.until += Math.max(user.until, block.timestamp + toLockTime(commitment));
    uint256 morePower = toLockMultiplier(commitment) * value;
    _mint(msg.sender, morePower);
    powers[user.delegate] += morePower;
  }

  function unlock(uint256 value) external {
    Data storage user = users[msg.sender];
    require(block.timestamp > user.until, "!until");
    uint256 lessPower = Math.ceilDiv(balanceOf(msg.sender) * value, user.value);
    user.value -= value;
    powers[user.delegate] -= lessPower;
    _burn(msg.sender, lessPower);
    require(kaya.transfer(msg.sender, value));
  }

  function vote(address guy) external {
    Data storage user = users[msg.sender];
    uint256 power = balanceOf(msg.sender);
    powers[user.delegate] -= power;
    user.delegate = guy;
    powers[user.delegate] += power;
  }

  function toLockTime(uint256 commitment) public pure returns (uint256) {
    if (commitment == 0) return 7 days;
    if (commitment == 1) return 30 days;
    if (commitment == 2) return 182 days;
    if (commitment == 3) return 365 days;
    if (commitment == 4) return 730 days;
    if (commitment == 5) return 1461 days;
    require(false, "!commitment");
  }

  function toLockMultiplier(uint256 commitment) public pure returns (uint256) {
    if (commitment == 0) return 1;
    if (commitment == 1) return 2;
    if (commitment == 2) return 3;
    if (commitment == 3) return 5;
    if (commitment == 4) return 10;
    if (commitment == 5) return 20;
    require(false, "!commitment");
  }
}
