// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";

/// @title PrivacyStakingPoolFactory
/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
///         The pool constructor receives the caller as `creator`, so the caller
///         retains the right to initialize and fund the deployed pool directly.
contract PrivacyStakingPoolFactory {
    error ZeroAddressToken();

    address[] private _allPools;
    mapping(address owner => address[]) private _poolsByOwner;

    event PoolCreated(
        address indexed owner, address indexed pool, address indexed stakeToken, address rewardToken, uint256 poolCount
    );

    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
            revert ZeroAddressToken();
        }

        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));

        _allPools.push(pool);
        _poolsByOwner[msg.sender].push(pool);

        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
    }

    function poolCount() external view returns (uint256) {
        return _allPools.length;
    }

    function getPoolsByOwner(address owner) external view returns (address[] memory) {
        return _poolsByOwner[owner];
    }

    function getAllPools() external view returns (address[] memory) {
        return _allPools;
    }
}
