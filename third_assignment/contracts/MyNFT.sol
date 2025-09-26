// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MyNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public nextTokenId;
    mapping(uint256 => string) private _tokenURIs;

    function initialize() public initializer {
        // 初始化 ERC721 名称/符号
        __ERC721_init("MyNFT", "MNFT");
        // 初始化 Ownable
        __Ownable_init();
        // 初始化可升级的 ReentrancyGuard
        __ReentrancyGuard_init();
    }

    // 铸币时传入自定义元数据地址
    function mint(address to, string memory tokenURI) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI); // 将元数据链接设置为 IPFS 地址
        nextTokenId++;
    }

    // 允许用户查询自己的 NFT 的元数据地址
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    // 设置特定 token 的元数据 URI
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
    }

}
