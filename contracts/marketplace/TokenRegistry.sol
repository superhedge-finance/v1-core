// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenRegistry is OwnableUpgradeable {
    /// @dev Events of the contract
    event TokenAdded(address token);
    event TokenRemoved(address token);

    /// @notice ERC20 Address -> Bool
    mapping(address => bool) public enabled;

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Method for adding payment token
     * @dev Only admin
     * @param token ERC20 token address
     */
    function add(address token) external onlyOwner {
        require(!enabled[token], "token already added");
        enabled[token] = true;
        emit TokenAdded(token);
    }

    /**
     * @notice Method for removing payment token
     * @dev Only admin
     * @param token ERC20 token address
     */
    function remove(address token) external onlyOwner {
        require(enabled[token], "token not exist");
        enabled[token] = false;
        emit TokenRemoved(token);
    }
}
