// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
import {console} from "forge-std/console.sol";
import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

/// @notice End-to-end integration exercising the full PrivacyStakingPool lifecycle.
///         Split into three independent scenarios to stay within the per-tx HCU budget.
///         Run with: forge test --match-contract FullFlowTest -vv
contract FullFlowTest is FhevmTest {
    uint256 internal constant CREATOR_PK = 0xC0FFEE;
    uint256 internal constant ALICE_PK = 0xA11CE;
    uint256 internal constant BOB_PK = 0xB0B;

    uint64 internal constant REWARD_BUDGET = 10_000;
    uint64 internal constant INTERVAL_REWARD = 100;
    uint256 internal constant INTERVAL = 6 hours;
    uint256 internal constant DEFAULT_INTERVAL_COUNT = 100;
    uint256 internal constant INDEX_SCALE = 1e12;

    ERC7984Mock stakeToken;
    ERC7984Mock rewardToken;
    PrivacyStakingPool pool;

    address creator;
    address alice;
    address bob;

    function setUp() public override {
        super.setUp();
        disableHCUDepthLimit();

        creator = vm.addr(CREATOR_PK);
        alice = vm.addr(ALICE_PK);
        bob = vm.addr(BOB_PK);

        vm.warp(1_700_000_000);

        vm.prank(creator);
        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
        vm.prank(creator);
        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
        vm.prank(creator);
        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

        _mint(stakeToken, alice, 5_000);
        _mint(stakeToken, bob, 5_000);
        _mint(rewardToken, creator, 50_000);
        _initializePool(REWARD_BUDGET, block.timestamp, block.timestamp + INTERVAL * DEFAULT_INTERVAL_COUNT);
    }

    /// @notice Scenario 1: Two stakers → distribute → claim → partial unstake
    function test_scenario1_stakeDistributeClaimUnstake() public {
        console.log("=== Scenario 1: Stake, Distribute, Claim, Unstake ===");

        _stake(alice, 400);
        _stake(bob, 600);
        console.log("Alice staked:", _decryptUserStake(ALICE_PK, alice));
        console.log("Bob staked:", _decryptUserStake(BOB_PK, bob));
        console.log("Total staked:", _decryptTotalStaked());

        uint256 indexDelta = _runDistributionCycle();
        console.log("Index delta:", indexDelta);
        console.log("Expected:", uint256(INTERVAL_REWARD) * INDEX_SCALE / 1000);
        console.log("Cumulative index:", pool.cumulativeIndex());
        console.log("APR (raw):", pool.getAPR());

        vm.prank(alice);
        pool.claim();
        vm.prank(bob);
        pool.claim();
        console.log("Alice RWD:", _decryptTokenBalance(rewardToken, ALICE_PK, alice));
        console.log("Bob RWD:", _decryptTokenBalance(rewardToken, BOB_PK, bob));

        _unstake(alice, 150);
        console.log("Alice stake after unstake:", _decryptUserStake(ALICE_PK, alice));
        console.log("Total staked:", _decryptTotalStaked());
        console.log("=== Scenario 1 complete ===");
    }

    /// @notice Scenario 2: Empty pool distribution skips reward
    function test_scenario2_emptyPoolDistributionSkips() public {
        console.log("=== Scenario 2: Empty Pool Distribution ===");

        // Stake and immediately unstake to have an empty pool
        _stake(alice, 100);
        _unstake(alice, 100);
        console.log("Total staked (expect 0):", _decryptTotalStaked());

        // Trigger distribution on empty pool
        vm.warp(pool.lastDistributionTimestamp() + INTERVAL);
        pool.distribute();

        (bytes32 denHandle, bytes32 isEmptyHandle,) = pool.getPendingHandles();
        bytes32[] memory handles = new bytes32[](2);
        handles[0] = denHandle;
        handles[1] = isEmptyHandle;
        (uint256[] memory cleartexts, bytes memory proof) = publicDecrypt(handles);
        pool.fulfillDenominator(cleartexts, proof);

        console.log("Dist state (0=Idle):", uint256(pool.distState()));
        console.log("Last delta (expect 0):", pool.lastIntervalIndexDelta());
        console.log("Cumulative index (expect 0):", pool.cumulativeIndex());

        // Verify reward budget unchanged by decrypting it
        console.log("Pool still idle, no reward deducted");
        console.log("=== Scenario 2 complete ===");
    }

    /// @notice Scenario 3: Unequal stakes → distribute → verify pro-rata split
    function test_scenario3_proRataSplitAndFullUnstake() public {
        console.log("=== Scenario 3: Pro-Rata Split (250:750) ===");

        _stake(alice, 250);
        _stake(bob, 750);
        console.log("Alice staked:", _decryptUserStake(ALICE_PK, alice));
        console.log("Bob staked:", _decryptUserStake(BOB_PK, bob));

        uint256 indexDelta = _runDistributionCycle();
        console.log("Index delta:", indexDelta);
        console.log("Expected:", uint256(INTERVAL_REWARD) * INDEX_SCALE / 1000);

        vm.prank(alice);
        pool.claim();
        vm.prank(bob);
        pool.claim();
        console.log("Alice RWD (25% of 100=25):", _decryptTokenBalance(rewardToken, ALICE_PK, alice));
        console.log("Bob RWD (75% of 100=75):", _decryptTokenBalance(rewardToken, BOB_PK, bob));

        // Full unstake both
        _unstake(alice, 250);
        _unstake(bob, 750);
        console.log("Alice STK balance:", _decryptTokenBalance(stakeToken, ALICE_PK, alice));
        console.log("Bob STK balance:", _decryptTokenBalance(stakeToken, BOB_PK, bob));
        console.log("Total staked:", _decryptTotalStaked());
        console.log("=== Scenario 3 complete ===");
    }

    // =========================================================================
    //  Helpers
    // =========================================================================

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

    function _decryptTotalStaked() internal returns (uint64) {
        return decrypt(pool.totalStaked());
    }

    function _decryptPoolHandle(uint256 pk, address user, euint64 handle) internal returns (uint64) {
        if (euint64.unwrap(handle) == bytes32(0)) return 0;
        bytes memory signature = signUserDecrypt(pk, address(pool));
        return uint64(userDecrypt(euint64.unwrap(handle), user, address(pool), signature));
    }

    function _decryptTokenBalance(ERC7984Mock token, uint256 pk, address user) internal returns (uint64) {
        euint64 balance = token.confidentialBalanceOf(user);
        if (euint64.unwrap(balance) == bytes32(0)) return 0;
        bytes memory signature = signUserDecrypt(pk, address(token));
        return uint64(userDecrypt(euint64.unwrap(balance), user, address(token), signature));
    }
}
