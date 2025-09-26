// SPDX-License-Identifier: MIT
pragma solidity ~0.8;


contract Voting {
    mapping(string => uint256) public votes;

    // 存储所有候选人名字，resetVotes时遍历使用
    string[] public candidates;

    // 记录哪些地址已经投过票
    mapping(address => bool) private hasVoted;

    // 用来记录所有投票过的地址
    address[] private voterList;

    // 投票给某个候选人
    function vote(string memory _candidate) public {
        require(!hasVoted[msg.sender], "You have already voted");

        // 新候选人情况
        if (votes[_candidate] == 0) {
            candidates.push(_candidate);
        }

        votes[_candidate] += 1;

        // 标记地址已投票
        hasVoted[msg.sender] = true;

        // 保存投票地址
        voterList.push(msg.sender);
    }

    // 查询某个候选人的票数
    function getVotes(string memory _candidate) public view returns (uint256) {
        return votes[_candidate];
    }

    // 重置所有候选人的票数，并允许所有人重新投票
    function resetVotes() public {
        for (uint i = 0; i < candidates.length; i++) {
            votes[candidates[i]] = 0;
        }
        // 清空候选人列表
        delete candidates;

        // 重置所有投票者状态
        for (uint i = 0; i < voterList.length; i++) {
            hasVoted[voterList[i]] = false;
        }
        // 清空投票者记录
        delete voterList;
    }
}