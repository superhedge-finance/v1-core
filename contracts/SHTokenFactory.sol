// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "./interfaces/ISHTokenFactory.sol";
import "./SHToken.sol";

contract SHTokenFactory is ISHTokenFactory {
    event TokenCreated(address indexed tokenAddress, string name, string symbol, address creator);

    function createToken(string memory name, string memory symbol, address _owner) external returns (address) {
        SHToken newToken = new SHToken(name, symbol, _owner);
        emit TokenCreated(address(newToken), name, symbol, _owner);
        return address(newToken);
    }
}
