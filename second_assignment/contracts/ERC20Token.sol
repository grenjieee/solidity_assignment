// SPDX-License-Identifier: MIT
pragma solidity ~0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyERC20 is IERC20 {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 8;

    uint256 private _totalSupply;
    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(owner, initialSupply * 10**decimals);
    }

    // --- IERC20 实现 ---
    // 返回代币总供应量
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // 查询某个账户余额
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // 转账函数
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // 查询授权额度
    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    // 授权函数
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 代扣转账
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "ERC20: allowance exceeded");
        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    // --- 内部逻辑 ---
    // 内部转账逻辑，复用在 transfer 和 transferFrom
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to zero address");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // 内部铸币逻辑
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // --- 额外功能: 仅合约所有者可增发 ---
    function mint(uint256 amount) public onlyOwner {
        _mint(owner, amount * 10**decimals);
    }
}