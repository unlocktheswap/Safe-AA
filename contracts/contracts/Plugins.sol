// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {_getFeeCollectorRelayContext, _getFeeTokenRelayContext, _getFeeRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {customInterface, PoolKey, IHooks, IPoolManager, TestSettings} from "./interface/customInterface.sol";

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

contract RelayPlugin is BasePluginWithEventMetadata {
    event MaxFeeUpdated(address indexed account, address indexed feeToken, uint256 maxFee);

    error FeeTooHigh(address feeToken, uint256 fee);
    error FeePaymentFailure(bytes data);
    error UntrustedOrigin(address origin);
    error RelayExecutionFailure(bytes data);
    error InvalidRelayMethod(bytes4 data);

    error SenderHasNoValidNFTSubscription(address sender, address nft);

    address public immutable trustedOrigin;
    bytes4 public immutable relayMethod;

    // Account => token => maxFee
    mapping(address => mapping(address => uint256)) public maxFeePerToken;
    IERC721 subscriptionToken;

    constructor(
        address _trustedOrigin,
        bytes4 _relayMethod
    )
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "Relay Plugin",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""//"https://5afe.github.io/safe-core-protocol-demo/#/relay/${plugin}"
            })
        )
    {
        trustedOrigin = _trustedOrigin;
        relayMethod = _relayMethod;
    }

    function setMaxFeePerToken(address token, uint256 maxFee) external {
        maxFeePerToken[msg.sender][token] = maxFee;
        emit MaxFeeUpdated(msg.sender, token, maxFee);
    }

    function setNFTToken(address token) external {
        subscriptionToken = IERC721(token);
    }

    function payFee(ISafeProtocolManager manager, ISafe safe, uint256 nonce) internal {
        address feeCollector = _getFeeCollectorRelayContext();
        address feeToken = _getFeeTokenRelayContext();
        uint256 fee = _getFeeRelayContext();
        SafeProtocolAction[] memory actions = new SafeProtocolAction[](1);
        uint256 maxFee = maxFeePerToken[address(safe)][feeToken];
        if (fee > maxFee) revert FeeTooHigh(feeToken, fee);
        if (feeToken == NATIVE_TOKEN || feeToken == address(0)) {
            // If the native token is used for fee payment, then we directly send the fees to the fee collector
            actions[0].to = payable(feeCollector);
            actions[0].value = fee;
            actions[0].data = "";
        } else {
            // If a ERC20 token is used for fee payment, then we trigger a token transfer on the token for the fee to the fee collector
            actions[0].to = payable(feeToken);
            actions[0].value = 0;
            actions[0].data = abi.encodeWithSignature("transfer(address,uint256)", feeCollector, fee);
        }
        // Note: Metadata format has not been proposed
        SafeTransaction memory safeTx = SafeTransaction({actions: actions, nonce: nonce, metadataHash: bytes32(0)});
        try manager.executeTransaction(safe, safeTx) returns (bytes[] memory) {} catch (bytes memory reason) {
            revert FeePaymentFailure(reason);
        }
    }

    function relayCall(address relayTarget, bytes calldata relayData) internal {
        // Check relay data to avoid that module can be abused for arbitrary interactions
        if (bytes4(relayData[:4]) != relayMethod) revert InvalidRelayMethod(bytes4(relayData[:4]));

        // Perform relay call and require success to avoid that user paid for failed transaction
        (bool success, bytes memory data) = relayTarget.call(relayData);
        if (!success) revert RelayExecutionFailure(data);
    }

    function executeFromPlugin(ISafeProtocolManager manager, ISafe safe, bytes calldata data) external {
        if (trustedOrigin != address(0) && msg.sender != trustedOrigin) revert UntrustedOrigin(msg.sender);

        //check sender has subscription NFT, purchase if applicable
        (address sender, address nftAddress, bool freeSwap, PoolKey memory key, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, address router) = 
            abi.decode(data,(address,address,bool,PoolKey,bool,int256,uint160,address));

        /*PoolKey memory key = PoolKey({
            currency0: token0,
            currency1: token1,
            fee: 0x80000,
            tickSpacing: 60,
            hooks: IHooks(v4Hook)
        });*/

        if(freeSwap) {
            //purchase NFT if opting for freeSwap and do not have one
            if(IERC721(nftAddress).balanceOf(sender) < 1) {
                customInterface(address(key.hooks)).purchaseMembership(key, 0.1 ether, sender);
            }
            relayCall(address(safe), data);
            // We use the hash of the tx to relay has a nonce as this is unique
            //uint256 nonce = uint256(keccak256(abi.encode(this, manager, safe, data)));
            payFee(manager, safe, uint256(keccak256(abi.encode(this, manager, safe, data))));
        }
        
        customInterface(router).swap(
            key, 
            IPoolManager.SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            }),
            TestSettings({
                withdrawTokens: true,
                settleUsingTransfer: true
            }),
            abi.encode(msg.sender)
        );
    }
}
