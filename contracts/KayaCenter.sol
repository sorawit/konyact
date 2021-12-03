// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./KayaGame.sol";
import "./WithGovernor.sol";
import "../interfaces/IKaya.sol";
import "../interfaces/IKayaCenter.sol";

contract KayaCenter is Initializable, WithGovernor, IKayaCenter {
  event SetCfo(address indexed cfo);
  event NewGame(address indexed game, string name, string uri);
  event EditGame(address indexed game, string name, string uri);
  event Deposit(address indexed game, address indexed user, uint256 value);
  event Withdraw(address indexed game, address indexed user, uint256 value);
  event Reward(address indexed game, uint256 value);

  IKaya public kaya;
  address public cfo;
  mapping(address => bool) public isGame;

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

  /// @dev Adds a new game to the ecosystem. The game will be able to earn KAYA rewards.
  /// @param name The name of the newly added game.
  /// @param uri The uri of the newly added game.
  function add(string memory name, string memory uri) external onlyGov returns (address) {
    address game = address(new KayaGame(name, uri));
    isGame[game] = true;
    emit NewGame(game, name, uri);
    return game;
  }

  /// @dev Edits the information of an existing game.
  /// @param game The address of the game contract to edit.
  /// @param name The name to edit to.
  /// @param uri The uri to edit to.
  function edit(
    address game,
    string memory name,
    string memory uri
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).edit(name, uri);
    emit EditGame(address(game), name, uri);
  }

  /// @dev Deposits KAYA into the given game.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  function deposit(address game, uint256 value) external {
    _deposit(game, value);
  }

  /// @dev Deposits KAYA into the given game using EIP-2612 permit to permit for max int.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  /// @param deadline The deadline for EIP-2616 permit parameter.
  /// @param v Part of permit signature.
  /// @param r Part of permit signature.
  /// @param s Part of permit signature.
  function depositWithPermit(
    address game,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _deposit(game, value);
  }

  /// @dev Internal function to process KAYA deposits to games.
  /// @param game The game address to deposit KAYA to.
  /// @param value The size of KAYA to deposit.
  function _deposit(address game, uint256 value) internal {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(game, msg.sender, value);
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
