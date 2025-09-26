# NFT 拍卖市场

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

> ### contract 介绍
>
> - contract/Auction.sol 拍卖的实际载体合约.里面的函数有竞价、结束拍卖;以及一些拍卖属性数据;构造时传入 NFT 相关内容有代理合约地址和 NFT 的 ID、拍卖发起者、Clainlink 相关实现的合约地址、本次拍卖起拍价、拍卖的持续时间.有 2 个 event 用来记录竞价、结束拍卖.
> - contract/AuctionFactory.sol 拍卖合约工厂合约.里面有创建拍卖的函数,以及所有拍卖地址的状态变量数据.
> - contract/MyNFT.sol NFT 合约,里面有铸造 NFT 的函数,因为继承了 REC721 协议,所以有 ERC721 协议中的内容都可以使用.
> - contract/PriceFeed.sol Chainlink 预言机合约,主要功能是用来将对应的 ERC20 代币或者 ETH 转化为相应 USD 的价值,用于比价使用.
> - contract/MyERC20.sol 继承 ERC20 合约,主要功能是用来给用户进行代币的 ERC20 对 auction 的合约进行授权(approve)往该合约中转账额度的作用.
>
> ### 测试用例介绍
>
> - test/totalProceed.js 测试 NFT 拍卖市场的整体功能.本来编写了本地测试以及 Sepolia 链上测试,但是由于预言机要借用的链上数据,所以只完成链上测试.具体测试步骤在该 js 文件的注释中.
>
> ### 部署脚本介绍
>
> - deploy/deploy.js 合约部署的 js 脚本.
>
> ### 记录文件介绍
>
> - .cache/\*.json 对应部署上线的合约的相关记录信息.
>
> ### 测试结果
> - 测试结果在 test/test_result.png.  
