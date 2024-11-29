// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libraries/DataTypes.sol";

interface ISHFactory {
    /**
     * @notice Creates a new product with the specified parameters.
     * @param _name The name of the product.
     * @param _underlying The underlying asset of the product.
     * @param _currency The currency in which the product is denominated.
     * @param _manager The address of the product manager.
     * @param _exWallet The address of the ex wallet.
     * @param _maxCapacity The maximum capacity of the product.
     * @param _issuanceCycle The issuance cycle details of the product.
     * @param _router The address of the router.
     * @param _market The address of the market.
     */
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

    /**
     * @notice Returns the number of products created.
     * @return The total number of products.
     */
    function numOfProducts() external view returns (uint256);

    /**
     * @notice Checks if the given address is a product.
     * @param _product The address to check.
     * @return True if the address is a product, false otherwise.
     */
    function isProduct(address _product) external view returns (bool);

    /**
     * @notice Retrieves the product address by its name.
     * @param _name The name of the product.
     * @return The address of the product.
     */
    function getProduct(string memory _name) external view returns (address);
}
