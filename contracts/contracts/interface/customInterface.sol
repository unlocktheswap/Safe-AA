// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

/**
 * @title Compatibility with 0.8.20
 * @author PizzaHi5 
 * @notice Due to compatibility mismatch, a make-shift approach is used below:
    //Currency = address
    //BalanceDelta = int256
 */
interface customInterface {
    function swap(
        PoolKey memory key, 
        IPoolManager.SwapParams memory params, 
        TestSettings memory testSettings) 
        external payable returns (int256 delta);

    function purchaseMembership (
        PoolKey calldata key,
        uint256 value)
        external payable returns (uint256 tokenId);
}

/// @notice Returns the key for identifying a pool
struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically
    address currency0; //changed from Currency
    /// @notice The higher currency of the pool, sorted numerically
    address currency1; //changed from Currency
    /// @notice The pool swap fee, capped at 1_000_000. The upper 4 bits determine if the hook sets any fees.
    uint24 fee;
    /// @notice Ticks that involve positions must be a multiple of tick spacing
    int24 tickSpacing;
    /// @notice The hooks of the pool
    IHooks hooks;
}

interface IPoolManager {
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
    struct ModifyPositionParams {
    // the lower and upper tick of the position
    int24 tickLower;
    int24 tickUpper;
    // how to modify the liquidity
    int256 liquidityDelta;
    }
}

struct TestSettings {
    bool withdrawTokens;
    bool settleUsingTransfer;
}

interface IHooks {
    /// @notice The hook called before the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @param hookData Arbitrary data handed into the PoolManager by the initializer to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        returns (bytes4);

    /// @notice The hook called after the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param sqrtPriceX96 The sqrt(price) of the pool as a Q64.96
    /// @param tick The current tick after the state of a pool is initialized
    /// @param hookData Arbitrary data handed into the PoolManager by the initializer to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before a position is modified
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for modifying the position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after a position is modified
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for modifying the position
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        int256 delta,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param params The parameters for the swap
    /// @param delta The amount owed to the locker (positive) or owed to the pool (negative)
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        int256 delta,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}