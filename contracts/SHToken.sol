// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SHToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory _name, string memory _symbol, address product) ERC20(_name, _symbol) {
        _grantRole(MINTER_ROLE, product);
    }

    function mint(address to, uint256 amount) onlyRole(MINTER_ROLE) external  {
        // require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) onlyRole(MINTER_ROLE) external {
        _spendAllowance(to, msg.sender, amount);
        _burn(to, amount);
    }

    function decimals() override public view virtual returns (uint8) {
        return 6;
    }

    function checkBalanceOf(address account) external view returns (uint256) {
        return IERC20(address(this)).balanceOf(account);
    }



}
