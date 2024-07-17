// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISHToken {

    function mintToken(address to, uint256 amount) external ;
    function burnToken(address to, uint256 amount) external ;

}