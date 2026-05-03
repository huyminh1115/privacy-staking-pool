// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

contract PrivacyStakingPoolTest is FhevmTest {
    uint256 internal constant CREATOR_PK = 0xC0FFEE;
    uint256 internal constant ALICE_PK = 0xA11CE;
    uint256 internal constant BOB_PK = 0xB0B;

    uint64 internal constant INITIAL_REWARD_BUDGET = 1_000;
    uint64 internal constant INTERVAL_REWARD = 10;
    uint64 internal constant ALICE_STAKE = 100;
    uint64 internal constant BOB_STAKE = 300;
    uint256 internal constant INTERVAL = 6 hours;
    uint256 internal constant DEFAULT_INTERVAL_COUNT = 100;
    uint256 internal constant INDEX_SCALE = 1e12;

    ERC7984Mock internal stakeToken;
    ERC7984Mock internal rewardToken;
    PrivacyStakingPool internal pool;

    address internal creator;
    address internal alice;
    address internal bob;

    function setUp() public override {
        super.setUp();
        disableHCUDepthLimit();

        creator = vm.addr(CREATOR_PK);
        alice = vm.addr(ALICE_PK);
        bob = vm.addr(BOB_PK);

        vm.warp(100);

        vm.prank(creator);
        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");

        vm.prank(creator);
        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

        vm.prank(creator);
        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

        _mint(stakeToken, alice, 1_000);
        _mint(stakeToken, bob, 1_000);
        _mint(rewardToken, creator, 5_000);
    }

    function test_initializeFundsPoolAndSetsRewardConfig() public {
        uint64 creatorRewardBalanceBefore = _decryptTokenBalance(rewardToken, CREATOR_PK, creator);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + INTERVAL * DEFAULT_INTERVAL_COUNT;
        _initializePool(INITIAL_REWARD_BUDGET, startTime, endTime);

        assertTrue(pool.initialized());
        assertEq(pool.creator(), creator);
        assertEq(pool.poolStartTime(), startTime);
        assertEq(pool.poolEndTime(), endTime);
        assertEq(pool.lastDistributionTimestamp(), startTime);
        assertEq(uint256(pool.distState()), uint256(PrivacyStakingPool.DistState.Idle));
        assertEq(
            _decryptTokenBalance(rewardToken, CREATOR_PK, creator), creatorRewardBalanceBefore - INITIAL_REWARD_BUDGET
        );
    }

    function test_stakeMovesTokensAndTracksEncryptedStake() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);

        uint64 aliceStakeBalanceBefore = _decryptTokenBalance(stakeToken, ALICE_PK, alice);
        _stake(alice, ALICE_STAKE);

        assertEq(_decryptUserStake(ALICE_PK, alice), ALICE_STAKE);
        assertEq(_decryptTokenBalance(stakeToken, ALICE_PK, alice), aliceStakeBalanceBefore - ALICE_STAKE);
        assertEq(_decryptTotalStaked(), ALICE_STAKE);
        assertEq(pool.getUserIndex(alice), 0);
    }

    function test_distributionCycleClaimAndUnstake() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
        _stake(alice, ALICE_STAKE);

        uint256 indexDelta = _runDistributionCycle();

        assertEq(indexDelta, uint256(INTERVAL_REWARD) * INDEX_SCALE / ALICE_STAKE);
        assertEq(pool.lastIntervalIndexDelta(), indexDelta);
        assertEq(pool.cumulativeIndex(), indexDelta);
        assertEq(pool.getAPR(), indexDelta * 1460);

        uint64 rewardBalanceBefore = _decryptTokenBalance(rewardToken, ALICE_PK, alice);
        vm.prank(alice);
        pool.claim();

        assertEq(_decryptTokenBalance(rewardToken, ALICE_PK, alice), rewardBalanceBefore + INTERVAL_REWARD);

        uint64 stakeBalanceBefore = _decryptTokenBalance(stakeToken, ALICE_PK, alice);
        _unstake(alice, 40);

        assertEq(_decryptUserStake(ALICE_PK, alice), ALICE_STAKE - 40);
        assertEq(_decryptTotalStaked(), ALICE_STAKE - 40);
        assertEq(_decryptTokenBalance(stakeToken, ALICE_PK, alice), stakeBalanceBefore + 40);
    }

    function test_distributionSplitsRewardsProRataAcrossStakers() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
        _stake(alice, ALICE_STAKE);
        _stake(bob, BOB_STAKE);

        uint256 indexDelta = _runDistributionCycle();

        assertEq(indexDelta, uint256(INTERVAL_REWARD) * INDEX_SCALE / (ALICE_STAKE + BOB_STAKE));

        uint64 aliceRewardBalanceBefore = _decryptTokenBalance(rewardToken, ALICE_PK, alice);
        uint64 bobRewardBalanceBefore = _decryptTokenBalance(rewardToken, BOB_PK, bob);

        vm.prank(alice);
        pool.claim();
        vm.prank(bob);
        pool.claim();

        assertEq(_decryptTokenBalance(rewardToken, ALICE_PK, alice), aliceRewardBalanceBefore + 2);
        assertEq(_decryptTokenBalance(rewardToken, BOB_PK, bob), bobRewardBalanceBefore + 7);
    }

    function test_emptyPoolDistributionSkipsRewardAndResetsState() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);

        uint256 lastTimestampBefore = pool.lastDistributionTimestamp();
        vm.warp(lastTimestampBefore + INTERVAL);

        vm.prank(alice);
        pool.distribute();

        (bytes32 denHandle, bytes32 isEmptyHandle, bytes32 indexDeltaHandleBefore) = pool.getPendingHandles();
        assertEq(indexDeltaHandleBefore, bytes32(0));

        bytes32[] memory handles = new bytes32[](2);
        handles[0] = denHandle;
        handles[1] = isEmptyHandle;
        (uint256[] memory cleartexts, bytes memory proof) = publicDecrypt(handles);

        vm.prank(bob);
        pool.fulfillDenominator(cleartexts, proof);

        (,, bytes32 indexDeltaHandleAfter) = pool.getPendingHandles();
        assertEq(indexDeltaHandleAfter, bytes32(0));
        assertEq(pool.lastIntervalIndexDelta(), 0);
        assertEq(pool.lastDistributionTimestamp(), block.timestamp);
        assertEq(uint256(pool.distState()), uint256(PrivacyStakingPool.DistState.Idle));
    }

    function test_notIdleRevertsDuringDistribution() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
        _stake(alice, ALICE_STAKE);

        vm.warp(pool.lastDistributionTimestamp() + INTERVAL);
        vm.prank(alice);
        pool.distribute();

        (externalEuint64 amount, bytes memory proof) = encryptUint64(1, alice, address(pool));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PrivacyStakingPool.NotIdle.selector));
        pool.stake(amount, proof);

        vm.expectRevert(abi.encodeWithSelector(PrivacyStakingPool.NotIdle.selector));
        pool.distribute();
    }

    function test_intervalTimingEnforced() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
        _stake(alice, ALICE_STAKE);

        vm.warp(pool.lastDistributionTimestamp() + INTERVAL - 1);
        vm.expectRevert(abi.encodeWithSelector(PrivacyStakingPool.IntervalNotElapsed.selector));
        pool.distribute();

        vm.warp(pool.lastDistributionTimestamp() + INTERVAL);
        pool.distribute();
        assertEq(uint256(pool.distState()), uint256(PrivacyStakingPool.DistState.AwaitingDenominator));
    }

    function test_claimRevertsWhenNothingAccrued() public {
        _initializePool(INITIAL_REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
        _stake(alice, ALICE_STAKE);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PrivacyStakingPool.NothingToClaim.selector));
        pool.claim();
    }

    function _initializePool(uint64 budget, uint256 startTime, uint256 endTime) internal {
        vm.prank(creator);
        rewardToken.setOperator(address(pool), type(uint48).max);

        (externalEuint64 budgetInput, bytes memory budgetProof) = encryptUint64(budget, creator, address(pool));

        vm.prank(creator);
        pool.initialize(budgetInput, budgetProof, startTime, endTime);
    }

    function _stake(address user, uint64 amount) internal {
        vm.prank(user);
        stakeToken.setOperator(address(pool), type(uint48).max);

        (externalEuint64 amountInput, bytes memory proof) = encryptUint64(amount, user, address(pool));
        vm.prank(user);
        pool.stake(amountInput, proof);
    }

    function _unstake(address user, uint64 amount) internal {
        (externalEuint64 amountInput, bytes memory proof) = encryptUint64(amount, user, address(pool));
        vm.prank(user);
        pool.unstake(amountInput, proof);
    }

    function _runDistributionCycle() internal returns (uint256 indexDelta) {
        vm.warp(pool.lastDistributionTimestamp() + INTERVAL);
        pool.distribute();

        (bytes32 denHandle, bytes32 isEmptyHandle,) = pool.getPendingHandles();
        bytes32[] memory phase1Handles = new bytes32[](2);
        phase1Handles[0] = denHandle;
        phase1Handles[1] = isEmptyHandle;

        (uint256[] memory phase1Cleartexts, bytes memory phase1Proof) = publicDecrypt(phase1Handles);
        pool.fulfillDenominator(phase1Cleartexts, phase1Proof);

        (,, bytes32 indexDeltaHandle) = pool.getPendingHandles();
        bytes32[] memory phase2Handles = new bytes32[](1);
        phase2Handles[0] = indexDeltaHandle;

        (uint256[] memory phase2Cleartexts, bytes memory phase2Proof) = publicDecrypt(phase2Handles);
        pool.fulfillIndexDelta(phase2Cleartexts, phase2Proof);

        return phase2Cleartexts[0];
    }

    function _mint(ERC7984Mock token, address to, uint64 amount) internal {
        (externalEuint64 amountInput, bytes memory proof) = encryptUint64(amount, creator, address(token));
        vm.prank(creator);
        token.$_mint(to, amountInput, proof);
    }

    function _decryptUserStake(uint256 pk, address user) internal returns (uint64) {
        return _decryptPoolHandle(pk, user, pool.getUserStake(user));
    }

    function _decryptPendingReward(uint256 pk, address user) internal returns (uint64) {
        return _decryptPoolHandle(pk, user, pool.getUserPendingReward(user));
    }

    function _decryptTotalStaked() internal returns (uint64) {
        return decrypt(pool.totalStaked());
    }

    function _decryptPoolHandle(uint256 pk, address user, euint64 handle) internal returns (uint64) {
        if (euint64.unwrap(handle) == bytes32(0)) {
            return 0;
        }

        bytes memory signature = signUserDecrypt(pk, address(pool));
        return uint64(userDecrypt(euint64.unwrap(handle), user, address(pool), signature));
    }

    function _decryptTokenBalance(ERC7984Mock token, uint256 pk, address user) internal returns (uint64) {
        euint64 balance = token.confidentialBalanceOf(user);
        if (euint64.unwrap(balance) == bytes32(0)) {
            return 0;
        }

        bytes memory signature = signUserDecrypt(pk, address(token));
        return uint64(userDecrypt(euint64.unwrap(balance), user, address(token), signature));
    }
}
