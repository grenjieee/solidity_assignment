// contracts/PriceFeed.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PriceFeed is Initializable, ReentrancyGuardUpgradeable{
    // token => Chainlink priceFeed (ETH 用 address(0))
    mapping(address => address) public priceFeeds;

    function initialize() public initializer {
        // 初始化可升级的 ReentrancyGuard
        __ReentrancyGuard_init();
    }

    // 设置预言机
    function setPriceFeed(address token, address feed) external {
        priceFeeds[token] = feed;
    }

    // 获取 Chainlink 原始价格
    function getLatestPrice(address token) public view returns (int256 price, uint8 decimals) {
        require(priceFeeds[token] != address(0), "Price feed not set");
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeeds[token]);
        (, int256 answer,,,) = feed.latestRoundData();
        price = answer;
        decimals = feed.decimals();
    }

    /// @notice 把 token 数量换算成 USD (18 decimals)
    /// @param token ERC20 地址（ETH 用 address(0)）
    /// @param amount 代币数量 (原始单位, 按 ERC20 decimals)
    function getUSDValue(address token, uint256 amount) external view returns (uint256) {
        (int256 price, uint8 priceDecimals) = getLatestPrice(token);
        require(price > 0, "Invalid price");

        uint256 tokenDecimals;
        if (token == address(0)) {
            // ETH 默认 18 decimals
            tokenDecimals = 18;
        } else {
            tokenDecimals = IERC20Metadata(token).decimals();
        }

        // 转换公式:
        // amount * price / (10^tokenDecimals)
        // 然后把 priceDecimals 对齐到 18 decimals
        uint256 usdValue = (amount * uint256(price)) / (10 ** tokenDecimals);

        if (priceDecimals < 18) {
            usdValue = usdValue * (10 ** (18 - priceDecimals));
        } else if (priceDecimals > 18) {
            usdValue = usdValue / (10 ** (priceDecimals - 18));
        }

        return usdValue;
    }
}
