// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./interfaces/ISHProduct.sol";
import "./libraries/DataTypes.sol";

contract ParameterUpdater {
    address public manager;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Not a manager");
        _;
    }

    function updateParameters(
        address productAddress,
        string calldata _name,
        DataTypes.IssuanceCycle calldata _issuanceCycle,
        address _router,
        address _market
    ) external onlyManager {
        ISHProduct product = ISHProduct(productAddress);

        require(_issuanceCycle.issuanceDate > block.timestamp, "ID bigger");
        require(_issuanceCycle.maturityDate > _issuanceCycle.issuanceDate, "MT bigger");

        require(_issuanceCycle.tr1 <= 100000 && _issuanceCycle.tr1 >= 0, "Less than 100000 or greater than 0");
        require(_issuanceCycle.tr2 <= 100000 && _issuanceCycle.tr2 >= 0, "Less than 100000 or greater than 0");

        require(bytes(_issuanceCycle.apy).length >= 2 && bytes(_issuanceCycle.apy).length <= 12, "Error apy length");

        require(_issuanceCycle.strikePrice1 <= 1000000 && _issuanceCycle.strikePrice1 >= 0, "Less than 1000000 or greater than 0");
        require(_issuanceCycle.strikePrice2 <= 1000000 && _issuanceCycle.strikePrice2 >= 0, "Less than 1000000 or greater than 0");
        require(_issuanceCycle.strikePrice3 <= 1000000 && _issuanceCycle.strikePrice3 >= 0, "Less than 1000000 or greater than 0");
        require(_issuanceCycle.strikePrice4 <= 1000000 && _issuanceCycle.strikePrice4 >= 0, "Less than 1000000 or greater than 0");

        product.updateParameters(_name, _issuanceCycle, _router, _market);
    }
} 