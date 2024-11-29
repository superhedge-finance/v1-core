// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title SHToken Contract
/// @notice This contract is an ERC20 token with minting and burning capabilities.
/// @dev Inherits from OpenZeppelin's ERC20 and AccessControl contracts.
contract SHToken is ERC20, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint8 public constant DECIMALS = 6;

    /// @notice Constructor to initialize the token with a name, symbol, and product address.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _product The address that will be granted minter and burner roles.
    constructor(string memory _name, string memory _symbol, address _product) ERC20(_name, _symbol) {
        _grantRole(MINTER_ROLE, _product);
        _grantRole(BURNER_ROLE, _product);
    }

    /// @notice Mints tokens to a specified address.
    /// @dev Only accounts with the MINTER_ROLE can call this function.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified account.
    /// @dev Only accounts with the BURNER_ROLE can call this function.
    /// @param account The account from which tokens will be burned.
    /// @param amount The amount of tokens to burn.
    function burn(address account, uint256 amount) external onlyRole(BURNER_ROLE) {
        require(amount > 0, "Amount must be greater than zero");
        _burn(account, amount);
    }

    /// @notice Returns the number of decimals used to get its user representation.
    /// @return The number of decimals.
    function decimals() public pure virtual override returns (uint8) {
        return DECIMALS;
    }

    /// @notice Transfers tokens to a specified address.
    /// @dev Overrides the ERC20 transfer function to include additional checks.
    /// @param recipient The address to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        super.transfer(recipient, amount);
        return true;
    }

}