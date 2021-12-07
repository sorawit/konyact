// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract KayaProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
