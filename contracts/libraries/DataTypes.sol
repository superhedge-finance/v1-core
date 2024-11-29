// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library DataTypes {
    /// @notice Struct representing issuance cycle
    /// @dev This struct is used to store details about an issuance cycle.
    struct IssuanceCycle {
        /// @notice The coupon rate for the issuance cycle
        uint8 coupon;
        /// @notice The first strike price for the issuance cycle
        uint256 strikePrice1;
        /// @notice The second strike price for the issuance cycle
        uint256 strikePrice2;
        /// @notice The third strike price for the issuance cycle
        uint256 strikePrice3;
        /// @notice The fourth strike price for the issuance cycle
        uint256 strikePrice4;
        /// @notice The first tranche rate for the issuance cycle
        uint256 tr1;
        /// @notice The second tranche rate for the issuance cycle
        uint256 tr2;
        /// @notice The issuance date of the cycle
        uint256 issuanceDate;
        /// @notice The maturity date of the cycle
        uint256 maturityDate;
        /// @notice The annual percentage yield for the issuance cycle
        string apy;
        /// @notice Reference to the underlying spot
        uint8 underlyingSpotRef;
        /// @notice Minimum order size for options
        uint8 optionMinOrderSize;
        /// @notice Identifier for the sub-account
        string subAccountId;
        /// @notice Participation rate in the issuance cycle
        uint8 participation;
    }

    /// @notice Enum representing product status
    /// @dev This enum is used to track the status of a product.
    enum Status {
        /// @notice The product is pending approval
        Pending,
        /// @notice The product has been accepted
        Accepted,
        /// @notice The product is locked
        Locked,
        /// @notice The product has been issued
        Issued,
        /// @notice The product has matured
        Mature
    }
}
