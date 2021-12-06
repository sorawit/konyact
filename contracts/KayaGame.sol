// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IKaya.sol";
import "../interfaces/IKayaCenter.sol";
import "../interfaces/IKayaGame.sol";

contract KayaGame is IKayaGame {
  IKaya public immutable kaya;
  address public immutable controller;

  string public name;
  string public uri;
  uint16 public baseFee; // base exchange fee for GM in bps

  /// @dev Initializes the smart contract with the initial state values.
  constructor(
    string memory _name,
    string memory _uri,
    uint16 _baseFee
  ) {
    kaya = IKaya(IKayaCenter(msg.sender).kaya());
    controller = msg.sender;
    name = _name;
    uri = _uri;
    baseFee = _baseFee;
  }

  /// @dev Edits the name and uri of this game contract.
  /// @param _name The new name to update, or "" if do-not-modify.
  /// @param _uri The new uri to update, or "" if do-not-modify.
  /// @param _baseFee The new exchange fee bps to update.
  function edit(
    string memory _name,
    string memory _uri,
    uint16 _baseFee
  ) external {
    require(msg.sender == controller, "!controller");
    if (bytes(_name).length > 0) {
      name = _name;
    }
    if (bytes(_uri).length > 0) {
      uri = _uri;
    }
    baseFee = _baseFee;
  }

  /// @dev Withdraws KAYA tokens to the target address. Must be called by the controller.
  /// @param to The address to send KAYA tokens to.
  /// @param value The size of KAYA tokens to send.
  function withdraw(address to, uint256 value) external {
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
