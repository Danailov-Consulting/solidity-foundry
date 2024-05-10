// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

// /Users/ddanailov/Workspace/Solidity/solidity-foundry/rwas/lib/
import {FunctionsClient} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

import {ConfirmedOwner} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract dTSLA is ConfirmedOwner, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    enum MintOrRedeem {
        mint,
        redeem
    }

    struct dTslaRequest {
        uint256 amountOfToken;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

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
    ) internal {}

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
}
