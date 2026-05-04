// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";

contract PrivacyStakingPoolFactoryTest is FhevmTest {
    uint256 internal constant CREATOR_PK = 0xC0FFEE;

    PrivacyStakingPoolFactory internal factory;
    ERC7984Mock internal stakeToken;
    ERC7984Mock internal rewardToken;
    address internal creator;

    function setUp() public override {
        super.setUp();

        creator = vm.addr(CREATOR_PK);

        vm.prank(creator);
        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");

        vm.prank(creator);
        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

        factory = new PrivacyStakingPoolFactory();
    }

    function test_createPoolTracksDeploymentAndPreservesCreator() public {
        vm.prank(creator);
        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
        address[] memory ownerPools = factory.getPoolsByOwner(creator);
        address[] memory allPools = factory.getAllPools();

        assertEq(pool.creator(), creator);
        assertEq(address(pool.stakeToken()), address(stakeToken));
        assertEq(address(pool.rewardToken()), address(rewardToken));
        assertEq(factory.poolCount(), 1);
        assertEq(ownerPools.length, 1);
        assertEq(ownerPools[0], poolAddress);
        assertEq(allPools.length, 1);
        assertEq(allPools[0], poolAddress);
    }

    function test_createPoolRevertsForZeroAddressToken() public {
        vm.prank(creator);
        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));

        vm.prank(creator);
        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
    }
}
