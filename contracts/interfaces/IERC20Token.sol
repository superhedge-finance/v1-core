// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC20Token {
    function mint(address to, uint256 amount) external;
    function burn(address account,uint256 amount) external;
}