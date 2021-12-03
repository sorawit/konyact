// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/utils/Initializable.sol";

contract WithGovernor is Initializable {
  address public gov;
  address public pendingGov;

  event AcceptGov(address gov);
  event SetPendingGov(address gov);

  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  function initialize__WithGovernor(address _gov) internal initializer {
    require(_gov != address(0), "!gov");
    gov = _gov;
    emit AcceptGov(_gov);
  }

  /// @dev Updates the address to become the new governor after it accepts.
  /// @param _pendingGov The new pending governor address.
  function setPendingGov(address _pendingGov) external onlyGov {
    pendingGov = _pendingGov;
    emit SetPendingGov(_pendingGov);
  }

  /// @dev Called by the pending governor to become the governor.
  function acceptGov() external {
    require(msg.sender == pendingGov, "!pendingGov");
    pendingGov = address(0);
    gov = msg.sender;
    emit AcceptGov(msg.sender);
  }
}
