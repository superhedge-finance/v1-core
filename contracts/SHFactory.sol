// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ISHFactory.sol";
import "./interfaces/ISHTokenFactory.sol";
import "./libraries/DataTypes.sol";
import "./SHProduct.sol";

/**
* @notice Factory contract to create new products
*/
contract SHFactory is ISHFactory, Ownable2StepUpgradeable, UUPSUpgradeable {

   /// @notice Mapping from product name to product address
   mapping(string productName => address productAddress) public getProduct;
   /// @notice Boolean check if an address is a product
   mapping(address productAddress => bool isProduct) public isProduct;
   address public tokenFactory;
   /// @notice Event emitted when new product is created
   event ProductCreated(
       address indexed product,
       string name,
       string underlying,
       uint256 maxCapacity
   );

   /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
   function initialize(address _tokenFactory) external initializer {
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
       tokenFactory = _tokenFactory;
   }

   /**
    * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    * {upgradeTo} and {upgradeToAndCall}.
    */
   function _authorizeUpgrade(address) internal override onlyOwner {}

   /**
    * @notice Function to create new product(vault)
    * @param _name is the product name
    * @param _underlying is the underlying asset label
    * @param _currency principal asset, USDC address
    * @param _manager manager of the product
    * @param _exWallet is the wallet address of exWallet
    * @param _maxCapacity is the maximum USDC amount that this product can accept
    * @param _issuanceCycle is the struct variable with issuance date,
       maturiy date, coupon, strike1 and strke2
    */

    // IERC20Upgradeable _currency,
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
   ) external onlyOwner {
       require(getProduct[_name] == address(0), "Product already exists");

       // create new product contract
       SHProduct product = new SHProduct();
       address productAddr = address(product);
       
       address _tokenAddress= ISHTokenFactory(tokenFactory).createToken("NoteToken", "NT",productAddr, IERC20MetadataUpgradeable(address(_currency)).decimals());

       address _currencyAddress = address(_currency);

       product.initialize(
           _name,
           _underlying,
           _currency,
           _manager,
           _exWallet,
           _maxCapacity,
           _issuanceCycle,
           _router,
           _market,
           _tokenAddress,
           _currencyAddress
       );

       getProduct[_name] = productAddr;
       isProduct[productAddr] = true;

       emit ProductCreated(productAddr, _name, _underlying, _maxCapacity);
   }
}
