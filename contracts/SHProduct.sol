// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import "./StructGen.sol";
import "./interfaces/ISHProduct.sol";
import "./interfaces/IERC20Token.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Array.sol";
import "./libraries/EventFunctions.sol";

contract SHProduct is StructGen, ReentrancyGuardUpgradeable, PausableUpgradeable,EventFunctions{
    IPPrincipalToken public PT;
    IPYieldToken public YT;
    IPAllActionV3 public router ;
    address public currencyAddress;
    IPMarket public market;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Array for address[];
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

    DataTypes.Status public status;
    DataTypes.IssuanceCycle public issuanceCycle;
    
    mapping(address => UserInfo) public userInfo;
    UserOptionPosition[] public UserOptionPositions;
    

    IERC20Upgradeable public currency;
    bool public isDistributed;

    /// @notice restricting access to the automation functions
    mapping(address => bool) public whitelisted;

    function initialize(
        string memory _name,
        string memory _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _exWallet,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle memory _issuanceCycle,
        address _router,
        address _market,
        address _tokenAddress,
        address _currencyAddress
    ) public initializer {
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

        require(_issuanceCycle.issuanceDate > block.timestamp, 
            "ID bigger");
        require(_issuanceCycle.maturityDate > _issuanceCycle.issuanceDate, 
            "MT bigger");
        
        issuanceCycle = _issuanceCycle;

        router = IPAllActionV3(_router);
        market = IPMarket(_market);
        (, PT,YT) = IPMarket(market).readTokens();
    }
    
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Only whitelisted");
        _;
    }

    /// @notice Modifier for functions restricted to manager
    modifier onlyManager() {
        require(msg.sender == manager, "Not a manager");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyAccepted() {
        require(status == DataTypes.Status.Accepted, "Not accepted");
        _;
    }

    modifier onlyLocked() {
        require(status == DataTypes.Status.Locked, "Not locked");
        _;
    }

    modifier onlyIssued() {
        require(status == DataTypes.Status.Issued, "Not issued");
        _;
    }

    modifier onlyMature() {
        require(status == DataTypes.Status.Mature, "Not mature");
        _;
    }

    modifier LockedOrMature() {
        require(status == DataTypes.Status.Locked || status == DataTypes.Status.Mature, 
            "Neither mature nor locked");
        _;
    }

    modifier AcceptedOrLockedOrMature() {
        require(status == DataTypes.Status.Locked || status == DataTypes.Status.Mature || status == DataTypes.Status.Accepted, 
            "Neither mature nor locked");
        _;
    }

    /**
     * @notice Whitelists the additional accounts to call the automation functions.
     */
    function whitelist(address _account) external onlyManager {
        require(!whitelisted[_account], "Whitelisted");
        whitelisted[_account] = true;
    }

    /**
     * @notice Remove the additional callers from whitelist.
     */
    function removeFromWhitelist(address _account) external onlyManager {
        delete whitelisted[_account];
    }

    function addAdmin(address _account) external onlyManager {
        admin = _account;
    }

    function fundAccept() external whenNotPaused onlyWhitelisted {
        require(status == DataTypes.Status.Pending || status == DataTypes.Status.Mature, 
            "Neither mature nor pending status");
        // Then update status
        status = DataTypes.Status.Accepted;
        emit FundAccept(
            block.timestamp
        );
    }

    function addOptionProfitList(address[] memory _userList, uint256[] memory _amountList) external whenNotPaused onlyAccepted onlyWhitelisted {
        uint256 _optionProfit = optionProfit;
        if (_optionProfit > 0) {
            for (uint256 i = 0; i < _userList.length; i++) {
                userInfo[_userList[i]].optionPayout += _amountList[i];
            }
            optionProfit = 0;
        }
        emit AddOptionProfitList(
            _userList,
            _amountList
        );
    }

    function fundLock() external whenNotPaused onlyAccepted onlyWhitelisted {
        status = DataTypes.Status.Locked;

        emit FundLock(block.timestamp);
    }

    function issuance() external whenNotPaused onlyLocked onlyWhitelisted {
        status = DataTypes.Status.Issued;
        emit Issuance(block.timestamp);
    }

    function mature() external whenNotPaused onlyIssued onlyWhitelisted {
        status = DataTypes.Status.Mature;
        emit Mature(block.timestamp);
    }

    /**
     * @dev Update users' coupon balance every week
     */

    function coupon(address[] memory _userList, uint256[] memory _amountList) external whenNotPaused onlyIssued onlyWhitelisted{
        for (uint256 i = 0; i < _userList.length; i++) {
            userInfo[_userList[i]].coupon += _amountList[i];
            emit Coupon(
                    _userList[i],
                    _amountList[i]
                );
        }
    }

    /**
     * @dev Updates only coupon parameter
     * @param _newCoupon weekly coupon rate in basis point; e.g. 0.10%/wk => 10
     */
    function updateCoupon(
        uint8 _newCoupon
    ) public LockedOrMature onlyManager {
        issuanceCycle.coupon = _newCoupon;

        emit UpdateCoupon(_newCoupon);
    }

    /**
     * @dev Update all parameters for next issuance cycle, called by only manager
     */
    function updateParameters(string memory _name, DataTypes.IssuanceCycle memory _issuanceCycle,address _router,address _market) external onlyAccepted onlyManager {

        name = _name;
        router = IPAllActionV3(_router);
        market = IPMarket(_market);
        (,PT,YT) = IPMarket(market).readTokens();

        issuanceCycle.tr1 = _issuanceCycle.tr1;
        issuanceCycle.tr2 = _issuanceCycle.tr2;
        issuanceCycle.strikePrice1 = _issuanceCycle.strikePrice1;
        issuanceCycle.strikePrice2 = _issuanceCycle.strikePrice2;
        issuanceCycle.strikePrice3 = _issuanceCycle.strikePrice3;
        issuanceCycle.strikePrice4 = _issuanceCycle.strikePrice4;
        issuanceCycle.apy = _issuanceCycle.apy;
        issuanceCycle.subAccountId = _issuanceCycle.subAccountId;
        issuanceCycle.issuanceDate = _issuanceCycle.issuanceDate;
        issuanceCycle.maturityDate = _issuanceCycle.maturityDate;

        emit UpdateParameters(
            _name,
            _router, 
            _market
        );
    }

    function updateStructure(uint256 _strikePrice1, uint256 _strikePrice2, uint256 _strikePrice3, uint256 _strikePrice4,
    uint256 _tr1, uint256 _tr2, string memory _apy, uint8 _underlyingSpotRef) external onlyLocked onlyManager {
        issuanceCycle.strikePrice1 = _strikePrice1;
        issuanceCycle.strikePrice2 = _strikePrice2;
        issuanceCycle.strikePrice3 = _strikePrice3;
        issuanceCycle.strikePrice4 = _strikePrice4;
        issuanceCycle.tr1 = _tr1;
        issuanceCycle.tr2 = _tr2;
        issuanceCycle.apy = _apy;
        issuanceCycle.underlyingSpotRef = _underlyingSpotRef;
        
        emit UpdateStructure(
            _strikePrice1,
            _strikePrice2,
            _strikePrice3,
            _strikePrice4,
            _tr1,
            _tr2,
            _apy,
            _underlyingSpotRef
        );
    }

    /**
     * @dev Deposits the USDC into the structured product and mint ERC20 Token
     * @param _amount is the amount of USDC to deposit
     * @param _type True: include profit, False: without profit
     */
    function deposit(uint256 _amount, bool _type) external whenNotPaused nonReentrant onlyAccepted{
        require(_amount > 0, "Greater zero");
        uint256 decimals = _currencyDecimals();
        
        uint256 amountToDeposit = _amount;
        if (_type == true) {
            amountToDeposit += userInfo[msg.sender].coupon + userInfo[msg.sender].optionPayout;
        }
        require((maxCapacity * 10 ** decimals) >= (currentCapacity + amountToDeposit), "Product is full");

        uint256 supply = amountToDeposit / (1 * 10 ** decimals);

        currency.safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Token(tokenAddress).mint(msg.sender,_amount);

        currentCapacity += amountToDeposit;
        if (_type == true) {
            userInfo[msg.sender].coupon = 0;
            userInfo[msg.sender].optionPayout = 0;
        }

        emit Deposit(msg.sender, _amount,supply);
    }

    /**
     * @dev Withdraws the principal from the structured product
     */
    function withdrawPrincipal() external nonReentrant onlyAccepted {
        uint256 currentToken = IERC20(tokenAddress).balanceOf(msg.sender);

        IERC20Token(tokenAddress).burn(msg.sender,currentToken);
        // IERC20(tokenAddress).transferFrom(msg.sender, deadAddress, currentToken);
        currency.safeTransfer(msg.sender, currentToken);
        currentCapacity -= currentToken;

        emit WithdrawPrincipal(
            msg.sender, 
            currentToken
        );
    }

    /**
     * @notice Withdraws user's coupon payout
     */
    function withdrawCoupon() external nonReentrant {
        uint256 _couponAmount = userInfo[msg.sender].coupon;
        require(_couponAmount > 0, "No CP");
        require(totalBalance() >= _couponAmount, "Balance");
        
        currency.safeTransfer(msg.sender, _couponAmount);
        userInfo[msg.sender].coupon = 0;

        emit WithdrawCoupon(msg.sender, _couponAmount);
    }

    // /**
    //  * @notice Withdraws user's option payout
    //  */
    function withdrawOption() external nonReentrant {
        uint256 _optionAmount = userInfo[msg.sender].optionPayout;
        require(_optionAmount > 0, "No OP");
        require(totalBalance() >= _optionAmount, "Balance");
        
        currency.safeTransfer(msg.sender, _optionAmount);
        userInfo[msg.sender].optionPayout = 0;

        emit WithdrawOption(msg.sender, _optionAmount);
    }

    /**
     * @notice Distributes locked funds
     */
    function distributeFunds(
        uint8 _yieldRate
    ) external onlyManager onlyLocked {
        require(!isDistributed, "Already distributed");
        require(_yieldRate <= 100, "Less than 100");
        uint8 optionRate = 100 - _yieldRate;

        uint256 optionAmount;
        if (optionRate > 0) {
            optionAmount = currentCapacity * optionRate / 100;
            currency.transfer(exWallet, optionAmount);
        }

        uint256 yieldAmount = currentCapacity - optionAmount;

        IERC20(currencyAddress).approve(address(router), yieldAmount);
        (uint256 _netPtOut,,) = router.swapExactTokenForPt(
            address(this), address(market), 0, defaultApprox, createTokenInputStruct(currencyAddress, yieldAmount), emptyLimit
        );
        netPtOut = _netPtOut;
    
        isDistributed = true;
        
        emit DistributeFunds(exWallet, optionRate, address(router), _yieldRate);
    }

    /**
     * @notice Redeem yield from Pendle protocol(DeFi lending protocol)
     */

    function redeemYield(
    ) external onlyManager onlyMature {
        require(isDistributed, "Not distributed");
        uint256 exactPtIn = IERC20(PT).balanceOf(address(this));
        uint256 netTokenOut;
        if (exactPtIn > 0)
        {
            IERC20(PT).approve(address(router), exactPtIn);
            // (netTokenOut,,) = router.swapExactPtForToken(
            // address(this), address(market), exactPtIn, createTokenOutputStruct(currencyAddress, 0), emptyLimit);
            (netTokenOut,) = router.redeemPyToToken(address(this), address(YT), exactPtIn, createTokenOutputStruct(currencyAddress, 0)); 
        }

        netPtOut = 0;
        isDistributed = false;
        emit RedeemYield(address(router), netTokenOut);
    }

    function earlyWithdraw(uint256 _noOfBlock) external onlyIssued{
        uint256 exactPtIn = 0;
        uint256 decimals = _currencyDecimals();
        uint256 earlyWithdrawUser = ((_noOfBlock * issuanceCycle.underlyingSpotRef) *(issuanceCycle.optionMinOrderSize * 10**(decimals)))/10;
        uint256 currentToken = IERC20(tokenAddress).balanceOf(msg.sender);

        uint256 withdrawBlockSize = (issuanceCycle.underlyingSpotRef * 10**(decimals) * issuanceCycle.optionMinOrderSize)/10;
        uint256 totalBlock = currentToken / withdrawBlockSize;

        if (totalBlock >= _noOfBlock){
            exactPtIn  = (earlyWithdrawUser * netPtOut / currentCapacity);  
        }

        IERC20Token(tokenAddress).burn(msg.sender,earlyWithdrawUser);
        IERC20(PT).approve(address(router), exactPtIn);
        (uint256 netTokenOut,,) = router.swapExactPtForToken(
        address(this), address(market), exactPtIn, createTokenOutputStruct(currencyAddress, 0), emptyLimit);
        netPtOut-=exactPtIn; 
        currentCapacity -= earlyWithdrawUser;
        totalNumberOfBlocks+=_noOfBlock;
        currency.safeTransfer(msg.sender, netTokenOut);
        emit EarlyWithdraw(msg.sender, _noOfBlock, exactPtIn, earlyWithdrawUser);
    }

    function storageOptionPosition(address[] memory _userList, uint256[] memory _amountList) external onlyIssued onlyAdmin
    {
        for (uint256 i = 0; i < _userList.length; i++) 
        {
            UserOptionPositions.push(UserOptionPosition({
                    userAddress: _userList[i],
                    value: _amountList[i]
            }));
            totalOptionPosition += _amountList[i];
        }
    }

    function userOptionPositionPaid() external onlyIssued onlyManager {

        currency.safeTransferFrom(msg.sender, address(this), totalOptionPosition);
        
        for (uint256 i = 0; i < UserOptionPositions.length; i++) 
        {
            currency.safeTransfer(UserOptionPositions[i].userAddress, UserOptionPositions[i].value);
        }
        totalOptionPosition = 0;
        totalNumberOfBlocks = 0;
        delete UserOptionPositions;
        emit UserOptionPositionPaid(totalOptionPosition);
    }

    /**
     * @dev Transfers option profit from a ex wallet, called by an owner
     */
    function redeemOptionPayout(uint256 _optionProfit) external onlyMature {
        require(msg.sender == exWallet, "Not a ex wallet");
        currency.safeTransferFrom(msg.sender, address(this), _optionProfit);
        optionProfit = _optionProfit;

        emit RedeemOptionPayout(msg.sender, _optionProfit);
    }

    /**
     * @notice Returns the user's principal balance
     * Before auto-rolling or fund lock, users can have both tokens so total supply is the sum of 
     * previous supply and current supply
     */
    function principalBalance(address _user) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(_user);
    }

    /**
     * @notice Returns the user's coupon payout
     */
    function couponBalance(address _user) external view returns (uint256) {
        return userInfo[_user].coupon;
    }

    /**
     * @notice Returns the user's option payout
     */
    function optionBalance(address _user) external view returns (uint256) {
        return userInfo[_user].optionPayout;
    }

    /**
     * @notice Returns the product's total USDC balance
     */
    function totalBalance() public view returns (uint256) {
        return currency.balanceOf(address(this));
    }

    /**
     * @notice Returns the decimal of underlying asset (USDC)
     */
    function _currencyDecimals() internal view returns (uint256) {
        return IERC20MetadataUpgradeable(address(currency)).decimals();
    }

    /**
     * @dev Pause the product
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @dev Unpause the product
     */

    function unpause() external onlyManager {
        _unpause();
    }
}
