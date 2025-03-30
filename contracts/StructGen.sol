// SPDX-License-Identifier: MIT
pragma solidity >=0.8.23 <0.9.0;

import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";

abstract contract StructGen {

    /// @notice Minimum guess value for approximation
    /// @dev Adjust as desired
    uint256 public guessMin = 0;

    /// @notice Maximum guess value for approximation
    /// @dev Adjust as desired
    uint256 public guessMax = type(uint256).max;

    /// @notice Offchain guess value, strictly 0
    uint256 public guessOffchain = 0;

    /// @notice Maximum number of iterations for approximation
    /// @dev Adjust as desired
    uint256 public maxIteration = 256;

    /// @notice Epsilon value for approximation, max 0.01% unused
    /// @dev Adjust as desired
    uint256 public eps = 1e14;

    /// @notice Represents an empty swap, meaning no swap aggregator is involved
    SwapData public emptySwap;

    /// @notice Represents an empty limit order, meaning no limit order is involved
    LimitOrderData public emptyLimit;

    /// @notice Default approximation parameters, more gas consuming (~ 180k gas)
    /// @dev No off-chain preparation is involved
    ApproxParams public defaultApprox = ApproxParams(guessMin, guessMax, guessOffchain, maxIteration, eps);

    /// @notice Creates a simple TokenInput struct without using any aggregators
    /// @dev For more info, refer to IPAllActionTypeV3.sol
    /// @param tokenIn The address of the input token
    /// @param netTokenIn The net amount of the input token
    /// @return A TokenInput struct with the specified parameters
    function createTokenInputStruct(address tokenIn, uint256 netTokenIn) internal view returns (TokenInput memory) {
        return TokenInput({
            tokenIn: tokenIn,
            netTokenIn: netTokenIn,
            tokenMintSy: tokenIn,
            pendleSwap: address(0),
            swapData: emptySwap
        });
    }

    /// @notice Creates a simple TokenOutput struct without using any aggregators
    /// @dev For more info, refer to IPAllActionTypeV3.sol
    /// @param tokenOut The address of the output token
    /// @param minTokenOut The minimum amount of the output token
    /// @return A TokenOutput struct with the specified parameters
    function createTokenOutputStruct(
        address tokenOut,
        uint256 minTokenOut
    )
        internal
        view
        returns (TokenOutput memory)
    {
        return TokenOutput({
            tokenOut: tokenOut,
            minTokenOut: minTokenOut,
            tokenRedeemSy: tokenOut,
            pendleSwap: address(0),
            swapData: emptySwap
        });
    }
}