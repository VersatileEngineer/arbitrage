// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

/// @title arbitrage between USDC-ETH 0.3% and 0.05% pool
/// @author Kris
/// @notice users can make a profit using the difference of price between 0.3% and 0.05% pool
contract Arbitrage {
    /* ======== STATE VARIABLES ======== */

    address public usdc;
    address public weth;
    IUniswapV3Pool public pool05;
    IUniswapV3Pool public pool3;
    ISwapRouter public swapRouter;

    /* ======== INITIALIZATION ======== */

    constructor(
        address _usdc,
        address _weth,
        address _pool05,
        address _pool3,
        address _router
    ) {
        usdc = _usdc;
        weth = _weth;
        pool05 = IUniswapV3Pool(_pool05);
        pool3 = IUniswapV3Pool(_pool3);
        swapRouter = ISwapRouter(_router);
    }

    /* ======== USER FUNCTIONS ======== */
    /**
     *  @notice implement arbitrage between USDC-Weth 0.3% and 0.05%
     *  @param amount uint256
     */

    function arbitrage(uint256 amount) external {
        require(amount > 0, "No zero amount");

        // Calculate the current price of USDC-ETH in both pools
        uint256 pool05Price = calculatePrice(pool05);
        uint256 pool3Price = calculatePrice(pool3);

        // Swap between 0.05% pool and 0.3% pool
        if (pool05Price > pool3Price) {
            _swap(3000, 500, amount);
        } else {
            _swap(500, 3000, amount);
        }
    }

    /**
     *  @notice implement swap inside poo1 and poo2 by comparision
     *  @param poo1 uint24
     *  @param poo2 uint24
     *  @param amount uint256
     */
    function _swap(uint24 poo1, uint24 poo2, uint256 amount) internal {
        // Transfer the specified amount of weth to this contract.
        TransferHelper.safeTransferFrom(
            address(weth),
            msg.sender,
            address(this),
            amount
        );

        // swap second in pool1 with weth
        uint256 usdcAmountOut = swapExactInputSingle(amount, weth, usdc, poo1);

        // swap second in pool2 with usdc
        uint256 wethAmountOut = swapExactInputSingle(
            usdcAmountOut,
            usdc,
            weth,
            poo2
        );

        // Transfer  weth to sender.
        TransferHelper.safeTransferFrom(
            address(weth),
            address(this),
            msg.sender,
            wethAmountOut
        );
    }

    /**
     *  @notice singleswap implementation
     *  @param token1 address
     *  @param token2 address
     *  @param poolFee uint24
     */
    function swapExactInputSingle(
        uint256 amountIn,
        address token1,
        address token2,
        uint24 poolFee
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend weth.
        TransferHelper.safeApprove(
            address(token1),
            address(swapRouter),
            amountIn
        );

        // swap first in pool1 with weth
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp, // Set a reasonable deadline
                amountIn: amountIn,
                amountOutMinimum: 0, // Set a minimum acceptable amount out
                sqrtPriceLimitX96: 0 // No price limit
            });
        amountOut = swapRouter.exactInputSingle(params);
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */
    /**
     *  @notice calcualte the pool's price
     *  @param pool IUniswapV3Pool
     */
    function calculatePrice(
        IUniswapV3Pool pool
    ) internal view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return (sqrtPriceX96 * sqrtPriceX96) >> 128;
    }
}
