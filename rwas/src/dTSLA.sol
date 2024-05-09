// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract dTSLA {
    /// Send an HTTP request to:
    /// 1. See how much TSLA is bought
    /// 2. If enough TSLA is in the alpaca account
    /// mint dTSLA
    /// 2 transaction function
    function sendMintRequest(uint256 amount) external onlyOwner {}

    function _mintFulFillRequest() internal {}

    /// @notice User sends a request to sell TSLA for USDC(redemptionToken)
    /// This will, have the chainlink function call our alpaca(bank)
    /// and do the following:
    /// 1. Sell TSLA on the brokerage
    /// 2. Buy USDC on the brokerage
    /// 3. Send USDC to this contract for the user to withdraw
    function sendRedeemRequest() external {}
}
