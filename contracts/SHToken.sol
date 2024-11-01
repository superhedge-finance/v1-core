// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SHToken is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address[] private users;
    mapping(address => uint256) private userBalances;

    constructor(string memory _name, string memory _symbol, address product) ERC20(_name, _symbol) {
        _grantRole(MINTER_ROLE, product);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        _updateUserBalance(to, amount, true);
    }

    function burn(address account, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(account) >= amount, "Insufficient balance");
        _burn(account, amount);
        _updateUserBalance(account, amount, false);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        super.transfer(recipient, amount);
        _updateUserBalance(msg.sender, amount, false);
        _updateUserBalance(recipient, amount, true);
        return true;
    }

    function _updateUserBalance(address user, uint256 amount, bool isAdd) internal {
        if (amount > 0 && userBalances[user] == 0) {
            users.push(user);
        }
        
        if (isAdd) {
            userBalances[user] = userBalances[user].add(amount);
        } else {
            require(userBalances[user] >= amount, "Insufficient balance");
            userBalances[user] = userBalances[user].sub(amount);
        }

        if (userBalances[user] == 0) {
            deleteUserFromArray(user);
        }
    }

    function deleteUserFromArray(address user) internal {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) {
                users[i] = users[users.length - 1];
                users.pop();
                break;
            }
        }
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }
}