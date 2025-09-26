// contracts/Auction.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceFeed.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Auction is Initializable, ReentrancyGuardUpgradeable{
    // 拍卖的 NFT
    IERC721 public nft;
    // 价格预言机
    PriceFeed public priceFeed;
    // 拍卖的卖家
    address public seller;
    // 拍卖的 NFT ID
    uint256 public tokenId;
    // 拍卖的起拍价(USD)
    uint256 public reservePrice;
    // 拍卖开始时间
    uint256 public startTime;
    // 拍卖结束时间
    uint256 public endTime;
    // 拍卖结束标志位
    bool public ended;
    // 最高出价者
    address public highestBidder;
    // 最高出价的代币信息
    address public highestBidToken;    // ETH = address(0)
    // 最高出价的原代币价格
    uint256 public highestBidRawAmount; // 原始数量 (ETH/USDC/DAI…)
    // 最高出价的USD价格
    uint256 public highestBidUSD;      // 折算成 USD 的数值 (18 decimals)

    event BidPlaced(address indexed bidder, address indexed token, uint256 amount, uint256 usdValue);
    event AuctionEnded(address winner, address token, uint256 amount, uint256 usdValue);

    modifier onlyAfterEnd() {
        require(block.timestamp >= endTime, "Auction not ended yet");
        _;
    }

    function initialize(
        address _nft,
        uint256 _tokenId,
        address _seller,
        address _priceFeed,
        uint256 _reservePrice,
        uint256 _duration
    ) public initializer {
        nft = IERC721(_nft);
        tokenId = _tokenId;
        seller = _seller;
        priceFeed = PriceFeed(_priceFeed);
        reservePrice = _reservePrice;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
        // 初始化可升级的 ReentrancyGuard
        __ReentrancyGuard_init();
    }

    /// @notice 出价 (token=0 表示 ETH)
    function bid(address token, uint256 amount) external payable nonReentrant{
        // 0. 如果已超时 -> 自动结束拍卖
        if (block.timestamp >= endTime) {
            endAuction();
            return;
        } else{
            // 已结束拍卖则禁止竞价
            require(!ended, "Auction already ended");

            uint256 bidInUSD;
            uint256 rawAmount;

            // 1. ETH 出价
            if (token == address(0)) {
                require(msg.value > 0, "ETH bid must be > 0");
                rawAmount = msg.value;
                bidInUSD = priceFeed.getUSDValue(address(0), msg.value);
            } else {
                // 2. ERC20 出价
                require(amount > 0, "Token bid must be > 0");
                require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
                rawAmount = amount;
                bidInUSD = priceFeed.getUSDValue(token, amount);
            }

            // 3. 确认高于当前最高价 & 保底价
            require(bidInUSD > highestBidUSD, "Bid too low in USD terms");
            require(bidInUSD >= reservePrice, "Bid below reserve price");

            // 4. 退还上一个最高价
            if (highestBidder != address(0)) {
                if (highestBidToken == address(0)) {
                    payable(highestBidder).transfer(highestBidRawAmount);
                } else {
                    require(
                        IERC20(highestBidToken).transfer(highestBidder, highestBidRawAmount),
                        "Refund failed"
                    );
                }
            }

            // 5. 更新最高价记录
            highestBidder = msg.sender;
            highestBidToken = token;
            highestBidRawAmount = rawAmount;
            highestBidUSD = bidInUSD;

            emit BidPlaced(msg.sender, token, highestBidRawAmount, highestBidUSD);
        }

        
    }

    /// @notice 结束拍卖，转移 NFT 与资金
    function endAuction() internal onlyAfterEnd {
        require(!ended, "Auction already ended");
        ended = true;

        if (highestBidder != address(0)) {
            // 成交：NFT 转给中标者，卖家收款
            nft.transferFrom(address(this), highestBidder, tokenId);

            if (highestBidToken == address(0)) {
                payable(seller).transfer(highestBidRawAmount);
            } else {
                require(
                    IERC20(highestBidToken).transfer(seller, highestBidRawAmount),
                    "Payout failed"
                );
            }

            emit AuctionEnded(highestBidder, highestBidToken, highestBidRawAmount, highestBidUSD);
        } else {
            // 流拍：NFT 退还给卖家
            nft.transferFrom(address(this), seller, tokenId);
        }
    }

    receive() external payable {
    }

}