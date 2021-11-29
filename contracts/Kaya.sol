pragma solidity 0.8.9;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Kaya is ERC20PresetMinterPauser("Kaya Token", "KAYA"), ERC20Permit("BETA") {
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
    ERC20PresetMinterPauser._beforeTokenTransfer(from, to, amount);
  }
}
