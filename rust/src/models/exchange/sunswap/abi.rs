use zilpay::alloy::sol;

sol! {
    struct Quote {
        uint8 routeType;
        uint256 amountOut;
        uint24 fee;
        bytes v3Path;
    }

    function quoteBestRoute(address tokenIn, address tokenOut, uint256 amountIn)
        external returns (Quote best);
}

sol! {
    interface IERC20 {
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
    }
}

sol! {
    function swapExactInputSingle(
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

    /// Multi-hop V3 swap over a packed `addr ‖ fee ‖ addr ‖ … ‖ addr` path.
    /// `tokenIn`/`tokenOut` are explicit because the fee-router's `_prepareInput`
    /// needs them for pull/approve/wrap assertions regardless of the packed path
    /// (see SunFeeRouter.sol `_prepareInput`).
    function swapExactInput(
        bytes path,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        bool nativeIn,
        bool nativeOut
    ) external payable returns (uint256 amountOut);
}

sol! {
    interface IWTRX {
        function deposit() external payable;
        function withdraw(uint256 amount) external;
    }
}
