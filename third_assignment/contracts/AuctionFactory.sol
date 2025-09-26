// contracts/AuctionFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Auction.sol";
import "./PriceFeed.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract AuctionFactory is Initializable, ReentrancyGuardUpgradeable{
    Auction[] public auctions;
    PriceFeed public priceFeed;

    function initialize(address _priceFeed) public initializer {
        priceFeed = PriceFeed(_priceFeed);
        // 初始化可升级的 ReentrancyGuard
        __ReentrancyGuard_init();
    }

    event AuctionCreated(address auctionAddress, address seller, uint256 tokenId);

    function createAuction(
        address nftAddress,
        uint256 nftId,
        uint256 reservePrice,
        uint256 duration
    ) external nonReentrant{

        Auction newAuction = new Auction(
            nftAddress,
            nftId,
            msg.sender,
            address(priceFeed),
            reservePrice,
            duration
        );

        // 转移 NFT 给 Auction 合约托管
        IERC721(nftAddress).transferFrom(msg.sender, address(newAuction), nftId);

        auctions.push(newAuction);

        emit AuctionCreated(address(newAuction), msg.sender, nftId);
    }

    function getAllAuctions() external view returns (Auction[] memory) {
        return auctions;
    }
}
