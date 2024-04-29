// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStaking {
    function setBlockReward(
        uint256 _roundId,
        uint256 _blockNumber,
        uint256 _ronixAmount
    ) external;
}
