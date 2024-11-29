// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ISHTokenFactory {

    /**
     * @notice Creates a new token with the specified name and symbol.
     * @dev This function is used to create a new token and assign an owner.
     * @param name The name of the token to be created.
     * @param symbol The symbol of the token to be created.
     * @param owner The address that will own the newly created token.
     * @return The address of the newly created token.
     */
    function createToken(string memory name, string memory symbol, address owner) external returns (address);

}