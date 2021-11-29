pragma solidity 0.8.9;

import "./Kaya.sol";

struct KayaGame {
  uint256 value;
}

contract KayaCenter {
  event Deposit(address indexed user, address indexed game, uint256 value);

  Kaya public immutable kaya;

  // mapping (address => KayaGame)

  constructor(Kaya _kaya) {
    kaya = _kaya;
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
    // TODO
  }

  function reward() external {
    // TODO
  }

  function _deposit(address game, uint256 value) internal {
    // require game
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(msg.sender, game, value);
  }
}
