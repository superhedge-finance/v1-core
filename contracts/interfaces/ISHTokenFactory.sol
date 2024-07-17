// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISHTokenFactory {

    function createToken(string memory name, string memory symbol, address owner) external  returns (address);

}