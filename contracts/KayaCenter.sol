// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./KayaGame.sol";
import "./WithGovernor.sol";
import "../interfaces/IKaya.sol";
import "../interfaces/IKayaCenter.sol";

contract KayaCenter is Initializable, WithGovernor, IKayaCenter {
  event SetCfo(address cfo);
  event SetKayaFee(uint16 kayaFee);
  event NewGame(address indexed game, string name, string uri, uint16 baseFee);
  event EditGame(address indexed game, string name, string uri, uint16 baseFee);
  event Deposit(address indexed game, address indexed user, uint256 value, string memo);
  event Withdraw(address indexed game, address indexed user, uint256 value);
  event Reward(address indexed game, uint256 value);

  IKaya public kaya;
  address public cfo;
  uint16 public kayaFee;

  mapping(address => bool) public isGame;
  address[] public games;

  function initialize(IKaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    cfo = _gov;
    initialize__WithGovernor(_gov);
  }

  /// @dev Sets the address that is authorized to initiate withdrawal from any games.
  /// @param _cfo The address to become the CFO.
  function setCfo(address _cfo) external onlyGov {
    cfo = _cfo;
    emit SetCfo(_cfo);
  }

  /// @dev Sets the global trading fee for KAYA ecosystem that applies to all games.
  /// @param _kayaFee The bps value to become new kaya fee.
  function setKayaFee(uint16 _kayaFee) external onlyGov {
    kayaFee = _kayaFee;
    emit SetKayaFee(_kayaFee);
  }

  /// @dev Returns the total number of games in the system.
  function gameLength() external view returns (uint256) {
    return games.length;
  }

  /// @dev Adds a new game to the ecosystem. The game will be able to earn KAYA rewards.
  /// @param name The name of the newly added game.
  /// @param uri The uri of the newly added game.
  /// @param baseFee The base trading fee bps of the newly added game.
  function add(
    string memory name,
    string memory uri,
    uint16 baseFee
  ) external onlyGov returns (address) {
    address game = address(new KayaGame(name, uri, baseFee));
    isGame[game] = true;
    games.push(game);
    emit NewGame(game, name, uri, baseFee);
    return game;
  }

  /// @dev Edits the information of an existing game.
  /// @param game The address of the game contract to edit.
  /// @param name The name to edit to.
  /// @param uri The uri to edit to.
  /// @param baseFee The base fee to edit to.
  function edit(
    address game,
    string memory name,
    string memory uri,
    uint16 baseFee
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).edit(name, uri, baseFee);
    emit EditGame(address(game), name, uri, baseFee);
  }

  /// @dev Deposits KAYA into the given game.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  /// @param memo Extra data for deposit.
  function deposit(
    address game,
    uint256 value,
    string memory memo
  ) external {
    _deposit(game, value, memo);
  }

  /// @dev Deposits KAYA into the given game using EIP-2612 permit to permit for max int.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  /// @param memo Extra data for deposit.
  /// @param deadline The deadline for EIP-2616 permit parameter.
  /// @param v Part of permit signature.
  /// @param r Part of permit signature.
  /// @param s Part of permit signature.
  function depositWithPermit(
    address game,
    uint256 value,
    string memory memo,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _deposit(game, value, memo);
  }

  /// @dev Internal function to process KAYA deposits to games.
  /// @param game The game address to deposit KAYA to.
  /// @param value The size of KAYA to deposit.
  function _deposit(
    address game,
    uint256 value,
    string memory memo
  ) internal {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(game, msg.sender, value, memo);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param value TODO
  function withdraw(
    address game,
    address to,
    uint256 value
  ) external {
    require(msg.sender == cfo, "!cfo");
    require(isGame[game], "!game");
    KayaGame(game).withdraw(to, value);
    emit Withdraw(game, to, value);
  }

  /// @dev Adds more KAYA reward to the game. Can technically be called by anyone.
  /// @param game The game contract to reward.
  /// @param value The size of KAYA tokens to add as rewards.
  function reward(address game, uint256 value) external {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value));
    emit Reward(game, value);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param data TODO
  function sos(
    address game,
    address to,
    bytes memory data
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).sos(to, data);
  }
}
