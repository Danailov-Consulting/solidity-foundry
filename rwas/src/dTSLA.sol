// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

// /Users/ddanailov/Workspace/Solidity/solidity-foundry/rwas/lib/
import {FunctionsClient} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ConfirmedOwner} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract dTSLA is ConfirmedOwner, FunctionsClient, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;

    error dTSLA_NotEnoughCollateral();

    enum MintOrRedeem {
        mint,
        redeem
    }

    struct dTslaRequest {
        uint256 amountOfToken;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

    // Math constants
    uint256 constant PRECISION = 1e18;

    /// https://docs.chain.link/chainlink-functions/supported-networks
    address constant SEPOLIA_FUNCTIONS_ROUTER =
        0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    uint32 constant GAS_LIMIT = 300_000;
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 DON_ID = hex"b83E47C2bC239B3bf370bc41e1459A34b41238D0";

    string private s_mintSourceCode;
    uint64 immutable i_subId;

    mapping(bytes32 requestId => dTslaRequest request)
        private s_requestIdToRequest;

    constructor(
        string memory mintSourceCode,
        uint64 subId
    ) ConfirmedOwner(msg.sender) FunctionsClient(SEPOLIA_FUNCTIONS_ROUTER) {
        s_mintSourceCode = mintSourceCode;
        i_subId = subId;
    }

    /// Send an HTTP request to:
    /// 1. See how much TSLA is bought
    /// 2. If enough TSLA is in the alpaca account
    /// mint dTSLA
    /// 2 transaction function
    function sendMintRequest(
        uint256 amount
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_mintSourceCode);
        requestId = _sendRequest(req.encodeCBOR(), i_subId, GAS_LIMIT, DON_ID);
        s_requestIdToRequest[requestId] = dTslaRequest(
            amount,
            msg.sender,
            MintOrRedeem.mint
        );

        return requestId;
    }

    /// Return the amount of TSLA value (in USD) is stored in our broker
    ///
    function _mintFulFillRequest(
        bytes32 requestId,
        bytes memory response
    ) internal {
        uint256 amountOfTokensToMint = s_requestIdToRequest[requestId]
            .amountOfToken;
        s_portfolioBalance = uint256(bytes32(response));

        // if TSLA collateral (how much TSLA we've bought) > dTSLA to mint -> mint
        // How much TSLA in $$$ do we have?
        // How much TSLA in $$$ are we minting?
        if (
            _getCollateralRatioAdjustedTotalBalance(amountOfTokensToMint) >
            s_portfolioBalance
        ) {
            revert dTSLA_NotEnoughCollateral();
        }
    }

    /// @notice User sends a request to sell TSLA for USDC(redemptionToken)
    /// This will, have the chainlink function call our alpaca(bank)
    /// and do the following:
    /// 1. Sell TSLA on the brokerage
    /// 2. Buy USDC on the brokerage
    /// 3. Send USDC to this contract for the user to withdraw
    function sendRedeemRequest() external {}

    function _redeemFulFillRequest(
        bytes32 requestId,
        bytes memory response
    ) internal {}

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory /** err */
    ) internal override {
        if (s_requestIdToRequest[requestId].mintOrRedeem == MintOrRedeem.mint) {
            _mintFulFillRequest(requestId, response);
        } else {
            _redeemFulFillRequest(requestId, response);
        }
    }

    function _getCollateralRatioAdjustedTotalBalance(
        uint256 amountOfTokensToMint
    ) internal view returns (uint256) {
        uint256 calculatedNewTotalValue = getCalculatedNewTotalValue(
            amountOfTokensToMint
        );
    }

    /// The new expected total value in USD of all the dTSLA tokens combined
    function getCalculatedNewTotalValue(
        uint256 addedNumberOfTokens
    ) internal view returns (uint256) {
        // 10 dtsla tokens + 5 dtsla tokens = 15dtsla tokens * tsla prince (100) = 1500
        uint256 supply = totalSupply();
        uint256 totalTokens = supply + addedNumberOfTokens;
        uint256 teslaPrice = getTslaPrice();

        return (totalTokens * teslaPrice) / PRECISION;
    }

    function getTslaPrice() internal view returns (uint256) {}
}
