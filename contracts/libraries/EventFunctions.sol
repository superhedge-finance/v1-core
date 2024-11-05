// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EventFunctions {
    event Deposit(
        address indexed _user,
        uint256 _amount,
        uint256 _supply
    );

    event WithdrawPrincipal(
        address indexed _user,
        uint256 _amount
    );

    event WithdrawCoupon(
        address indexed _user,
        uint256 _amount
    );

    event WithdrawOption(
        address indexed _user,
        uint256 _amount
    );

    event RedeemOptionPayout(
        address indexed _from,
        uint256 _amount
    );

    event DistributeFunds(
        address indexed _exWallet,
        uint256 _optionRate,
        address indexed _pendleRouter,
        uint8 _yieldRate
    );
    
    event RedeemYield(
        address _pendleRouter,
        uint256 _amount
    );

    event EarlyWithdraw(
        address indexed _user,
        uint256 _noOfBlock, 
        uint256 _exactPtIn, 
        uint256 _earlyWithdrawUser
    );

    event UserOptionPositionPaid(uint256 totalOptionPosition);

    /// @notice Event emitted when new issuance cycle is updated
    event UpdateParameters(
        string _name,
        address _router, 
        address _market
    );

    event UpdateStructure(
        uint256 _strikePrice1,
        uint256 _strikePrice2,
        uint256 _strikePrice3,
        uint256 _strikePrice4,
        uint256 _tr1,
        uint256 _tr2,
        string _apy,
        uint8 _underlyingSpotRef
    );

    event FundAccept(
        uint256 _optionProfit,
        uint256 _timestamp
    );

    event FundLock(
        uint256 _timestamp
    );

    event Issuance(
        uint256 _timestamp
    );

    event Mature(
        uint256 _timestamp
    );
    
    event Coupon(
        address indexed _user,
        uint256 _amount
    );

    event OptionPayout(
        address indexed _user,
        uint256 _amount
    );

    event UpdateCoupon(
        uint256 _newCoupon
    );
}