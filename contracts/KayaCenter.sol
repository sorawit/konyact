// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./Kaya.sol";
import "./KayaGame.sol";
import "./WithGovernor.sol";
import "../interfaces/IKaya.sol";
import "../interfaces/IKayaCenter.sol";

contract KayaCenter is Initializable, WithGovernor, IKayaCenter {
  event Deposit(address indexed user, address indexed game, uint256 value);
  event Withdraw(address indexed user, address indexed game, uint256 value);
  event Reward(address indexed game, uint256 value);

  IKaya public kaya;
  address public cfo;
  mapping(address => bool) public isGame;

  function initialize(IKaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    cfo = _gov;
    initialize__WithGovernor(_gov);
  }

  function add(string memory name, string memory uri) external onlyGov {
    KayaGame game = new KayaGame(name, uri);
    isGame[address(game)] = true;
  }

  function edit(
    address game,
    string memory name,
    string memory uri
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).edit(name, uri);
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

  function withdraw(
    address game,
    address to,
    uint256 value
  ) external {
    require(msg.sender == cfo, "!cfo");
    require(isGame[game], "!game");
    KayaGame(game).withdraw(to, value);
  }

  function sos(
    address game,
    address to,
    bytes memory data
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).sos(to, data);
  }

  function notifyReward(uint256 value) external {
    require(isGame[msg.sender], "!game");
    emit Reward(msg.sender, value);
  }

  function _deposit(address game, uint256 value) internal {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(msg.sender, game, value);
  }
}
