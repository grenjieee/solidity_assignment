// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeggingContract {
    address public owner; // 合约所有者

    // 记录捐赠者地址 -> 捐赠金额
    mapping(address => uint256) public donations;

    // 用于存储捐赠金额最多的前3个地址
    address[] public topDonors;
    // 用于存储捐赠金额最多的前3个金额信息
    uint256[] public topDonations;

    // 事件：记录每次捐赠（额外挑战 1）
    event Donation(address indexed donor, uint256 amount);

    receive() external payable {
    }

    constructor() {
        owner = msg.sender; // 部署者是合约所有者
    }

    // 允许用户捐赠以太币
    function donate() external payable {
        require(isDonationTime(), "Donation is only allowed between 00:00 and 23:45 UTC");
        require(msg.value > 0, "Donation must be greater than 0");

        donations[msg.sender] += msg.value; // 累加捐赠金额

        emit Donation(msg.sender, msg.value); // 触发捐赠事件

        // 更新捐赠排行榜
        _updateTopDonors(msg.sender, donations[msg.sender]);
    }

    // 查询某个地址的捐赠金额
    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }

    // 查询捐赠排行榜（最多捐赠的前三个地址）
    function getTopDonors() external view returns (address[] memory, uint256[] memory) {
        return (topDonors, topDonations);
    }

    // 只有所有者能提取资金
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }

    // 只有所有者能调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 更新捐赠排行榜
    function _updateTopDonors(address donor, uint256 donationAmount) private {
        bool updated = false;
    
        // 如果捐赠者已经在排行榜中，更新其捐赠金额
        for (uint256 i = 0; i < topDonors.length; i++) {
            if (topDonors[i] == donor) {
                topDonations[i] += donationAmount; // 累加捐赠金额
                updated = true;
                break;
            }
        }
    
        // 如果该地址不在排行榜中，则添加它
        if (!updated) {
            if (topDonors.length < 3) {
                topDonors.push(donor);
                topDonations.push(donationAmount);
            } else {
                // 找到捐赠金额最少的一个，替换它
                uint256 minDonationIndex = 0;
                for (uint256 i = 1; i < topDonors.length; i++) {
                    if (topDonations[i] < topDonations[minDonationIndex]) {
                        minDonationIndex = i;
                    }
                }
    
                // 只有在新的捐赠金额大于当前最小的捐赠金额时，才会替换
                if (donationAmount > topDonations[minDonationIndex]) {
                    topDonors[minDonationIndex] = donor;
                    topDonations[minDonationIndex] = donationAmount;
                }
            }
        }
    }

    // 检查当前时间是否在每天的 00:00 到 23:45 UTC 之间
    function isDonationTime() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        uint256 dayStart = currentTime - (currentTime % 1 days); // 获取今天的 00:00:00 时间戳
        uint256 donationStart = dayStart; // 00:00:00 UTC
        uint256 donationEnd = dayStart + 23 hours + 45 minutes; // 23:45:00 UTC

        return currentTime >= donationStart && currentTime <= donationEnd;
    }
}
