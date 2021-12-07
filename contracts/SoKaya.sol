// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol';
import 'OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/utils/math/Math.sol';

import './KayaCenter.sol';
import './WithGovernor.sol';
import '../interfaces/IKaya.sol';

contract SoKaya is Initializable, WithGovernor {
  struct Distribution {
    mapping(address => uint) powers;
    mapping(address => uint) prevKayaPerPowers;
    uint nowKayaPerPower;
    uint inflation;
  }

  struct User {
    uint value;
    uint until;
    address game;
    uint claimable;
  }

  IKaya public kaya;
  KayaCenter public center;

  Distribution public distGame;
  Distribution public distUser;

  uint public totalPower;
  uint public lastTick;

  mapping(address => User) users;

  event Lock(address indexed user, uint value, uint8 commitment, uint morePower);
  event Unlock(address indexed user, uint value, uint lessPower);
  event Vote(address indexed user, address indexed game);
  event Claim(address indexed user, uint value);
  event SetInflation(uint gameInflation, uint userInflation);

  /// @dev Makes sure tick() is called.
  modifier withTick() {
    tick();
    _;
  }

  /// @dev Initializes the SoKaya smart contract with the corrent Kaya Center.
  function initialize(
    KayaCenter _center,
    address _gov,
    uint _gameInflation,
    uint _userInflation
  ) external initializer {
    center = _center;
    kaya = _center.kaya();
    distGame.inflation = _gameInflation;
    distUser.inflation = _userInflation;
    emit SetInflation(_gameInflation, _userInflation);
    initialize__WithGovernor(_gov);
  }

  /// @dev Returns user distribution information of a particular user.
  function getUserDistribution(address user)
    external
    view
    returns (uint power, uint prevKayaPerPower)
  {
    return (distUser.powers[user], distUser.prevKayaPerPowers[user]);
  }

  /// @dev Returns game distribution information of a particular game.
  function getGameDistribution(address game)
    external
    view
    returns (uint power, uint prevKayaPerPower)
  {
    return (distGame.powers[game], distGame.prevKayaPerPowers[game]);
  }

  /// @dev Update inflation parameters.
  /// @param _gameInflation The new game inflation value.
  /// @param _gameInflation The new user inflation value.
  function setInflation(uint _gameInflation, uint _userInflation) external withTick onlyGov {
    distGame.inflation = _gameInflation;
    distUser.inflation = _userInflation;
    emit SetInflation(_gameInflation, _userInflation);
  }

  /// @dev Locks KAYA tokens to earn soKAYA tokens. Newly earned tokens must be delegated.
  /// @param value The value of KAYA tokens to lock up.
  /// @param commitment The time commitment enum. Existing locked tokens will also be affected.
  /// @param game (First lock only) The address to delegate soKAYA power to.
  function lock(
    uint value,
    uint8 commitment,
    address game
  ) external withTick {
    _lock(value, commitment, game);
  }

  /// @dev Similar to lock functionality, but with an addtional permit call.
  function lockWithPermit(
    uint value,
    uint8 commitment,
    address game,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external withTick {
    kaya.permit(msg.sender, address(this), type(uint).max, deadline, v, r, s);
    _lock(value, commitment, game);
  }

  function _lock(
    uint value,
    uint8 commitment,
    address game
  ) internal {
    require(kaya.transferFrom(msg.sender, address(this), value));
    User storage user = users[msg.sender];
    if (user.game == address(0)) {
      require(game != address(0) && center.isGame(game), '!game');
      user.game = game;
      emit Vote(msg.sender, game);
    } else {
      require(game == address(0) || game == user.game, '!game');
    }
    user.value += value;
    user.until += Math.max(user.until, block.timestamp + toLockTime(commitment));
    uint morePower = toLockMultiplier(commitment) * value;
    _flushGame(user.game);
    _flushUser(msg.sender);
    totalPower += morePower;
    distGame.powers[user.game] += morePower;
    distUser.powers[msg.sender] += morePower;
    emit Lock(msg.sender, value, commitment, morePower);
  }

  /// @dev Unlocks KAYA tokens back to the sender. Must already pass lock period.
  /// @param value The amount of tokens to unlock.
  function unlock(uint value) external withTick {
    User storage user = users[msg.sender];
    require(block.timestamp > user.until, '!until');
    uint allPower = distUser.powers[msg.sender];
    uint lessPower = Math.ceilDiv(allPower * value, user.value);
    user.value -= value;
    totalPower -= lessPower;
    _flushGame(user.game);
    _flushUser(msg.sender);
    distGame.powers[user.game] -= lessPower;
    distUser.powers[msg.sender] -= lessPower;
    emit Unlock(msg.sender, value, lessPower);
  }

  /// @dev Changes voting power allocation to a new game.
  /// @param game The game contract to switch voting power to.
  function vote(address game) external withTick {
    require(game != address(0) && center.isGame(game), '!game');
    User storage user = users[msg.sender];
    uint power = distUser.powers[msg.sender];
    _flushGame(user.game);
    _flushGame(game);
    distGame.powers[user.game] -= power;
    distGame.powers[game] += power;
    user.game = game;
    emit Vote(msg.sender, game);
  }

  /// @dev Claims all the claimable KAYA reward for the caller.
  function claim() external withTick {
    _flushUser(msg.sender);
    uint value = users[msg.sender].claimable;
    require(kaya.transfer(msg.sender, value));
    users[msg.sender].claimable -= value;
    emit Claim(msg.sender, value);
  }

  /// @dev Flushes KAYA rewards to multiple games.
  function flushGames(address[] calldata games) external withTick {
    for (uint idx = 0; idx < games.length; idx++) {
      _flushGame(games[idx]);
    }
  }

  /// @dev Triggers inflation logic to mint more KAYA and accumulate to the games and stakers.
  function tick() public {
    uint timePast = block.timestamp - lastTick;
    lastTick = block.timestamp;
    if (timePast == 0 || totalPower < 1e18) return;
    uint supply = kaya.totalSupply();
    uint kayaGame = (distGame.inflation * supply * timePast) / 1e18 / 365 days;
    uint kayaUser = (distUser.inflation * supply * timePast) / 1e18 / 365 days;
    if (kayaGame + kayaUser == 0) return;
    kaya.mint(address(this), kayaGame + kayaUser);
    distGame.nowKayaPerPower += (kayaGame * 1e12) / totalPower;
    distUser.nowKayaPerPower += (kayaUser * 1e12) / totalPower;
  }

  function _flushUser(address user) internal {
    users[user].claimable += _flush(distUser, user);
  }

  function _flushGame(address game) internal {
    center.reward(game, _flush(distGame, game));
  }

  function _flush(Distribution storage dist, address who) internal returns (uint) {
    uint diff = dist.nowKayaPerPower - dist.prevKayaPerPowers[who];
    uint pending = (diff * dist.powers[who]) / 1e12;
    dist.prevKayaPerPowers[who] = dist.nowKayaPerPower;
    return pending;
  }

  /// @dev Given the commitment enum value, returns the duration of lock time in seconds.
  /// @param commitment The commitment value to query.
  function toLockTime(uint8 commitment) public pure returns (uint) {
    if (commitment == 0) return 7 days;
    if (commitment == 1) return 30 days;
    if (commitment == 2) return 180 days;
    if (commitment == 3) return 365 days;
    if (commitment == 4) return 730 days;
    if (commitment == 5) return 1461 days;
    require(false, '!commitment');
  }

  /// @dev Given the commitment enum value, returns the SoKaya multiplier.
  /// @param commitment The commitment value to query.
  function toLockMultiplier(uint8 commitment) public pure returns (uint) {
    if (commitment == 0) return 1;
    if (commitment == 1) return 2;
    if (commitment == 2) return 3;
    if (commitment == 3) return 5;
    if (commitment == 4) return 10;
    if (commitment == 5) return 20;
    require(false, '!commitment');
  }
}
