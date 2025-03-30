// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../libraries/DataTypes.sol";

interface ISHProduct {
    function name() external view returns (string memory);

    function maxCapacity() external view returns (uint256);

    function shNFT() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdrawPrincipal() external;

    function paused() external view returns (bool);

    function status() external view returns (DataTypes.Status);

    function updateName(string memory _name) external;

    function updateParameters(string memory _name, DataTypes.IssuanceCycle memory _issuanceCycle, address _router, address _market) external;
}
