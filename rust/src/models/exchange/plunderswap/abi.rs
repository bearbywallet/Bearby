use zilpay::alloy::sol;

sol! {
    interface IPlunderRouterV2 {
        function getAmountsOut(uint256 amountIn, address[] path)
            external view returns (uint256[] amounts);
    }
}

sol! {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams params)
        external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

sol! {
    interface IERC20 {
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
    }
}

sol! {
    function swapV2(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] path,
        uint256 deadline,
        bool nativeIn,
        bool nativeOut,
        bool supportingFeeOnTransfer
    ) external payable;

    function swapV3ExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        uint160 sqrtPriceLimitX96,
        uint256 deadline,
        bool nativeIn,
        bool nativeOut
    ) external payable returns (uint256 amountOut);

}

sol! {
    interface IWZIL {
        function deposit() external payable;
        function withdraw(uint256 amount) external;
    }
}
