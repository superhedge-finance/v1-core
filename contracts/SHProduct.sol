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
import "./interfaces/ISHFactory.sol";
import "./interfaces/IERC20Token.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Array.sol";

contract SHProduct is StructGen, ReentrancyGuardUpgradeable, PausableUpgradeable {
    IPPrincipalToken public PT;
    IPAllActionV3 public router ;
    address public currencyAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    IPMarket public market;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Array for address[];
    uint256 public netPtOut;

    struct UserInfo {
        uint256 coupon;
        uint256 optionPayout;
    }

    string public name;
    string public underlying;

    address public manager;
    // address public shNFT;
    address public shFactory;
    address public tokenAddress;

    address public exWallet;

    uint256 public maxCapacity;
    uint256 public currentCapacity;
    uint256 public optionProfit;
    uint256 public totalCurrentSupply;
    
    uint256 public currentTokenId;
    uint256 public prevTokenId;

    DataTypes.Status public status;
    DataTypes.IssuanceCycle public issuanceCycle;
    
    mapping(address => UserInfo) public userInfo;

    IERC20Upgradeable public currency;
    bool public isDistributed;

    /// @notice restricting access to the automation functions
    mapping(address => bool) public whitelisted;
    
    event Deposit(
        address indexed _user,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _supply
    );

    event WithdrawPrincipal(
        address indexed _user,
        uint256 _amount,
        uint256 _prevTokenId,
        uint256 _prevSupply,
        uint256 _currentTokenId,
        uint256 _currentSupply
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
        address indexed _qredoDeribit,
        uint256 _optionRate,
        address indexed _lendleLPool,
        uint256 _yieldRate
    );
    
    event RedeemYield(
        address _lendleLPool,
        uint256 _amount
    );

    /// @notice Event emitted when new issuance cycle is updated
    event UpdateParameters(
        uint256 _coupon,
        uint256 _strikePrice1,
        uint256 _strikePrice2,
        uint256 _strikePrice3,
        uint256 _strikePrice4,
        uint256 _tr1,
        uint256 _tr2,
        string _apy,
        string _uri
    );

    // event FundAccept(
    //     uint256 _optionProfit,
    //     uint256 _prevTokenId,
    //     uint256 _currentTokenId,
    //     uint256 _numOfHolders,
    //     uint256 _timestamp
    // );

    event FundAccept(
        uint256 _optionProfit,
        uint256 _timestamp
    );

    event FundLock(
        uint256 _timestamp
    );

    // event Issuance(
    //     uint256 _currentTokenId,
    //     uint256 _prevHolders,
    //     uint256 _timestamp
    // );

    event Issuance(
        uint256 _timestamp
    );

    event Mature(
        uint256 _prevTokenId,
        uint256 _currentTokenId,
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

    event UpdateStrikePrices(
        uint256 _strikePrice1,
        uint256 _strikePrice2,
        uint256 _strikePrice3,
        uint256 _strikePrice4
    );

    event UpdateURI(
        uint256 _currentTokenId,
        string _uri
    );

    event UpdateTRs(
        uint256 _newTr1,
        uint256 _newTr2
    );

    event UpdateAPY(
        string _apy
    );
    
    event UpdateTimes(
        uint256 _issuanceDate,
        uint256 _maturityDate
    );

    event UpdateName(
        string _name
    );

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
        maxCapacity = _maxCapacity;
        tokenAddress = _tokenAddress;
        currency = _currency;
        currencyAddress = _currencyAddress;
        shFactory = msg.sender;

        require(_issuanceCycle.issuanceDate > block.timestamp, 
            "Issuance date should be bigger than current timestamp");
        require(_issuanceCycle.maturityDate > _issuanceCycle.issuanceDate, 
            "Maturity timestamp should be bigger than issuance one");
        
        issuanceCycle = _issuanceCycle;

        router = IPAllActionV3(_router);
        market = IPMarket(_market);
        (, PT,) = IPMarket(market).readTokens();


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

    modifier onlyAccepted() {
        require(status == DataTypes.Status.Accepted, "Not accepted status");
        _;
    }

    modifier onlyLocked() {
        require(status == DataTypes.Status.Locked, "Not locked status");
        _;
    }

    modifier onlyIssued() {
        require(status == DataTypes.Status.Issued, "Not issued status");
        _;
    }

    modifier onlyMature() {
        require(status == DataTypes.Status.Mature, "Not mature status");
        _;
    }

    modifier LockedOrMature() {
        require(status == DataTypes.Status.Locked || status == DataTypes.Status.Mature, 
            "Neither mature nor locked");
        _;
    }

    /**
     * @notice Whitelists the additional accounts to call the automation functions.
     */
    function whitelist(address _account) external onlyManager {
        require(!whitelisted[_account], "Already whitelisted");
        whitelisted[_account] = true;
    }

    /**
     * @notice Remove the additional callers from whitelist.
     */
    function removeFromWhitelist(address _account) external onlyManager {
        delete whitelisted[_account];
    }

    function fundAccept() external whenNotPaused onlyWhitelisted {
        require(status == DataTypes.Status.Pending || status == DataTypes.Status.Mature, 
            "Neither mature nor pending status");
        // First, distribute option profit to the token holders.
        // address[] memory totalHolders = ISHNFT(shNFT).accountsByToken(prevTokenId);
        uint256 _optionProfit = optionProfit;
        // if (_optionProfit > 0) {
        //     uint256 totalSupply = ISHNFT(shNFT).totalSupply(prevTokenId);
        //     for (uint256 i = 0; i < totalHolders.length; i++) {
        //         uint256 prevSupply = ISHNFT(shNFT).balanceOf(totalHolders[i], prevTokenId);
        //         uint256 _optionPayout = prevSupply * _optionProfit / totalSupply;
        //         userInfo[totalHolders[i]].optionPayout += _optionPayout;
        //         emit OptionPayout(totalHolders[i], _optionPayout);
        //     }
        //     optionProfit = 0;
        // }
        // Then update status
        status = DataTypes.Status.Accepted;

        // emit FundAccept(
        //     _optionProfit, 
        //     prevTokenId, 
        //     currentTokenId, 
        //     totalHolders.length, 
        //     block.timestamp
        // );

        emit FundAccept(
            _optionProfit, 
            block.timestamp
        );
    }

    function fundLock() external whenNotPaused onlyAccepted onlyWhitelisted {
        status = DataTypes.Status.Locked;

        emit FundLock(block.timestamp);
    }

    function issuance() external whenNotPaused onlyLocked onlyWhitelisted {
        status = DataTypes.Status.Issued;

        // emit Issuance(currentTokenId, totalHolders.length, block.timestamp);
        emit Issuance(block.timestamp);
    }

    function mature() external whenNotPaused onlyIssued onlyWhitelisted {

        status = DataTypes.Status.Mature;

        emit Mature(prevTokenId, currentTokenId, block.timestamp);
    }

    /**
     * @dev Update users' coupon balance every week
     */
    function coupon(address[] memory _holdersList, uint256[] memory _amountHoldersList) external whenNotPaused onlyIssued onlyWhitelisted {
        for (uint256 i = 0; i < _holdersList.length; i++) {
            uint256 _amount = _amountHoldersList[i] * issuanceCycle.coupon / 10000;
            userInfo[_holdersList[i]].coupon += _amount;

            emit Coupon(
                    _holdersList[i],
                    _amount
                );
        }
    }

    /**
     * @dev Updates only coupon parameter
     * @param _newCoupon weekly coupon rate in basis point; e.g. 0.10%/wk => 10
     */
    function updateCoupon(
        uint256 _newCoupon
    ) public LockedOrMature onlyManager {
        issuanceCycle.coupon = _newCoupon;

        emit UpdateCoupon(_newCoupon);
    }

    /**
     * @dev Updates strike prices
     */
    function updateStrikePrices(
        uint256 _strikePrice1,
        uint256 _strikePrice2,
        uint256 _strikePrice3,
        uint256 _strikePrice4
    ) public LockedOrMature onlyManager {
        issuanceCycle.strikePrice1 = _strikePrice1;
        issuanceCycle.strikePrice2 = _strikePrice2;
        issuanceCycle.strikePrice3 = _strikePrice3;
        issuanceCycle.strikePrice4 = _strikePrice4;

        emit UpdateStrikePrices(
            _strikePrice1, 
            _strikePrice2, 
            _strikePrice3, 
            _strikePrice4
        );
    }

    /**
     * @dev Updates TR1 & TR2 (total returns %)
     */
    function updateTRs(
        uint256 _newTr1,
        uint256 _newTr2
    ) public LockedOrMature onlyManager {
        issuanceCycle.tr1 = _newTr1;
        issuanceCycle.tr2 = _newTr2;

        emit UpdateTRs(_newTr1, _newTr2);
    }

    /**
     *
     */
    function updateAPY(
        string memory _apy
    ) public LockedOrMature onlyManager {
        issuanceCycle.apy = _apy;

        emit UpdateAPY(_apy);
    }

    /**
     * @dev Update all parameters for next issuance cycle, called by only manager
     */
    function updateParameters(
        uint256 _coupon,
        uint256 _strikePrice1,
        uint256 _strikePrice2,
        uint256 _strikePrice3,
        uint256 _strikePrice4,
        uint256 _tr1,
        uint256 _tr2,
        string memory _apy,
        string memory _uri
    ) external LockedOrMature onlyManager {

        updateCoupon(_coupon);

        updateStrikePrices(_strikePrice1, _strikePrice2, _strikePrice3, _strikePrice4);

        updateTRs(_tr1, _tr2);

        updateAPY(_apy);

        emit UpdateParameters(
            _coupon, 
            _strikePrice1, 
            _strikePrice2,
            _strikePrice3,
            _strikePrice4,
            _tr1,
            _tr2,
            _apy,
            _uri
        );
    }
    function updateTimes(
        uint256 _issuanceDate,
        uint256 _maturityDate
    ) external onlyMature onlyManager {
        require(_issuanceDate > block.timestamp, 
            "Issuance timestamp should be bigger than current one");
        require(_maturityDate > _issuanceDate, 
            "Maturity timestamp should be bigger than issuance one");
        
        issuanceCycle.issuanceDate = _issuanceDate;
        issuanceCycle.maturityDate = _maturityDate;

        emit UpdateTimes(_issuanceDate, _maturityDate);
    }
    /**
     * @dev Update issuance & maturity dates
     */
    

    /**
     * @notice Update product name
     */
    function updateName(string memory _name) external {
        require(msg.sender == shFactory, "Not a factory contract");
        name = _name;

        emit UpdateName(_name);
    }

    /**
     * @dev Deposits the USDC into the structured product and mint ERC1155 NFT
     * @param _amount is the amount of USDC to deposit
     * @param _type True: include profit, False: without profit
     */
    // function deposit(uint256 _amount, bool _type) external whenNotPaused nonReentrant onlyAccepted {
    function deposit(uint256 _amount, bool _type) external whenNotPaused nonReentrant onlyAccepted {
        require(_amount > 0, "Amount must be greater than zero");
        
        uint256 amountToDeposit = _amount;
        if (_type == true) {
            amountToDeposit += userInfo[msg.sender].coupon + userInfo[msg.sender].optionPayout;
        }

        uint256 decimals = _currencyDecimals();
        // require((amountToDeposit % (1000 * 10 ** decimals)) == 0, "Amount must be whole-number thousands"); // > 1000
        require((maxCapacity * 10 ** decimals) >= (currentCapacity + amountToDeposit), "Product is full");

        uint256 supply = amountToDeposit / (1 * 10 ** decimals);

        currency.safeTransferFrom(msg.sender, address(this), _amount);
        IERC20Token(tokenAddress).mint(msg.sender,_amount);
        totalCurrentSupply = totalCurrentSupply + _amount;

        currentCapacity += amountToDeposit;
        if (_type == true) {
            userInfo[msg.sender].coupon = 0;
            userInfo[msg.sender].optionPayout = 0;
        }

        emit Deposit(msg.sender, _amount, currentTokenId, supply);
    }

    /**
     * @dev Withdraws the principal from the structured product
     */
    function withdrawPrincipal() external nonReentrant onlyAccepted {
        uint256 currentToken = IERC20Token(tokenAddress).checkBalanceOf(msg.sender);
        IERC20(tokenAddress).transferFrom(msg.sender, deadAddress, currentToken);
        currency.safeTransfer(msg.sender, currentToken);
        currentCapacity -= currentToken;

        emit WithdrawPrincipal(
            msg.sender, 
            currentToken, 
            prevTokenId, 
            currentToken, 
            currentTokenId, 
            currentToken
        );
    }

    function withdrawTokenAll(IERC20 _token) external  {
        require(_token.balanceOf(address(this)) > 0 , "balanceOfToken:  is equal 0");
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }



    /**
     * @notice Withdraws user's coupon payout
     */
    function withdrawCoupon() external nonReentrant {
        uint256 _couponAmount = userInfo[msg.sender].coupon;
        require(_couponAmount > 0, "No coupon payout");
        require(totalBalance() >= _couponAmount, "Insufficient balance");
        
        currency.safeTransfer(msg.sender, _couponAmount);
        userInfo[msg.sender].coupon = 0;

        emit WithdrawCoupon(msg.sender, _couponAmount);
    }

    // /**
    //  * @notice Withdraws user's option payout
    //  */
    function withdrawOption() external nonReentrant {
        uint256 _optionAmount = userInfo[msg.sender].optionPayout;
        require(_optionAmount > 0, "No option payout");
        require(totalBalance() >= _optionAmount, "Insufficient balance");
        
        currency.safeTransfer(msg.sender, _optionAmount);
        userInfo[msg.sender].optionPayout = 0;

        emit WithdrawOption(msg.sender, _optionAmount);
    }

    /**
     * @notice Distributes locked funds
     */
    function distributeFunds(
        uint256 _yieldRate,
        address _router
    ) external onlyManager onlyLocked {
        require(!isDistributed, "Already distributed");
        require(_yieldRate <= 100, "Yield rate should be equal or less than 100");
        uint256 optionRate = 100 - _yieldRate;

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
        
        emit DistributeFunds(exWallet, optionRate, _router, _yieldRate);
    }

    /**
     * @notice Redeem yield from Lendle protocol(DeFi lending protocol)
     */

    function redeemYield(
        address _router
    ) external onlyManager onlyMature {
        require(isDistributed, "Not distributed");
        // Withdraw your asset based on a aToken amount
        uint256 exactPtIn = IERC20(PT).balanceOf(address(this));
        IERC20(PT).approve(address(router), exactPtIn);
        (uint256 netTokenOut,,) = router.swapExactPtForToken(
        address(this), address(market), exactPtIn, createTokenOutputStruct(currencyAddress, 0), emptyLimit);
        netPtOut = 0;
        isDistributed = false;

        emit RedeemYield(_router, netTokenOut);
    }

    /**
     * @dev Transfers option profit from a qredo wallet, called by an owner
     */
    function redeemOptionPayout(uint256 _optionProfit) external onlyMature {
        require(msg.sender == exWallet, "Not exWallet address");
        currency.safeTransferFrom(msg.sender, address(this), _optionProfit);
        optionProfit = _optionProfit;

        emit RedeemOptionPayout(msg.sender, _optionProfit);
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
     * @notice Calculates the currency amount based on token supply
     */
    function _convertTokenToCurrency(uint256 _tokenSupply) internal view returns (uint256) {
        return _tokenSupply * 1 * (10 ** _currencyDecimals());
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
