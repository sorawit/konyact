// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IKayaCenter.sol";
import "../interfaces/IKayaGame.sol";

contract KayaGame is IKayaGame {
  IERC20 public immutable kaya;
  address public immutable controller;

  /// @dev Initializes the smart contract with the initial state values.
  /// @param _kaya The KAYA token smart contract address.
  constructor(IERC20 _kaya) {
    kaya = _kaya;
    controller = msg.sender;
  }

  /// @dev Adds more KAYA reward to the game. Can technically be called by anyone.
  /// @param value The size of KAYA tokens to add as rewards.
  function reward(uint256 value) external {
    require(kaya.transferFrom(msg.sender, address(this), value));
    IKayaCenter(controller).notifyReward(value);
  }

  /// @dev Withdraws KAYA tokens to the target address. Must be called by the controller.
  /// @param to The address to send KAYA tokens to.
  /// @param value The size of KAYA tokens to send.
  function withdrawTo(address to, uint256 value) external {
    require(msg.sender == controller, "!controller");
    require(kaya.transfer(to, value), "!transfer");
  }

  /// @dev Called by controller to ask this contract to any action. Primarily for recovering
  /// lost assets, whether in the forms of ERC20, ERC721, ERC1155, punks, or any other standard
  /// that get accidietnally sent to this contract.
  /// @param to The contract address to execute the acton.
  /// @param data The data attached the call.
  function sos(address to, bytes memory data) external payable {
    require(msg.sender == controller, "!controller");
    (bool ok, ) = to.call{ value: msg.value }(data);
    require(ok, "!ok");
  }
}
