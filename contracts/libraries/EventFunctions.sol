// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title EventFunctions Contract
/// @notice This contract defines a set of events for tracking various actions and states within a financial system.
contract EventFunctions {

    /// @notice Emitted when funds are accepted.
    event FundAccept();

    /// @notice Emitted when funds are locked.
    event FundLock();

    /// @notice Emitted when an issuance occurs.
    event Issuance();

    /// @notice Emitted when maturity is reached.
    event Mature();

    /// @notice Emitted when a deposit is made.
    /// @param user The address of the user making the deposit.
    /// @param amount The amount deposited.
    event Deposit(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when the principal is withdrawn.
    /// @param user The address of the user withdrawing the principal.
    /// @param amount The amount withdrawn.
    event WithdrawPrincipal(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when a coupon is withdrawn.
    /// @param user The address of the user withdrawing the coupon.
    /// @param amount The amount withdrawn.
    event WithdrawCoupon(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when an option is withdrawn.
    /// @param user The address of the user withdrawing the option.
    /// @param amount The amount withdrawn.
    event WithdrawOption(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when an option payout is redeemed.
    /// @param from The address from which the payout is redeemed.
    /// @param amount The amount redeemed.
    event RedeemOptionPayout(
        address indexed from,
        uint256 amount
    );

    /// @notice Emitted when funds are distributed.
    /// @param qredoDeribit The address of the Qredo Deribit.
    /// @param optionRate The rate of the option.
    /// @param pendleRouter The address of the Pendle Router.
    /// @param yieldRate The yield rate.
    event DistributeFunds(
        address indexed qredoDeribit,
        uint256 optionRate,
        address indexed pendleRouter,
        uint32 yieldRate
    );
    
    /// @notice Emitted when yield is redeemed.
    /// @param pendleRouter The address of the Pendle Router.
    /// @param amount The amount redeemed.
    event RedeemYield(
        address pendleRouter,
        uint256 amount
    );

    /// @notice Emitted when an early withdrawal is made.
    /// @param user The address of the user making the withdrawal.
    /// @param noOfBlock The number of blocks.
    /// @param exactPtIn The exact point in.
    /// @param earlyWithdrawUser The early withdrawal user.
    event EarlyWithdraw(
        address indexed user,
        uint256 noOfBlock, 
        uint256 exactPtIn, 
        uint256 earlyWithdrawUser
    );

    /// @notice Emitted when a user's option position is paid.
    /// @param totalOptionPosition The total option position paid.
    event UserOptionPositionPaid(uint256 totalOptionPosition);

    /// @notice Emitted when new issuance cycle parameters are updated.
    /// @param name The name of the issuance cycle.
    /// @param router The address of the router.
    /// @param market The address of the market.
    event UpdateParameters(
        string name,
        address router, 
        address market
    );

    /// @notice Emitted when the structure is updated.
    /// @param strikePrice1 The first strike price.
    /// @param strikePrice2 The second strike price.
    /// @param strikePrice3 The third strike price.
    /// @param strikePrice4 The fourth strike price.
    /// @param tr1 The first tr value.
    /// @param tr2 The second tr value.
    /// @param apy The annual percentage yield.
    /// @param underlyingSpotRef The underlying spot reference.
    event UpdateStructure(
        uint256 strikePrice1,
        uint256 strikePrice2,
        uint256 strikePrice3,
        uint256 strikePrice4,
        uint256 tr1,
        uint256 tr2,
        string apy,
        uint8 underlyingSpotRef
    );
    
    /// @notice Emitted when a coupon is issued.
    /// @param user The address of the user receiving the coupon.
    /// @param amount The amount of the coupon.
    event Coupon(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when an option payout is made.
    /// @param user The address of the user receiving the payout.
    /// @param amount The amount of the payout.
    event OptionPayout(
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when the coupon is updated.
    /// @param newCoupon The new coupon value.
    event UpdateCoupon(
        uint256 newCoupon
    );

    /// @notice Emitted when a list of option profits is added.
    /// @param userList The list of user addresses.
    /// @param amountList The list of amounts corresponding to each user.
    event AddOptionProfitList(
        address[] userList,
        uint256[] amountList
    );

    /// @notice Emitted when an account is whitelisted.
    /// @param account The address of the account.
    event WhiteList(
        address indexed account
    );

    /// @notice Emitted when an account is removed from the whitelist.
    /// @param account The address of the account.
    event RemoveFromWhiteList(
        address indexed account
    );

    /// @notice Emitted when an admin is added.
    /// @param account The address of the admin account.
    event AddAdmin(
        address indexed account
    );
}

