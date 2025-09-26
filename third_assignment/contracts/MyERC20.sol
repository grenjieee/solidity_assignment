// contracts/MyERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyERC20 is Initializable, ERC20Upgradeable{

    function initialize() public initializer {
        __ERC20_init("MyERC20", "ERC20");       // 初始化 ERC721 名称/符号
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}