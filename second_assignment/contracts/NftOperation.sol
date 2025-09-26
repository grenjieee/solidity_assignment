// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title SimpleERC721WithTokenURI
/// @notice 直接继承 ERC721，并自己维护 tokenURI 存储
contract SimpleERC721WithTokenURI is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokenId -> tokenURI
    mapping(uint256 => string) private _tokenURIs;

    address public owner;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        owner = msg.sender;
    }

    /// @notice 铸造 NFT 并设置 tokenURI
    /// @param recipient 接受 NFT 的地址
    /// @param uri token metadata 的链接（如 ipfs://CID/... 或 https://gateway...）
    /// @return newTokenId 新铸造的 tokenId
    function mintNFT(address recipient, string memory uri) external returns (uint256) {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();

        _safeMint(recipient, newId);
        _setTokenURI(newId, uri);

        return newId;
    }

    /// @dev 内部设置 tokenURI（会覆盖已有的）
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// @notice 返回 tokenURI（若不存在则 revert）
    /// @param tokenId token id
    /// @return tokenURI 字符串
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _uri = _tokenURIs[tokenId];
        return _uri;
    }

    /// @notice 可选：合约拥有者回收合约内 ETH
    function withdraw() external {
        require(msg.sender == owner, "only owner");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}