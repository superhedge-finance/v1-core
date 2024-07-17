// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20Token {
    function mint(address to, uint256 amount) external;
    function burn(address to, uint256 amount) external;
    function checkBalanceOf(address account) external view returns (uint256);
}