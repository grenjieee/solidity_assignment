// * 引入Hardhat的部署和升级工具
const { deployments, upgrades } = require("hardhat");

// * 引入Node.js内置模块,用于文件操作
const fs = require('fs');
const path = require('path');

module.exports = async ({ getNamedAccounts, deployments }) => {
    // * 从deployments中提取save方法,用于保存部署信息到hardhat-deploy的部署记录
    const { save } = deployments;

    // * 获取预定义的部署账户
    const { deployer } = await getNamedAccounts();

    console.log("所有合约部署的用户地址：", deployer);

    const MyNFTObject = await ethers.getContractFactory("MyNFT");
    const PriceFeedObject = await ethers.getContractFactory("PriceFeed");
    const AuctionFactoryObject = await ethers.getContractFactory("AuctionFactory");

    // ? 1.部署MyNFT.sol|PriceFeed.sol|AuctionFactory.sol(因为Auction.sol是由工厂生成的不需要部署,MyERC20.sol是用来给参加拍卖使用ERC20的用户授权转账到拍卖合约的需要在ERC20代理地址调用)
    // 通过代理合约部署
    // 通过OpenZeppelin Hardhat Upgrades插件部署可升级代理合约
    const MyNFTProxy = await upgrades.deployProxy(
        MyNFTObject,
        [],
        {
            initializer: "initialize",
        }
    );
    // * 等待代理合约部署完成,确保链上已经有合约地址
    await MyNFTProxy.waitForDeployment();
    // * 获取代理合约地址
    const MyNFTProxyAddress = await MyNFTProxy.getAddress();
    // * 获取实现合约(Implementation)的地址
    const MyNFTimplAddress = await upgrades.erc1967.getImplementationAddress(MyNFTProxyAddress);
    console.log("MyNFT合约地址：", MyNFTProxyAddress);
    console.log("MyNFT实现合约地址：", MyNFTimplAddress);

    const PriceFeedProxy = await upgrades.deployProxy(
        PriceFeedObject,
        [],
        {
            initializer: "initialize",
        }
    );
    await PriceFeedProxy.waitForDeployment();
    const PriceFeedProxyAddress = await PriceFeedProxy.getAddress();
    const PriceFeedimplAddress = await upgrades.erc1967.getImplementationAddress(PriceFeedProxyAddress);
    console.log("PriceFeed合约地址：", PriceFeedProxyAddress);
    console.log("PriceFeed实现合约地址：", PriceFeedimplAddress);

    const AuctionFactoryProxy = await upgrades.deployProxy(
        AuctionFactoryObject,
        [PriceFeedProxyAddress],
        {
            initializer: "initialize",
        }
    );
    await AuctionFactoryProxy.waitForDeployment();
    const AuctionFactoryProxyAddress = await AuctionFactoryProxy.getAddress();
    const AuctionFactoryimplAddress = await upgrades.erc1967.getImplementationAddress(AuctionFactoryProxyAddress);
    console.log("AuctionFactory合约地址：", AuctionFactoryProxyAddress);
    console.log("AuctionFactory实现合约地址：", AuctionFactoryimplAddress);

    // ? 2. 进行相关合约的内容记录
    // * 定义本地存储路径,用于保存代理和实现地址及ABI信息
    // 定义存储路径
    const cacheDir = path.join(__dirname, "../.cache");

    // 如果不存在 .cache 目录，则创建
    if (!fs.existsSync(cacheDir)) {
        fs.mkdirSync(cacheDir, { recursive: true });
    }
    const MyNFTStorePath = path.join(__dirname, "../.cache/proxyMyNFT.json");
    const PriceFeedStorePath = path.join(__dirname, "../.cache/proxyPriceFeed.json");
    const AuctionFactoryStorePath = path.join(__dirname, "../.cache/proxyAuctionFactory.json");

    // * 将proxy地址、实现地址、合约ABI写入JSON文件,方便前端或测试脚本使用
    fs.writeFileSync(
        MyNFTStorePath,
        JSON.stringify({
            proxyAddress: MyNFTProxyAddress,
            implAddress: MyNFTimplAddress,
            abi: MyNFTObject.interface.format("json"),
        })
    );
    fs.writeFileSync(
        PriceFeedStorePath,
        JSON.stringify({
            proxyAddress: PriceFeedProxyAddress,
            implAddress: PriceFeedimplAddress,
            abi: PriceFeedObject.interface.format("json"),
        })
    );
    fs.writeFileSync(
        AuctionFactoryStorePath,
        JSON.stringify({
            proxyAddress: AuctionFactoryProxyAddress,
            implAddress: AuctionFactoryimplAddress,
            abi: AuctionFactoryObject.interface.format("json"),
        })
    );

    // 使用hardhat-deploy保存部署信息
    // save方法会将部署信息写入deployments文件夹中,方便之后使用get方法获取合约实例
    await save("MyNFTInfo", {
        address: MyNFTProxyAddress,
        abi: MyNFTObject.interface.format("json"),
    });
    await save("PriceFeedInfo", {
        address: PriceFeedProxyAddress,
        abi: PriceFeedObject.interface.format("json"),
    });
    await save("AuctionFactoryInfo", {
        address: AuctionFactoryProxyAddress,
        abi: AuctionFactoryObject.interface.format("json"),
    });
};

// ? 3. 打上对应的部署/升级标签
// 为hardhat-deploy定义标签,用于选择性部署
module.exports.tags = ["NFTAuctionV1"]; 