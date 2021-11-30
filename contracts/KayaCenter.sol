// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

import "./Kaya.sol";
import "../interfaces/IKayaCenter.sol";

struct KayaGame {
  uint256 value;
}

contract KayaCenter is Initializable, IKayaCenter {
  event Deposit(address indexed user, address indexed game, uint256 value);
  event Withdraw(address indexed user, address indexed game, uint256 value);
  event Reward(address indexed game, uint256 value);

  Kaya public kaya;
  address public gov;
  address public pendingGov;
  address public cfo;

  // mapping (address => KayaGame)
  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  function initialize(Kaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    gov = _gov;
    cfo = _gov;
  }

  function setPendingGov(address _pendingGov) external onlyGov {
    pendingGov = _pendingGov;
  }

  function acceptGov() external {
    require(msg.sender == pendingGov, "!pendingGov");
    pendingGov = address(0);
    gov = msg.sender;
  }

  function add() external {
    // TODO
  }

  function isGame(address game) external view returns (bool) {
    return false;
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
    // TODO
  }

  function notifyReward(uint256 value) external {
    // TODO
  }

  function _deposit(address game, uint256 value) internal {
    // require game
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(msg.sender, game, value);
  }
}
