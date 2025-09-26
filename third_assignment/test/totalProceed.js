const { ethers, deployments, upgrades, network } = require("hardhat");
const { expect } = require("chai");

describe("NftAuctionV1 Test", function () {
    let deployer, bidder1, bidder2;
    let erc20, nft, priceFeed, auctionFactory, auction;
    let currentTokenID;

    before(async function () { 
        this.timeout(1800000);
        [deployer, bidder1, bidder2] = await ethers.getSigners();
        console.log("当前网络:", network.name);
        console.log("Deployer地址:", deployer.address);

        if (network.name === "hardhat") {
            // ? 0. 部署合约
            // ========== 部署 ERC20 ==========
            const ERC20 = await ethers.getContractFactory("MyERC20");
            erc20 = await upgrades.deployProxy(ERC20, [], {
                initializer: "initialize",
            });
            await erc20.waitForDeployment();
            // ========== 部署 NFT ==========
            const NFT = await ethers.getContractFactory("MyNFT");
            nft = await upgrades.deployProxy(NFT, [], {
                initializer: "initialize",
            });
            await nft.waitForDeployment();
            // ========== 部署 PriceFeed ==========
            const PriceFeed = await ethers.getContractFactory("PriceFeed");
            priceFeed = await upgrades.deployProxy(PriceFeed, [], {
                initializer: "initialize",
            });
            await priceFeed.waitForDeployment();

            // ? 1. 给PriceFeed中进行 ETH/REC20 => USD的setPriceFeed的映射建立,此处传入的是MetaMask钱包中的对应币种的合约地址
            await priceFeed.setPriceFeed(ethers.ZeroAddress, "0x694AA1769357215DE4FAC081bf1f309aDC325306");
            await priceFeed.setPriceFeed(await erc20.getAddress(), "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E");

            // ========== 部署 AuctionFactory ==========
            const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
            auctionFactory = await upgrades.deployProxy(
                AuctionFactory,
                [await priceFeed.getAddress()],
                {
                    initializer: "initialize",
                }
            );
            await auctionFactory.waitForDeployment();

            console.log("ERC20:", await erc20.getAddress());
            console.log("NFT:", await nft.getAddress());
            console.log("PriceFeed:", await priceFeed.getAddress());
            console.log("AuctionFactory:", await auctionFactory.getAddress());

            // ? 2. 使用MyNFT去进行铸币
            let tokenId = await nft.connect(deployer).nextTokenId();
            await nft.connect(deployer).mint(deployer.address, "https://black-geographical-louse-890.mypinata.cloud/ipfs/bafkreiakgpqxqsm23hlx6x63zfg4irzpeykvz5b5xcpaxx7c43wqpgpkje");

            // Mint ERC20 给 bidder1 & bidder2
            await erc20.mint(bidder1.address, ethers.parseUnits("10000", 18));
            await erc20.mint(bidder2.address, ethers.parseUnits("10000", 18));

            // ? 3. 将对应的NFT给approve给拍卖工厂
            await nft.connect(deployer).approve(await auctionFactory.getAddress(), tokenId);

            // ? 4. 工厂创建对应的Auction对象,使用createAuction(MyNFT代理合约地址,对应NFT的tokenId,起拍价,拍卖持续时间)
            const tx = await auctionFactory.connect(deployer).createAuction(
                await nft.getAddress(), tokenId, 1, 60
            );

            await tx.wait();
            let auctionAddress = await auctionFactory.getAllAuctions();
            console.log("auctions:", auctionAddress);

            auction = await ethers.getContractAt("Auction", auctionAddress[auctionAddress.length - 1]);
            console.log("当前Auction:", auctionAddress[auctionAddress.length - 1]);
        } else { 
            const fs = require("fs");
            const path = require("path");

            const nftData = JSON.parse(fs.readFileSync(path.join(__dirname, "../.cache/proxyMyNFT.json")));
            const priceFeedData = JSON.parse(fs.readFileSync(path.join(__dirname, "../.cache/proxyPriceFeed.json")));
            const factoryData = JSON.parse(fs.readFileSync(path.join(__dirname, "../.cache/proxyAuctionFactory.json")));

            nft = await ethers.getContractAt(nftData.abi, nftData.proxyAddress);
            priceFeed = await ethers.getContractAt(priceFeedData.abi, priceFeedData.proxyAddress);
            auctionFactory = await ethers.getContractAt(factoryData.abi, factoryData.proxyAddress);

            // ? 1. 给PriceFeed中进行 ETH/REC20 => USD的setPriceFeed的映射建立,此处传入的是MetaMask钱包中的对应币种的合约地址
            await priceFeed.setPriceFeed(ethers.ZeroAddress, "0x694AA1769357215DE4FAC081bf1f309aDC325306");
            const USCDAddress = "0x1c7d4b196cb0c7b01d743fbc6116a902379c7238";
            await priceFeed.setPriceFeed(USCDAddress, "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E");

            // ? 2. 使用MyNFT去进行铸币
            let tokenIdBigInt = (await nft.connect(deployer).nextTokenId());
            let tokenId = Number(tokenIdBigInt);
            console.log("当前NFT的tokenId:", tokenId);
            currentTokenID = tokenId;
            const NFTMint = await nft.connect(deployer).mint(deployer.address, "https://black-geographical-louse-890.mypinata.cloud/ipfs/bafkreiakgpqxqsm23hlx6x63zfg4irzpeykvz5b5xcpaxx7c43wqpgpkje");
            await NFTMint.wait();

            const owner = await nft.ownerOf(tokenId);
            console.log("NFT owner:", owner);

            // ? 3. 将对应的NFT给approve给拍卖工厂
            const NFTTransfer = await nft.connect(deployer).approve(await auctionFactory.getAddress(), tokenId);
            await NFTTransfer.wait();

            const approved = await nft.getApproved(tokenId);
            console.log("NFT approved to:", approved);

            // ? 4. 工厂创建对应的Auction对象,使用createAuction(MyNFT代理合约地址,对应NFT的tokenId,起拍价,拍卖持续时间)
            const tx = await auctionFactory.connect(deployer).createAuction(
                await nft.getAddress(), tokenId, 1, 60
            );

            await tx.wait();
            let auctionAddress = await auctionFactory.getAllAuctions();

            auction = await ethers.getContractAt("Auction", auctionAddress[auctionAddress.length - 1]);
            console.log("当前Auction:", auctionAddress[auctionAddress.length - 1]);

            erc20 = await ethers.getContractAt("MyERC20", USCDAddress);
        }
    });

    it("bid,check USD value,check auction ended status", async function () {
        this.timeout(1800000);

        // ? 5. 在对应币种的合约地址上调用approve给对应拍卖
        const bidder1ApproveERC20 = await erc20.connect(bidder1).approve(await auction.getAddress(), ethers.parseUnits("1000", 6));
        const bidder2ApproveERC20 = await erc20.connect(bidder2).approve(await auction.getAddress(), ethers.parseUnits("1000", 6));
        await bidder1ApproveERC20.wait();
        await bidder2ApproveERC20.wait();

        // ? 6. 多用户进行NFT竞价(使用多币种进行)
        // 出价
        const bid_first = await auction.connect(bidder1).bid(await erc20.getAddress(), ethers.parseUnits("5", 6));
        await bid_first.wait();
        const highestBidder_first = await auction.highestBidder();
        const highestBidToken_first = await auction.highestBidToken();
        const highestBidRawAount_first = await auction.highestBidRawAmount();
        // 验证当前Auction的Auction信息是否更新正确
        expect(highestBidder_first).to.equal(bidder1.address);
        expect(ethers.getAddress(highestBidToken_first)).to.equal(ethers.getAddress(await erc20.getAddress()));
        expect(highestBidRawAount_first).to.equal(ethers.parseUnits("5", 6));

        const bid_second = await auction.connect(bidder2).bid(ethers.ZeroAddress, 0, { value: ethers.parseEther("0.005") });
        await bid_second.wait();
        const highestBidder_second = await auction.highestBidder();
        const highestBidToken_second = await auction.highestBidToken();
        const highestBidRawAount_second = await auction.highestBidRawAmount();
        await new Promise((resolve) => setTimeout(resolve, 3 * 1000));
        // 验证当前Auction的Auction信息是否更新正确
        expect(highestBidder_second).to.equal(bidder2.address);
        expect(ethers.getAddress(highestBidToken_second)).to.equal(ethers.getAddress(ethers.ZeroAddress));
        expect(highestBidRawAount_second).to.equal(ethers.parseEther("0.005"));

        // ? 7. 设置区块时间跳到本来应该拍卖结束的时间后
        await new Promise((resolve) => setTimeout(resolve, 61 * 1000));

        // ? 8. 检查对应的NFT的归属权(ownerOf)是否属于拍卖赢家,对应的竞拍高价是否到账拍卖发起者,并且本次拍卖的结束标志位是否成功修改
        // * 先进行竞价,看看是否会走到endAuction逻辑
        const bid_third = await auction.connect(bidder1).bid(ethers.ZeroAddress, 0, { value: ethers.parseEther("0.01") });
        await bid_third.wait();
        expect(await nft.ownerOf(currentTokenID)).to.equal(bidder2.address);
        const highestBidder_third = await auction.highestBidder();
        const highestBidRawAount_third = await auction.highestBidRawAmount();
        await new Promise((resolve) => setTimeout(resolve, 3 * 1000));
        expect(highestBidder_third).to.equal(bidder2.address);
        expect(highestBidRawAount_third).to.equal(ethers.parseEther("0.005"));
        // * 验证结束标志位是否成功修改
        expect(await auction.ended()).to.equal(true);
    })
})