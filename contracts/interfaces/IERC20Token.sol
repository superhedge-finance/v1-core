// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC20Token {
    /**
     * @notice Mints a specified amount of tokens to a given address.
     * @dev This function should be called by an authorized account.
     * @param to The address to which the minted tokens will be sent.
     * @param amount The number of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns a specified amount of tokens from a given account.
     * @dev This function should be called by an authorized account.
     * @param account The address from which the tokens will be burned.
     * @param amount The number of tokens to burn.
     */
    function burn(address account, uint256 amount) external;
}