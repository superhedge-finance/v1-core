// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import "./StructGen.sol";
import "./interfaces/IERC20Token.sol";
import "./libraries/DataTypes.sol";
import "./libraries/EventFunctions.sol";
import "./ParameterUpdater.sol";


/**
 * @title SHProduct
 * @notice A structured product contract that manages deposits, withdrawals, and yield generation
 * @dev Inherits from StructGen, ReentrancyGuardUpgradeable, PausableUpgradeable, and EventFunctions
 */
contract SHProduct is StructGen,ReentrancyGuardUpgradeable,PausableUpgradeable,EventFunctions {

    IPPrincipalToken public PT;
    IPYieldToken public YT;
    IPAllActionV3 public router;
    address public currencyAddress;
    IPMarket public market;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public netPtOut;

    struct UserInfo {
        uint256 coupon;
        uint256 optionPayout;
    }

    struct UserOptionPosition {
        address userAddress;
        uint256 value;
    }

    string public name;
    string public underlying;

    address public manager;
    address public shFactory;
    address public tokenAddress;
    address public admin;

    address public exWallet;

    uint256 public maxCapacity;
    uint256 public currentCapacity;
    uint256 public optionProfit;
    uint256 public totalOptionPosition;
    uint256 public totalNumberOfBlocks;
    address public fundContract;

    DataTypes.Status public status;
    DataTypes.IssuanceCycle public issuanceCycle;
    
    mapping(address => UserInfo) public userInfo;
    UserOptionPosition[] public UserOptionPositions;
    

    IERC20Upgradeable public currency;
    bool public isDistributed;

    mapping(address => bool) public whitelisted;

    ParameterUpdater public parameterUpdater;
   

    /**
     * @notice Initializes the contract
     * @param _name Product name
     * @param _underlying Underlying asset name
     * @param _currency Underlying asset token
     * @param _manager Manager address
     * @param _exWallet External wallet address
     * @param _maxCapacity Maximum capacity of the product
     * @param _issuanceCycle Issuance cycle parameters
     * @param _router Router address
     * @param _market Market address
     * @param _tokenAddress ERC20 token address
     * @param _currencyAddress Currency address
     */
    function initialize(
        string calldata _name,
        string calldata _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _exWallet,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle calldata _issuanceCycle,
        address _router,
        address _market,
        address _tokenAddress,
        address _currencyAddress
    ) external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        name = _name;
        underlying = _underlying;

        manager = _manager;
        exWallet = _exWallet;
        tokenAddress = _tokenAddress;
        maxCapacity = _maxCapacity;
        currency = _currency;
        currencyAddress = _currencyAddress;
        shFactory = msg.sender;
        require(_issuanceCycle.coupon <= 1000000 && _issuanceCycle.coupon >= 0, "Invalid coupon");
        require(_issuanceCycle.issuanceDate > block.timestamp, "Invalid issuance date");
        require(_issuanceCycle.maturityDate > _issuanceCycle.issuanceDate, "Invalid maturity date");
        
        issuanceCycle = _issuanceCycle;

        router = IPAllActionV3(_router);
        market = IPMarket(_market);
        (, PT,YT) = IPMarket(market).readTokens();
    }

    /**
     * @notice Modifier for functions restricted to whitelisted addresses
     */ 
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Only whitelisted");
        _;
    }

    /**
     * @notice Modifier for functions restricted to manager
     */
    modifier onlyManager() {
        require(msg.sender == manager, "Not a manager");
        _;
    }

    /**
     * @notice Modifier for functions restricted to the admin
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Accepted status
     */
    modifier onlyAccepted() {
        require(status == DataTypes.Status.Accepted, "Not accepted");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Locked status
     */
    modifier onlyLocked() {
        require(status == DataTypes.Status.Locked, "Not locked");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Issued status
     */
    modifier onlyIssued() {
        require(status == DataTypes.Status.Issued, "Not issued");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Mature status
     */
    modifier onlyMature() {
        require(status == DataTypes.Status.Mature, "Not mature");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Locked or Mature status
     */
    modifier LockedOrMature() {
        require(status == DataTypes.Status.Locked || status == DataTypes.Status.Mature, "Neither Locked nor Mature");
        _;
    }

    /**
     * @notice Modifier for functions restricted to products in Locked, Mature, or Accepted status
     */
    modifier AcceptedOrLockedOrMature() {
        require(status == DataTypes.Status.Locked || status == DataTypes.Status.Mature || status == DataTypes.Status.Accepted, "Neither Accepted nor Locked nor Mature");
        _;
    }

    /**
     * @notice Whitelists the additional accounts to call the automation functions.
     */
    function whitelist(address _account) external onlyManager {
        require(!whitelisted[_account], "Account is already whitelisted");
        whitelisted[_account] = true;
        emit WhiteList(_account);
    }

    /**
     * @notice Remove the additional callers from whitelist.
     */
    function removeFromWhitelist(address _account) external onlyManager {
        delete whitelisted[_account];
        emit RemoveFromWhiteList(_account);
    }

    /**
     * @notice Adds an admin to the contract
     * @param _account Address of the admin to add
     * @dev Only callable by manager
     */
    function addAdmin(address _account) external onlyManager {
        admin = _account;
        emit AddAdmin(_account);
    }

    /**
     * @notice Changes the product status to Accepted
     * @dev Only callable by whitelisted addresses when contract is not paused
     * @dev Product must be in Pending or Mature status
     */
    function fundAccept() external whenNotPaused onlyWhitelisted {
        require(status == DataTypes.Status.Pending || status == DataTypes.Status.Mature, "Invalid status");
        status = DataTypes.Status.Accepted;
        emit FundAccept();
    }

    /**
     * @notice Distributes option profits to a list of users
     * @param _userList Array of user addresses to receive profits
     * @param _amountList Array of amounts to distribute to each user
     * @dev Only callable by whitelisted addresses when contract is not paused and in Accepted status
     */
    function addOptionProfitList(address[] memory _userList, uint256[] memory _amountList) external whenNotPaused onlyMature onlyWhitelisted {
        uint256 _optionProfit = optionProfit;
        uint256 length = _userList.length;
        if (_optionProfit > 0) {
            for (uint256 i = 0; i < length; i++) {
                userInfo[_userList[i]].optionPayout += _amountList[i];
            }
            optionProfit = 0;
        }
        emit AddOptionProfitList(_userList, _amountList);
    }

    /**
     * @notice Changes the product status to Locked
     * @dev Only callable by whitelisted addresses when contract is not paused and in Accepted status
     */
    function fundLock() external whenNotPaused onlyAccepted onlyWhitelisted {
        status = DataTypes.Status.Locked;
        emit FundLock();
    }

    /**
     * @notice Changes the product status to Issued
     * @dev Only callable by whitelisted addresses when contract is not paused and in Locked status
     */
    function issuance() external whenNotPaused onlyLocked onlyWhitelisted {
        status = DataTypes.Status.Issued;
        emit Issuance();
    }

    /**
     * @notice Changes the product status to Mature
     * @dev Only callable by whitelisted addresses when contract is not paused and in Issued status
     */
    function mature() external whenNotPaused onlyIssued onlyWhitelisted {
        status = DataTypes.Status.Mature;
        emit Mature();
    }

    /**
     * @notice Updates users' coupon balances
     * @param _userList Array of user addresses to receive coupons
     * @param _amountList Array of coupon amounts to distribute
     * @dev Only callable by whitelisted addresses when contract is not paused and in Issued status
     */
    function coupon(address[] memory _userList, uint256[] memory _amountList) external whenNotPaused onlyIssued onlyWhitelisted{
        uint256 length = _userList.length;
        for (uint256 i = 0; i < length; i++) {
            userInfo[_userList[i]].coupon += _amountList[i];
            emit Coupon(
                    _userList[i],
                    _amountList[i]
                );
        }
    }

    /**
     * @notice Updates the coupon rate for the product
     * @param _newCoupon New weekly coupon rate in basis points (e.g., 10 = 0.10%/week)
     * @dev Only callable by manager when product is in Locked or Mature status
     * @dev Coupon rate must be between 0 and 100
     */
    function updateCoupon(
        uint256 _newCoupon
    ) external LockedOrMature onlyManager {
        require(_newCoupon <= 1000000 && _newCoupon >= 0, "Less than 0 or greater than 100");
        issuanceCycle.coupon = _newCoupon;

        emit UpdateCoupon(_newCoupon);
    }

    /**
     * @notice Updates all parameters for the next issuance cycle
     * @param _name New name for the product
     * @param _issuanceCycle New issuance cycle parameters
     * @param _router New router address
     * @param _market New market address
     * @dev Only callable by manager when product is in Accepted status
     */
    function updateParameters(string calldata _name, DataTypes.IssuanceCycle calldata _issuanceCycle,address _router,address _market) external AcceptedOrLockedOrMature onlyManager {
        parameterUpdater.updateParameters(address(this), _name, _issuanceCycle, _router, _market);
    }

    /**
     * @notice Deposits currency into the structured product and mints ERC20 tokens
     * @param _amount Amount of currency to deposit
     * @dev Only callable when contract is not paused and in Accepted status
     * @dev Amount must be greater than 0 and not exceed remaining capacity
     */
    function deposit(uint256 _amount) external nonReentrant whenNotPaused onlyAccepted {
        require(_amount > 0, "Greater zero");
        uint256 decimals = _currencyDecimals();
        require(decimals > 0, "Decimals");
        uint256 amountToDeposit = _amount;
        
        require((maxCapacity * 10 ** decimals) >= (currentCapacity + amountToDeposit), "Product is full");
        currentCapacity += amountToDeposit;
        
        currency.safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Token(tokenAddress).mint(msg.sender,_amount);

        emit Deposit(msg.sender, _amount);
    }


    /**
     * @notice Withdraws principal by burning product tokens
     * @dev Only callable when product is in Accepted status
     * @dev Burns user's entire token balance and returns equivalent currency
     */
    function withdrawPrincipal() external nonReentrant onlyAccepted {
        uint256 currentToken = IERC20(tokenAddress).balanceOf(msg.sender);
        IERC20Token(tokenAddress).burn(msg.sender,currentToken);
        currency.safeTransfer(msg.sender, currentToken);
        currentCapacity -= currentToken;

        emit WithdrawPrincipal(
            msg.sender, 
            currentToken
        );
    }

    /**
     * @notice Withdraws accumulated coupon payments
     * @dev Transfers all accumulated coupon payments to user
     * @dev Requires positive coupon balance and sufficient contract balance
     */
    function withdrawCoupon() external nonReentrant {
        uint256 _couponAmount = userInfo[msg.sender].coupon;
        require(_couponAmount > 0, "No coupon available");
        require(totalBalance() >= _couponAmount, "Insufficient contract balance");
        
        currency.safeTransfer(msg.sender, _couponAmount);
        userInfo[msg.sender].coupon = 0;

        emit WithdrawCoupon(msg.sender, _couponAmount);
    }

    /**
     * @notice Withdraws accumulated option payouts
     * @dev Transfers all accumulated option payouts to user
     * @dev Requires positive option payout balance and sufficient contract balance
     */
    function withdrawOption() external nonReentrant {
        uint256 _optionAmount = userInfo[msg.sender].optionPayout;
        require(_optionAmount > 0, "No option payout available");
        require(totalBalance() >= _optionAmount, "Insufficient contract balance");
        
        currency.safeTransfer(msg.sender, _optionAmount);
        userInfo[msg.sender].optionPayout = 0;

        emit WithdrawOption(msg.sender, _optionAmount);
    }

    /**
     * @notice Distributes locked funds between yield generation and options
     * @param _yieldRate Percentage of funds to allocate to yield generation (0-100)
     * @dev Only callable by manager when product is in Locked status
     * @dev Remaining percentage (100 - _yieldRate) goes to options wallet
     */
    function distributeFunds(uint32 _yieldRate) external onlyManager onlyLocked {
        require(!isDistributed, "Already distributed");
        require(_yieldRate <= 100_000_000, "Less than 100");
        isDistributed = true;
        uint32 optionRate = 100_000_000 - _yieldRate;
        uint256 optionAmount;
        if (optionRate > 0) {
            optionAmount = currentCapacity * optionRate / 100_000_000;
            currency.transfer(exWallet, optionAmount);
        }

        uint256 yieldAmount = currentCapacity - optionAmount;

        IERC20(currencyAddress).approve(address(router), yieldAmount);
        (uint256 _netPtOut,,) = router.swapExactTokenForPt(
            address(this), address(market), 0, defaultApprox, createTokenInputStruct(currencyAddress, yieldAmount), emptyLimit
        );
        netPtOut = _netPtOut;
        
        emit DistributeFunds(exWallet, optionRate, address(router), _yieldRate);
    }

    /**
     * @notice Redeems yield tokens from Pendle protocol
     * @dev Only callable by manager when product is in Mature status
     * @dev Requires funds to have been previously distributed
     */
    function redeemYield() external onlyManager onlyMature {
        require(isDistributed, "Not distributed");
        uint256 exactPtIn = IERC20(PT).balanceOf(address(this));
        uint256 netTokenOut;
        netPtOut = 0;
        isDistributed = false;
        if (exactPtIn > 0)
        {
            IERC20(PT).approve(address(router), exactPtIn);
            (netTokenOut,) = router.redeemPyToToken(address(this), address(YT), exactPtIn, createTokenOutputStruct(currencyAddress, 0)); 
        }
        
        emit RedeemYield(address(router), netTokenOut);
    }

    /**
     * @notice Allows users to withdraw funds early
     * @param _noOfBlock Number of blocks to withdraw early
     * @dev Only callable when product is in Issued status
     * @dev Burns corresponding tokens and returns proportional amount of underlying assets
     */
    function earlyWithdraw(uint256 _noOfBlock) external onlyIssued {
        uint256 exactPtIn = 0;
        uint256 decimals = _currencyDecimals();
        require(decimals > 0, "Decimals");
        uint256 earlyWithdrawUser = ((_noOfBlock * issuanceCycle.underlyingSpotRef) *(issuanceCycle.optionMinOrderSize * 10**(decimals)))/10; 
        uint256 currentToken = IERC20(tokenAddress).balanceOf(msg.sender);
        uint256 withdrawBlockSize = (issuanceCycle.underlyingSpotRef * 10**(decimals) * issuanceCycle.optionMinOrderSize)/10; 
        uint256 totalBlock = currentToken / withdrawBlockSize;
        require(totalBlock >= _noOfBlock, "Not enough blocks");

        exactPtIn  = (earlyWithdrawUser * netPtOut / currentCapacity);        
        totalNumberOfBlocks+=_noOfBlock;

        IERC20Token(tokenAddress).burn(msg.sender,earlyWithdrawUser);

        IERC20(PT).approve(address(router), exactPtIn);
        (uint256 netTokenOut,,) = router.swapExactPtForToken(
        address(this), address(market), exactPtIn, createTokenOutputStruct(currencyAddress, 0), emptyLimit);
        currency.safeTransfer(msg.sender, netTokenOut);
        emit EarlyWithdraw(msg.sender, _noOfBlock, exactPtIn, earlyWithdrawUser);
    }

    /**
     * @notice Stores option positions for users
     * @param _userList Array of user addresses
     * @param _amountList Array of option position amounts
     * @dev Only callable by admin when product is in Issued status
     */
    function storageOptionPosition(address[] memory _userList, uint256[] memory _amountList) external onlyIssued onlyAdmin {
        uint256 length = _userList.length;
        for (uint256 i = 0; i < length; i++) 
        {
            UserOptionPositions.push(UserOptionPosition({
                    userAddress: _userList[i],
                    value: _amountList[i]
            }));
            totalOptionPosition += _amountList[i];
        }
    }

    /**
     * @notice Pays out option positions to users
     * @dev Only callable by manager when product is in Issued status
     * @dev Transfers stored option positions to respective users
     */
    function userOptionPositionPaid() external onlyIssued onlyManager {
        currency.safeTransferFrom(msg.sender, address(this), totalOptionPosition);
        uint256 length = UserOptionPositions.length;
        for (uint256 i = 0; i < length; i++) 
        {
            currency.safeTransfer(UserOptionPositions[i].userAddress, UserOptionPositions[i].value);
        }
        totalOptionPosition = 0;
        totalNumberOfBlocks = 0;
        delete UserOptionPositions;
        emit UserOptionPositionPaid(totalOptionPosition);
    }

    /**
     * @notice Allows external wallet to transfer option profits to the contract
     * @param _optionProfit Amount of option profit to transfer
     * @dev Only callable by external wallet when product is in Mature status
     */
    function redeemOptionPayout(uint256 _optionProfit) external onlyMature {
        require(msg.sender == exWallet, "Not an exwallet");
        currency.safeTransferFrom(msg.sender, address(this), _optionProfit);
        optionProfit = _optionProfit;
        emit RedeemOptionPayout(msg.sender, _optionProfit);
    }

    /**
     * @notice Gets the principal balance of a user
     * @param _user Address of the user
     * @return uint256 Amount of principal tokens held by the user
     */
    function principalBalance(address _user) external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(_user);
    }

    /**
     * @notice Gets the coupon balance of a user
     * @param _user Address of the user
     * @return uint256 Amount of unclaimed coupon payments
     */
    function couponBalance(address _user) external view returns (uint256) {
        return userInfo[_user].coupon;
    }

    /**
     * @notice Gets the option payout balance of a user
     * @param _user Address of the user
     * @return uint256 Amount of unclaimed option payouts
     */
    function optionBalance(address _user) external view returns (uint256) {
        return userInfo[_user].optionPayout;
    }

    /**
     * @notice Gets the total balance of the underlying currency in the contract
     * @return uint256 Total balance of the contract
     */
    function totalBalance() public view returns (uint256) {
        return currency.balanceOf(address(this));
    }

    /**
     * @notice Gets the number of decimals for the underlying currency
     * @return uint256 Number of decimals
     * @dev Internal helper function
     */
    function _currencyDecimals() internal view returns (uint256) {
        return IERC20MetadataUpgradeable(address(currency)).decimals();
    }

    /**
     * @notice Pauses all contract operations
     * @dev Only callable by manager
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @notice Unpauses contract operations
     * @dev Only callable by manager
     */
    function unpause() external onlyManager {
        _unpause();
    }

    function setParameterUpdater(address _parameterUpdater) external onlyManager {
        parameterUpdater = ParameterUpdater(_parameterUpdater);
    }
}
