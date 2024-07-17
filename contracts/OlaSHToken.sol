// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SHToken is ERC20,AccessControl {
    uint8 private constant _decimals = 6;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    constructor(string memory _name, string memory _symbol,address _account) 
    ERC20(_name, _symbol) {
        grantRole(MINTER_ROLE, _account);
    }

    function mintToken(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount * (10 ** _decimals));
    }

    function burnToken(address from, uint256 amount) external onlyRole(MINTER_ROLE)  {
        _burn(from, amount);
    }
}