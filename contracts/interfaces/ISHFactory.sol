// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libraries/DataTypes.sol";

interface ISHFactory {
    function createProduct(
        string memory _name,
        string memory _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _exWallet,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle memory _issuanceCycle,
        address _router,
        address _market        
    ) external;
    
    function numOfProducts() external view returns (uint256);

    function isProduct(address _product) external view returns (bool);

    function getProduct(string memory _name) external view returns (address);
}
