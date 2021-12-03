// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/utils/math/Math.sol";

import "./KayaCenter.sol";
import "./KayaDistributor.sol";
import "../interfaces/IKaya.sol";

struct User {
  uint256 value;
  uint256 until;
  address game;
}

contract SoKaya is Initializable {
  IKaya public kaya;
  KayaDistributor public dist;
  KayaCenter public center;

  mapping(address => User) public users;
  mapping(address => uint256) public balanceOf;

  event Lock(address indexed user, uint256 value, uint8 commitment);
  event Unlock(address indexed user, uint256 value);
  event Vote(address indexed user, address indexed game);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @dev Initializes the SoKaya smart contract with the corrent Kaya Center.
  function initialize(KayaCenter _center, KayaDistributor _dist) external initializer {
    center = _center;
    kaya = _center.kaya();
    dist = _dist;
    dist.setSoKaya();
  }

  /// @dev Returns the name of soKAYA token.
  function name() public view returns (string memory) {
    return "Super Owner of KAYA";
  }

  /// @dev Returns the symbol of soKAYA token.
  function symbol() public view returns (string memory) {
    return "soKAYA";
  }

  /// @dev Locks KAYA tokens to earn soKAYA tokens. Newly earned tokens must be delegated.
  /// @param value The value of KAYA tokens to lock up.
  /// @param commitment The time commitment enum. Existing locked tokens will also be affected.
  /// @param game (First lock only) The address to delegate soKAYA power to.
  function lock(
    uint256 value,
    uint8 commitment,
    address game
  ) external {
    _lock(value, commitment, game);
  }

  /// @dev Similar to lock functionality, but with an addtional permit call.
  function lockWithPermit(
    uint256 value,
    uint8 commitment,
    address game,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _lock(value, commitment, game);
  }

  function _lock(
    uint256 value,
    uint8 commitment,
    address game
  ) internal {
    require(kaya.transferFrom(msg.sender, address(this), value));
    User storage user = users[msg.sender];
    if (user.game == address(0)) {
      require(game != address(0) && center.isGame(game), "!game");
      user.game = game;
      emit Vote(msg.sender, game);
    } else {
      require(game == address(0) || game == user.game, "!game");
    }
    user.value += value;
    user.until += Math.max(user.until, block.timestamp + toLockTime(commitment));
    uint256 morePower = toLockMultiplier(commitment) * value;
    dist.increasePower(user.game, msg.sender, morePower);
    balanceOf[msg.sender] += morePower;
    emit Lock(msg.sender, value, commitment);
    emit Transfer(address(0), msg.sender, morePower);
  }

  /// @dev Unlocks KAYA tokens back to the sender. Must already pass lock period.
  /// @param value The amount of tokens to unlock.
  function unlock(uint256 value) external {
    User storage user = users[msg.sender];
    require(block.timestamp > user.until, "!until");
    uint256 lessPower = Math.ceilDiv(balanceOf[msg.sender] * value, user.value);
    user.value -= value;
    dist.decreasePower(user.game, msg.sender, lessPower);
    balanceOf[msg.sender] -= lessPower;
    emit Unlock(msg.sender, value);
    emit Transfer(msg.sender, address(0), lessPower);
  }

  /// @dev Change voting power allocation to a new game.
  /// @param game The game contract to switch voting power to.
  function vote(address game) external {
    require(game != address(0) && center.isGame(game), "!game");
    User storage user = users[msg.sender];
    uint256 power = balanceOf[msg.sender];
    dist.transferPower(user.game, game, power);
    user.game = game;
    emit Vote(msg.sender, game);
  }

  /// @dev Given the commitment enum value, returns the duration of lock time in seconds.
  /// @param commitment The commitment value to query.
  function toLockTime(uint8 commitment) public pure returns (uint256) {
    if (commitment == 0) return 7 days;
    if (commitment == 1) return 30 days;
    if (commitment == 2) return 182 days;
    if (commitment == 3) return 365 days;
    if (commitment == 4) return 730 days;
    if (commitment == 5) return 1461 days;
    require(false, "!commitment");
  }

  /// @dev Given the commitment enum value, returns the SoKaya multiplier.
  /// @param commitment The commitment value to query.
  function toLockMultiplier(uint8 commitment) public pure returns (uint256) {
    if (commitment == 0) return 1;
    if (commitment == 1) return 2;
    if (commitment == 2) return 3;
    if (commitment == 3) return 5;
    if (commitment == 4) return 10;
    if (commitment == 5) return 20;
    require(false, "!commitment");
  }
}
