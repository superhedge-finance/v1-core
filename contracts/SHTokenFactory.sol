// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "./interfaces/ISHTokenFactory.sol";
import "./SHToken.sol";

contract SHTokenFactory is ISHTokenFactory {
    /// @notice Emitted when a new token is created
    /// @param tokenAddress The address of the newly created token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param creator The address of the token creator
    event TokenCreated(address indexed tokenAddress, string name, string symbol, address creator);

    /// @notice Creates a new token with the specified name and symbol
    /// @dev Deploys a new SHToken contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param _owner The address that will own the new token
    /// @return The address of the newly created token
    function createToken(string memory name, string memory symbol, address _owner) external returns (address) {
        SHToken newToken = new SHToken(name, symbol, _owner);
        emit TokenCreated(address(newToken), name, symbol, _owner);
        return address(newToken);
    }
}
