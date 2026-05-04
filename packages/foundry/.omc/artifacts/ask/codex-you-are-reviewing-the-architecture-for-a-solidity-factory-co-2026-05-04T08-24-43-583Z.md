# codex advisor artifact

- Provider: codex
- Exit code: 0
- Created at: 2026-05-04T08:24:43.585Z

## Original task

You are reviewing the architecture for a Solidity factory contract that deploys PrivacyStakingPool instances on Zama fhEVM.

The existing PrivacyStakingPool contract (src/PrivacyStakingPool.sol) has this constructor:
constructor(IERC7984 stakeToken*, IERC7984 rewardToken*) — sets creator = msg.sender, stores both token addresses as immutables.

After deployment, the creator calls initialize(externalEuint64 totalRewardBudget*, bytes budgetProof*, uint256 startTime*, uint256 endTime*) to fund the pool with encrypted rewards.

Design a PrivacyStakingPoolFactory contract that:

1. Deploys new PrivacyStakingPool instances via a createPool function
2. Stores all deployments in an array and mapping (owner => pools[])
3. Tracks pool count, provides getPoolsByOwner and getAllPools views
4. Emits events for each deployment
5. Uses no access control on createPool (anyone can create)

Key constraints:

- The factory must pass msg.sender as the creator (the pool constructor uses msg.sender)
- Since the pool constructor sets creator = msg.sender, and the factory calls new PrivacyStakingPool(), the factory itself would become creator. This is a problem. Consider either: (a) having the factory deploy and then the user initializes directly, or (b) using CREATE2 with a salt so the user deploys via the factory but the pool sees the factory as creator — which means the factory needs to proxy the initialize call.
- Imports: IERC7984 from @openzeppelin/confidential-contracts/interfaces/IERC7984.sol
- Solidity ^0.8.27

Focus on: correct creator ownership pattern, storage design, security (reentrancy, access), gas efficiency, event design. Provide the full Solidity implementation.

## Final prompt

You are reviewing the architecture for a Solidity factory contract that deploys PrivacyStakingPool instances on Zama fhEVM.

The existing PrivacyStakingPool contract (src/PrivacyStakingPool.sol) has this constructor:
constructor(IERC7984 stakeToken*, IERC7984 rewardToken*) — sets creator = msg.sender, stores both token addresses as immutables.

After deployment, the creator calls initialize(externalEuint64 totalRewardBudget*, bytes budgetProof*, uint256 startTime*, uint256 endTime*) to fund the pool with encrypted rewards.

Design a PrivacyStakingPoolFactory contract that:

1. Deploys new PrivacyStakingPool instances via a createPool function
2. Stores all deployments in an array and mapping (owner => pools[])
3. Tracks pool count, provides getPoolsByOwner and getAllPools views
4. Emits events for each deployment
5. Uses no access control on createPool (anyone can create)

Key constraints:

- The factory must pass msg.sender as the creator (the pool constructor uses msg.sender)
- Since the pool constructor sets creator = msg.sender, and the factory calls new PrivacyStakingPool(), the factory itself would become creator. This is a problem. Consider either: (a) having the factory deploy and then the user initializes directly, or (b) using CREATE2 with a salt so the user deploys via the factory but the pool sees the factory as creator — which means the factory needs to proxy the initialize call.
- Imports: IERC7984 from @openzeppelin/confidential-contracts/interfaces/IERC7984.sol
- Solidity ^0.8.27

Focus on: correct creator ownership pattern, storage design, security (reentrancy, access), gas efficiency, event design. Provide the full Solidity implementation.

## Raw output

```text
The correct ownership pattern is to make `creator` an explicit constructor argument on the pool. With the original constructor, a factory deployment always sets `creator = factory`, which breaks direct user initialization. A factory-side `initialize` proxy is also the wrong fit here because `initialize` transfers rewards from `msg.sender`, so it would try to pull tokens from the factory, not the user.

I implemented that pattern in [src/PrivacyStakingPool.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPool.sol:121) and added the factory in [src/PrivacyStakingPoolFactory.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPoolFactory.sol:1). `createPool` is permissionless, deploys `new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_)`, stores the deployment in both `_allPools` and `_poolsByOwner[msg.sender]`, exposes `poolCount()`, `getPoolsByOwner()`, and `getAllPools()`, and emits `PoolCreated(owner, pool, stakeToken, rewardToken, poolCount)`. I also added zero-address token validation and kept the factory stateless apart from registry storage, so there’s no reentrancy-sensitive flow or privileged path.

Impact analysis via GitNexus could not resolve the Solidity symbols from the current index, so I could not report a graph-based blast radius. From direct inspection, the practical affected surface was the pool constructor call sites in tests/scripts. Those were updated in [test/PrivacyStakingPool.t.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPool.t.sol:44), [script/DeployPrivacyStakingPool.s.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/DeployPrivacyStakingPool.s.sol:12), and [script/FullFlowTest.s.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/FullFlowTest.s.sol:48). Factory coverage is in [test/PrivacyStakingPoolFactory.t.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPoolFactory.t.sol:1).

Verification: `forge test --match-contract PrivacyStakingPoolTest` and `forge test --match-contract PrivacyStakingPoolFactoryTest` both passed.


OpenAI Codex v0.128.0 (research preview)
--------
workdir: /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
model: gpt-5.4
provider: openai
approval: never
sandbox: danger-full-access
reasoning effort: medium
reasoning summaries: none
session id: 019df213-42bf-7920-bd36-846e4c63688a
--------
user
You are reviewing the architecture for a Solidity factory contract that deploys PrivacyStakingPool instances on Zama fhEVM.

The existing PrivacyStakingPool contract (src/PrivacyStakingPool.sol) has this constructor:
constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) — sets creator = msg.sender, stores both token addresses as immutables.

After deployment, the creator calls initialize(externalEuint64 totalRewardBudget_, bytes budgetProof_, uint256 startTime_, uint256 endTime_) to fund the pool with encrypted rewards.

Design a PrivacyStakingPoolFactory contract that:
1. Deploys new PrivacyStakingPool instances via a createPool function
2. Stores all deployments in an array and mapping (owner => pools[])
3. Tracks pool count, provides getPoolsByOwner and getAllPools views
4. Emits events for each deployment
5. Uses no access control on createPool (anyone can create)

Key constraints:
- The factory must pass msg.sender as the creator (the pool constructor uses msg.sender)
- Since the pool constructor sets creator = msg.sender, and the factory calls new PrivacyStakingPool(), the factory itself would become creator. This is a problem. Consider either: (a) having the factory deploy and then the user initializes directly, or (b) using CREATE2 with a salt so the user deploys via the factory but the pool sees the factory as creator — which means the factory needs to proxy the initialize call.
- Imports: IERC7984 from @openzeppelin/confidential-contracts/interfaces/IERC7984.sol
- Solidity ^0.8.27

Focus on: correct creator ownership pattern, storage design, security (reentrancy, access), gas efficiency, event design. Provide the full Solidity implementation.
codex
I’m inspecting the existing pool contract and related flows first so the factory design matches the current ownership and initialization model. I’ll verify how `creator` is used, then decide whether the factory should proxy initialization or whether the pool constructor needs an explicit creator parameter.
exec
/bin/zsh -lc "pwd && rg -n \"contract PrivacyStakingPool|constructor\\(|initialize\\(\" src test -g '"'!lib'"'" in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
test/PrivacyStakingPool.t.sol:10:contract PrivacyStakingPoolTest is FhevmTest {
test/PrivacyStakingPool.t.sol:205:        pool.initialize(budgetInput, budgetProof, startTime, endTime);
src/PrivacyStakingPool.sol:14:contract PrivacyStakingPool is ZamaEthereumConfig, ReentrancyGuard {
src/PrivacyStakingPool.sol:121:    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
src/PrivacyStakingPool.sol:137:    function initialize(

mcp: gitnexus/query started
mcp: gitnexus/query (completed)
codex
The index query didn’t surface a deployment flow, so I’m reading the contract directly and checking symbol context on `PrivacyStakingPool`. I need to confirm whether `creator` gates any runtime functions beyond `initialize`, because that determines whether a factory-only creator model is acceptable.
exec
/bin/zsh -lc "sed -n '1,260p' src/PrivacyStakingPool.sol" in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FHE, euint64, euint128, ebool, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/utils/ReentrancyGuard.sol";

/// @title PrivacyStakingPool
/// @notice Staking pool that hides absolute stake/reward amounts using Zama FHE while
///         exposing the per-interval reward ratio (and derived APR) publicly.
///         Reward distribution uses fixed 6-hour intervals with a 3-phase async decryption flow.
///         Per-user accounting follows the Compound/MasterChef cumulative-index pattern.
contract PrivacyStakingPool is ZamaEthereumConfig, ReentrancyGuard {
    // =========================================================================
    //  Tokens & Creator
    // =========================================================================

    IERC7984 public immutable stakeToken;
    IERC7984 public immutable rewardToken;
    address public immutable creator;

    // =========================================================================
    //  Constants
    // =========================================================================

    uint256 public constant INDEX_SCALE = 1e12;
    uint256 public constant INTERVAL = 6 hours;
    uint64 public constant R_MIN = uint64(1) << 32; // 2^32
    uint64 public constant R_MAX_BOUND = uint64(1) << 48; // 2^48, must be power-of-2 for randBounded

    // =========================================================================
    //  Encrypted State
    // =========================================================================

    euint64 private _totalStaked;
    euint64 private _rewardBudget;
    euint64 private _fixedIntervalReward;
    mapping(address => euint64) private _userStake;
    mapping(address => euint64) private _userPendingReward;

    // =========================================================================
    //  Public State
    // =========================================================================

    uint256 public cumulativeIndex;
    uint256 public lastIntervalIndexDelta;
    uint256 public lastDistributionTimestamp;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    mapping(address => uint256) private _userIndex;

    // =========================================================================
    //  Distribution Lifecycle
    // =========================================================================

    enum DistState {
        Idle,
        AwaitingDenominator,
        AwaitingIndexDelta
    }

    DistState public distState;

    euint128 private _pendingNumBlinded;
    euint64 private _pendingIntervalReward;
    bytes32 private _pendingDenHandle;
    bytes32 private _pendingIsEmptyHandle;
    bytes32 private _pendingIndexDeltaHandle;

    // =========================================================================
    //  Initialization
    // =========================================================================

    bool private _initialized;

    // =========================================================================
    //  Errors
    // =========================================================================

    error NotCreator();
    error AlreadyInitialized();
    error NotInitialized();
    error NotIdle();
    error WrongPhase();
    error IntervalNotElapsed();
    error NothingToClaim();
    error BadLength();
    error InvalidTimeRange();

    // =========================================================================
    //  Events
    // =========================================================================

    event Initialized(address indexed creator);
    event Staked(address indexed user);
    event Unstaked(address indexed user);
    event Claimed(address indexed user);
    event DistributePhase1(uint256 timestamp);
    event DistributePhase2(uint256 denBlindedClear, bool isEmpty);
    event DistributePhase3(uint256 indexDeltaClear, uint256 newCumulativeIndex);

    // =========================================================================
    //  Modifiers
    // =========================================================================

    modifier onlyIdle() {
        require(distState == DistState.Idle, NotIdle());
        _;
    }

    modifier onlyInitialized() {
        require(_initialized, NotInitialized());
        _;
    }

    // =========================================================================
    //  Constructor
    // =========================================================================

    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
        creator = msg.sender;
        stakeToken = stakeToken_;
        rewardToken = rewardToken_;
    }

    // =========================================================================
    //  Initialization (separate from constructor to allow encrypted inputs)
    // =========================================================================

    /// @notice Fund the pool with encrypted reward budget and derive the fixed per-interval reward.
    ///         Creator must have set this pool as an operator on the reward token beforehand.
    /// @param totalRewardBudget_ Encrypted total reward token amount to fund the pool
    /// @param budgetProof_       Input proof for the budget ciphertext
    /// @param startTime_         Plaintext timestamp when the pool starts distributing
    /// @param endTime_           Plaintext timestamp when the pool stops distributing
    function initialize(
        externalEuint64 totalRewardBudget_,
        bytes calldata budgetProof_,
        uint256 startTime_,
        uint256 endTime_
    ) external {
        require(msg.sender == creator, NotCreator());
        require(!_initialized, AlreadyInitialized());
        require(startTime_ >= block.timestamp, InvalidTimeRange());
        require(endTime_ > startTime_, InvalidTimeRange());
        require((endTime_ - startTime_) % INTERVAL == 0, InvalidTimeRange());
        _initialized = true;

        uint256 numIntervals = (endTime_ - startTime_) / INTERVAL;
        euint64 budget = FHE.fromExternal(totalRewardBudget_, budgetProof_);
        FHE.allowThis(budget);
        FHE.allow(budget, address(rewardToken));
        _fixedIntervalReward = FHE.allowThis(FHE.div(budget, uint64(numIntervals)));

        euint64 transferred = rewardToken.confidentialTransferFrom(msg.sender, address(this), budget);
        _rewardBudget = FHE.allowThis(transferred);
        poolStartTime = startTime_;
        poolEndTime = endTime_;

        lastDistributionTimestamp = startTime_;
        emit Initialized(msg.sender);
    }

    // =========================================================================
    //  User Actions (all blocked while distribution is in progress)
    // =========================================================================

    /// @notice Stake encrypted amount of stake tokens into the pool.
    ///         Caller must have set this pool as an operator on the stake token.
    function stake(externalEuint64 amount, bytes calldata proof) external onlyIdle onlyInitialized nonReentrant {
        _settle(msg.sender);

        euint64 amt = FHE.fromExternal(amount, proof);
        FHE.allow(amt, address(stakeToken));

        _userStake[msg.sender] = FHE.allowThis(FHE.allow(FHE.add(_userStake[msg.sender], amt), msg.sender));
        _totalStaked = FHE.allowThis(FHE.add(_totalStaked, amt));

        stakeToken.confidentialTransferFrom(msg.sender, address(this), amt);
        emit Staked(msg.sender);
    }

    /// @notice Unstake up to `amount` of stake tokens. Clamped homomorphically to avoid
    ///         leaking over-unstake attempts via revert.
    function unstake(externalEuint64 amount, bytes calldata proof) external onlyIdle onlyInitialized nonReentrant {
        _settle(msg.sender);

        euint64 amt = FHE.fromExternal(amount, proof);
        euint64 actual = FHE.allowThis(FHE.min(amt, _userStake[msg.sender]));
        FHE.allow(actual, address(stakeToken));

        _userStake[msg.sender] = FHE.allowThis(FHE.allow(FHE.sub(_userStake[msg.sender], actual), msg.sender));
        _totalStaked = FHE.allowThis(FHE.sub(_totalStaked, actual));

        stakeToken.confidentialTransfer(msg.sender, actual);
        emit Unstaked(msg.sender);
    }

    /// @notice Claim all accrued reward tokens.
    function claim() external onlyIdle onlyInitialized nonReentrant {
        _settle(msg.sender);

        euint64 pending = _userPendingReward[msg.sender];
        require(FHE.isInitialized(pending), NothingToClaim());
        FHE.allow(pending, address(rewardToken));

        rewardToken.confidentialTransfer(msg.sender, pending);
        _userPendingReward[msg.sender] = FHE.allowThis(FHE.allow(FHE.asEuint64(0), msg.sender));

        emit Claimed(msg.sender);
    }

    // =========================================================================
    //  Distribution — Phase 1 (permissionless trigger)
    // =========================================================================

    /// @notice Begin a new distribution interval. Computes blinded numerator/denominator
    ///         and requests async decryption of the blinded denominator and isEmpty flag.
    function distribute() external onlyIdle onlyInitialized {
        require(block.timestamp >= poolStartTime, InvalidTimeRange());
        require(block.timestamp >= lastDistributionTimestamp + INTERVAL, IntervalNotElapsed());

        // Clamp reward to remaining budget
        euint64 safeReward = FHE.allowThis(FHE.min(_fixedIntervalReward, _rewardBudget));

        // Blinding factor r ∈ [R_MIN, R_MIN + R_MAX_BOUND)
        euint64 r = FHE.add(FHE.randEuint64(R_MAX_BOUND), FHE.asEuint64(R_MIN));

        // Widen to euint128 for safe multiplication
        euint128 safeReward128 = FHE.asEuint128(safeReward);
        euint128 r128 = FHE.asEuint128(r);
        euint128 totalStaked128 = FHE.asEuint128(_totalStaked);

        // numBlinded = safeReward * r * INDEX_SCALE
        euint128 numBlinded = FHE.allowThis(FHE.mul(FHE.mul(safeReward128, r128), uint128(INDEX_SCALE)));

        // denBlinded = totalStaked * r
        euint128 denBlinded = FHE.mul(totalStaked128, r128);

        // isEmpty = (totalStaked == 0)
        ebool isEmpty = FHE.eq(_totalStaked, FHE.asEuint64(0));

        // Store transient state
        _pendingNumBlinded = numBlinded;
        _pendingIntervalReward = safeReward;

        // Request public decryption of denBlinded and isEmpty
        _pendingDenHandle = euint128.unwrap(FHE.makePubliclyDecryptable(denBlinded));
        _pendingIsEmptyHandle = ebool.unwrap(FHE.makePubliclyDecryptable(isEmpty));

        distState = DistState.AwaitingDenominator;
        emit DistributePhase1(block.timestamp);
        // r falls out of scope — never stored, never reused
    }

    // =========================================================================
    //  Distribution — Phase 2 (keeper callback with decrypted denominator)
    // =========================================================================


mcp: gitnexus/context started
mcp: gitnexus/context (completed)
codex
`initialize` is currently hard-gated by `msg.sender == creator`, and `creator` is set only in the constructor. I’m checking whether `creator` is used anywhere else and whether tests assume EOA ownership, because that decides whether a factory-only fix is viable without touching the pool contract.
exec
/bin/zsh -lc "rg -n \"creator|NotCreator|Initialized\\(|initialize\\(\" src test" in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
src/PrivacyStakingPool.sol:21:    address public immutable creator;
src/PrivacyStakingPool.sol:81:    error NotCreator();
src/PrivacyStakingPool.sol:82:    error AlreadyInitialized();
src/PrivacyStakingPool.sol:83:    error NotInitialized();
src/PrivacyStakingPool.sol:95:    event Initialized(address indexed creator);
src/PrivacyStakingPool.sol:112:    modifier onlyInitialized() {
src/PrivacyStakingPool.sol:113:        require(_initialized, NotInitialized());
src/PrivacyStakingPool.sol:122:        creator = msg.sender;
src/PrivacyStakingPool.sol:137:    function initialize(
src/PrivacyStakingPool.sol:143:        require(msg.sender == creator, NotCreator());
src/PrivacyStakingPool.sol:144:        require(!_initialized, AlreadyInitialized());
src/PrivacyStakingPool.sol:162:        emit Initialized(msg.sender);
src/PrivacyStakingPool.sol:205:        require(FHE.isInitialized(pending), NothingToClaim());
src/PrivacyStakingPool.sol:336:        if (delta > 0 && FHE.isInitialized(_userStake[user])) {
test/PrivacyStakingPool.t.sol:27:    address internal creator;
test/PrivacyStakingPool.t.sol:35:        creator = vm.addr(CREATOR_PK);
test/PrivacyStakingPool.t.sol:41:        vm.prank(creator);
test/PrivacyStakingPool.t.sol:44:        vm.prank(creator);
test/PrivacyStakingPool.t.sol:47:        vm.prank(creator);
test/PrivacyStakingPool.t.sol:52:        _mint(rewardToken, creator, 5_000);
test/PrivacyStakingPool.t.sol:56:        uint64 creatorRewardBalanceBefore = _decryptTokenBalance(rewardToken, CREATOR_PK, creator);
test/PrivacyStakingPool.t.sol:63:        assertEq(pool.creator(), creator);
test/PrivacyStakingPool.t.sol:69:            _decryptTokenBalance(rewardToken, CREATOR_PK, creator), creatorRewardBalanceBefore - INITIAL_REWARD_BUDGET
test/PrivacyStakingPool.t.sol:199:        vm.prank(creator);
test/PrivacyStakingPool.t.sol:202:        (externalEuint64 budgetInput, bytes memory budgetProof) = encryptUint64(budget, creator, address(pool));
test/PrivacyStakingPool.t.sol:204:        vm.prank(creator);
test/PrivacyStakingPool.t.sol:205:        pool.initialize(budgetInput, budgetProof, startTime, endTime);
test/PrivacyStakingPool.t.sol:246:        (externalEuint64 amountInput, bytes memory proof) = encryptUint64(amount, creator, address(token));
test/PrivacyStakingPool.t.sol:247:        vm.prank(creator);

mcp: gitnexus/context started
mcp: gitnexus/context (completed)
codex
The current tests explicitly assert `pool.creator() == creator`, so a factory that becomes `creator` would break the existing ownership model and leave the user unable to call `initialize`. I’m reading the setup test around deployment to anchor the factory API and any required contract change.
exec
/bin/zsh -lc "sed -n '1,120p' test/PrivacyStakingPool.t.sol && printf '\\n---\\n' && sed -n '188,214p' test/PrivacyStakingPool.t.sol" in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
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

---

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

codex
The cleanest ownership model requires a small pool-contract change: the factory cannot preserve user ownership if the constructor always sets `creator = msg.sender`. I’m running impact analysis on the pool contract and `initialize` path before editing, then I’ll implement the explicit-creator constructor plus the factory.
mcp: gitnexus/impact started
mcp: gitnexus/impact (completed)
mcp: gitnexus/impact started
mcp: gitnexus/impact (completed)
exec
/bin/zsh -lc 'ls src test' in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
src:
FHECounter.sol
PrivacyStakingPool.sol

test:
FHECounter.t.sol
PrivacyStakingPool.t.sol

codex
Impact analysis could not resolve Solidity symbols from the current index, so there’s no reliable blast-radius graph to report from GitNexus. Based on direct inspection, the live touch points are narrow: the constructor is only instantiated in [test/PrivacyStakingPool.t.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPool.t.sol), and `initialize` is only exercised there, so the practical change surface is the pool contract, its tests, and the new factory.

I’m editing three areas now:
1. Update `PrivacyStakingPool` so the constructor accepts an explicit `creator_`.
2. Add `PrivacyStakingPoolFactory` with array/mapping tracking and deployment events.
3. Extend tests to cover both the new constructor path and factory deployment ownership.
apply patch
patch: completed
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPool.sol
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPoolFactory.sol
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPool.t.sol
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

codex
The ownership fix and factory are in place. I’m running the relevant Forge tests now to catch any constructor ABI fallout and to verify the factory preserves the EOA creator as intended.
exec
/bin/zsh -lc 'forge test --match-contract PrivacyStakingPoolFactoryTest' in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
exec
/bin/zsh -lc 'forge test --match-contract PrivacyStakingPoolTest' in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

 exited 1 in 1351ms:
Compiler run failed:
Error (6160): Wrong argument count for function call: 2 arguments given but expected 3.
  --> script/DeployPrivacyStakingPool.s.sol:12:35:
   |
12 |         PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
   |                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Error (6160): Wrong argument count for function call: 2 arguments given but expected 3.
  --> script/FullFlowTest.s.sol:48:16:
   |
48 |         pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
   |                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Error: Compilation failed

 exited 1 in 1351ms:
Compiler run failed:
Error (6160): Wrong argument count for function call: 2 arguments given but expected 3.
  --> script/DeployPrivacyStakingPool.s.sol:12:35:
   |
12 |         PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
   |                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Error (6160): Wrong argument count for function call: 2 arguments given but expected 3.
  --> script/FullFlowTest.s.sol:48:16:
   |
48 |         pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
   |                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Error: Compilation failed

codex
The test jobs are still running. I’m waiting on both the existing pool suite and the new factory suite before I close this out.
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

codex
Compilation exposed two constructor call sites in the scripts directory. I’m updating those to the explicit-creator constructor, then I’ll rerun the targeted tests.
exec
/bin/zsh -lc "sed -n '1,120p' script/DeployPrivacyStakingPool.s.sol && printf '\\n---\\n' && sed -n '1,120p' script/FullFlowTest.s.sol" in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
 succeeded in 0ms:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";

contract DeployPrivacyStakingPool is Script {
    function run(address stakeToken, address rewardToken) external {
        vm.startBroadcast();

        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
        console.log("PrivacyStakingPool deployed at:", address(pool));
        console.log("Creator:", pool.creator());

        vm.stopBroadcast();
    }
}

---
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

diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

apply patch
patch: completed
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/DeployPrivacyStakingPool.s.sol
/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/FullFlowTest.s.sol
diff --git a/packages/foundry/script/DeployPrivacyStakingPool.s.sol b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
index 823fe231a6d0b71efed34b1848a1a7d65391856e..686a5aa0ac7f9d36d456af797eda4a2629312726
--- a/packages/foundry/script/DeployPrivacyStakingPool.s.sol
+++ b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
@@ -9,7 +9,7 @@
     function run(address stakeToken, address rewardToken) external {
         vm.startBroadcast();

-        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
+        PrivacyStakingPool pool = new PrivacyStakingPool(msg.sender, IERC7984(stakeToken), IERC7984(rewardToken));
         console.log("PrivacyStakingPool deployed at:", address(pool));
         console.log("Creator:", pool.creator());

diff --git a/packages/foundry/script/FullFlowTest.s.sol b/packages/foundry/script/FullFlowTest.s.sol
index 0bd303b6f84325b1b4a0f1a8a9ffd41cab093d80..9515b7bbe266fdccce8ec3861f9fffb34bb30106
--- a/packages/foundry/script/FullFlowTest.s.sol
+++ b/packages/foundry/script/FullFlowTest.s.sol
@@ -45,7 +45,7 @@
         vm.prank(creator);
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 5_000);
         _mint(stakeToken, bob, 5_000);
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

diff --git a/packages/foundry/script/DeployPrivacyStakingPool.s.sol b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
index 823fe231a6d0b71efed34b1848a1a7d65391856e..686a5aa0ac7f9d36d456af797eda4a2629312726
--- a/packages/foundry/script/DeployPrivacyStakingPool.s.sol
+++ b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
@@ -9,7 +9,7 @@
     function run(address stakeToken, address rewardToken) external {
         vm.startBroadcast();

-        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
+        PrivacyStakingPool pool = new PrivacyStakingPool(msg.sender, IERC7984(stakeToken), IERC7984(rewardToken));
         console.log("PrivacyStakingPool deployed at:", address(pool));
         console.log("Creator:", pool.creator());

diff --git a/packages/foundry/script/FullFlowTest.s.sol b/packages/foundry/script/FullFlowTest.s.sol
index 0bd303b6f84325b1b4a0f1a8a9ffd41cab093d80..9515b7bbe266fdccce8ec3861f9fffb34bb30106
--- a/packages/foundry/script/FullFlowTest.s.sol
+++ b/packages/foundry/script/FullFlowTest.s.sol
@@ -45,7 +45,7 @@
         vm.prank(creator);
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 5_000);
         _mint(stakeToken, bob, 5_000);
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

codex
The remaining constructor call sites are fixed. I’m rerunning the targeted Forge suites now.
exec
/bin/zsh -lc 'forge test --match-contract PrivacyStakingPoolTest' in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
exec
/bin/zsh -lc 'forge test --match-contract PrivacyStakingPoolFactoryTest' in /Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry
diff --git a/packages/foundry/script/DeployPrivacyStakingPool.s.sol b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
index 823fe231a6d0b71efed34b1848a1a7d65391856e..686a5aa0ac7f9d36d456af797eda4a2629312726
--- a/packages/foundry/script/DeployPrivacyStakingPool.s.sol
+++ b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
@@ -9,7 +9,7 @@
     function run(address stakeToken, address rewardToken) external {
         vm.startBroadcast();

-        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
+        PrivacyStakingPool pool = new PrivacyStakingPool(msg.sender, IERC7984(stakeToken), IERC7984(rewardToken));
         console.log("PrivacyStakingPool deployed at:", address(pool));
         console.log("Creator:", pool.creator());

diff --git a/packages/foundry/script/FullFlowTest.s.sol b/packages/foundry/script/FullFlowTest.s.sol
index 0bd303b6f84325b1b4a0f1a8a9ffd41cab093d80..9515b7bbe266fdccce8ec3861f9fffb34bb30106
--- a/packages/foundry/script/FullFlowTest.s.sol
+++ b/packages/foundry/script/FullFlowTest.s.sol
@@ -45,7 +45,7 @@
         vm.prank(creator);
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 5_000);
         _mint(stakeToken, bob, 5_000);
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

 succeeded in 4324ms:
Compiling 4 files with Solc 0.8.27
Solc 0.8.27 finished in 2.88s
Compiler run successful!

Ran 2 tests for test/PrivacyStakingPoolFactory.t.sol:PrivacyStakingPoolFactoryTest
[PASS] test_createPoolRevertsForZeroAddressToken() (gas: 18224)
[PASS] test_createPoolTracksDeploymentAndPreservesCreator() (gas: 2004025)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 7.84ms (1.52ms CPU time)

Ran 1 test suite in 141.72ms (7.84ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)

diff --git a/packages/foundry/script/DeployPrivacyStakingPool.s.sol b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
index 823fe231a6d0b71efed34b1848a1a7d65391856e..686a5aa0ac7f9d36d456af797eda4a2629312726
--- a/packages/foundry/script/DeployPrivacyStakingPool.s.sol
+++ b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
@@ -9,7 +9,7 @@
     function run(address stakeToken, address rewardToken) external {
         vm.startBroadcast();

-        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
+        PrivacyStakingPool pool = new PrivacyStakingPool(msg.sender, IERC7984(stakeToken), IERC7984(rewardToken));
         console.log("PrivacyStakingPool deployed at:", address(pool));
         console.log("Creator:", pool.creator());

diff --git a/packages/foundry/script/FullFlowTest.s.sol b/packages/foundry/script/FullFlowTest.s.sol
index 0bd303b6f84325b1b4a0f1a8a9ffd41cab093d80..9515b7bbe266fdccce8ec3861f9fffb34bb30106
--- a/packages/foundry/script/FullFlowTest.s.sol
+++ b/packages/foundry/script/FullFlowTest.s.sol
@@ -45,7 +45,7 @@
         vm.prank(creator);
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 5_000);
         _mint(stakeToken, bob, 5_000);
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

 succeeded in 4658ms:
Compiling 4 files with Solc 0.8.27
Solc 0.8.27 finished in 3.20s
Compiler run successful!

Ran 8 tests for test/PrivacyStakingPool.t.sol:PrivacyStakingPoolTest
[PASS] test_claimRevertsWhenNothingAccrued() (gas: 1395248)
[PASS] test_distributionCycleClaimAndUnstake() (gas: 4758839)
[PASS] test_distributionSplitsRewardsProRataAcrossStakers() (gas: 5646658)
[PASS] test_emptyPoolDistributionSkipsRewardAndResetsState() (gas: 1973259)
[PASS] test_initializeFundsPoolAndSetsRewardConfig() (gas: 1315946)
[PASS] test_intervalTimingEnforced() (gas: 1774671)
[PASS] test_notIdleRevertsDuringDistribution() (gas: 1803792)
[PASS] test_stakeMovesTokensAndTracksEncryptedStake() (gas: 2172656)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 13.37ms (24.87ms CPU time)

Ran 1 test suite in 128.19ms (13.37ms CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)

codex
The correct ownership pattern is to make `creator` an explicit constructor argument on the pool. With the original constructor, a factory deployment always sets `creator = factory`, which breaks direct user initialization. A factory-side `initialize` proxy is also the wrong fit here because `initialize` transfers rewards from `msg.sender`, so it would try to pull tokens from the factory, not the user.

I implemented that pattern in [src/PrivacyStakingPool.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPool.sol:121) and added the factory in [src/PrivacyStakingPoolFactory.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/src/PrivacyStakingPoolFactory.sol:1). `createPool` is permissionless, deploys `new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_)`, stores the deployment in both `_allPools` and `_poolsByOwner[msg.sender]`, exposes `poolCount()`, `getPoolsByOwner()`, and `getAllPools()`, and emits `PoolCreated(owner, pool, stakeToken, rewardToken, poolCount)`. I also added zero-address token validation and kept the factory stateless apart from registry storage, so there’s no reentrancy-sensitive flow or privileged path.

Impact analysis via GitNexus could not resolve the Solidity symbols from the current index, so I could not report a graph-based blast radius. From direct inspection, the practical affected surface was the pool constructor call sites in tests/scripts. Those were updated in [test/PrivacyStakingPool.t.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPool.t.sol:44), [script/DeployPrivacyStakingPool.s.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/DeployPrivacyStakingPool.s.sol:12), and [script/FullFlowTest.s.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/script/FullFlowTest.s.sol:48). Factory coverage is in [test/PrivacyStakingPoolFactory.t.sol](/Users/mymac/Workspace/Zama/privacy-staking-pool/packages/foundry/test/PrivacyStakingPoolFactory.t.sol:1).

Verification: `forge test --match-contract PrivacyStakingPoolTest` and `forge test --match-contract PrivacyStakingPoolFactoryTest` both passed.
diff --git a/packages/foundry/script/DeployPrivacyStakingPool.s.sol b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
index 823fe231a6d0b71efed34b1848a1a7d65391856e..686a5aa0ac7f9d36d456af797eda4a2629312726
--- a/packages/foundry/script/DeployPrivacyStakingPool.s.sol
+++ b/packages/foundry/script/DeployPrivacyStakingPool.s.sol
@@ -9,7 +9,7 @@
     function run(address stakeToken, address rewardToken) external {
         vm.startBroadcast();

-        PrivacyStakingPool pool = new PrivacyStakingPool(IERC7984(stakeToken), IERC7984(rewardToken));
+        PrivacyStakingPool pool = new PrivacyStakingPool(msg.sender, IERC7984(stakeToken), IERC7984(rewardToken));
         console.log("PrivacyStakingPool deployed at:", address(pool));
         console.log("Creator:", pool.creator());

diff --git a/packages/foundry/script/FullFlowTest.s.sol b/packages/foundry/script/FullFlowTest.s.sol
index 0bd303b6f84325b1b4a0f1a8a9ffd41cab093d80..9515b7bbe266fdccce8ec3861f9fffb34bb30106
--- a/packages/foundry/script/FullFlowTest.s.sol
+++ b/packages/foundry/script/FullFlowTest.s.sol
@@ -45,7 +45,7 @@
         vm.prank(creator);
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 5_000);
         _mint(stakeToken, bob, 5_000);
diff --git a/packages/foundry/src/PrivacyStakingPool.sol b/packages/foundry/src/PrivacyStakingPool.sol
index 2f1ca84f5b22ef9bf9e3337d421e61e5066fb498..2f946f8ba672c63003b733496eb18c0aabea0c20
--- a/packages/foundry/src/PrivacyStakingPool.sol
+++ b/packages/foundry/src/PrivacyStakingPool.sol
@@ -118,8 +118,8 @@
     //  Constructor
     // =========================================================================

-    constructor(IERC7984 stakeToken_, IERC7984 rewardToken_) {
-        creator = msg.sender;
+    constructor(address creator_, IERC7984 stakeToken_, IERC7984 rewardToken_) {
+        creator = creator_;
         stakeToken = stakeToken_;
         rewardToken = rewardToken_;
     }
diff --git a/packages/foundry/src/PrivacyStakingPoolFactory.sol b/packages/foundry/src/PrivacyStakingPoolFactory.sol
new file mode 100644
index 0000000000000000000000000000000000000000..3224b5b8a02af139917327d997cf396ed8403996
--- /dev/null
+++ b/packages/foundry/src/PrivacyStakingPoolFactory.sol
@@ -0,0 +1,49 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+import {PrivacyStakingPool} from "./PrivacyStakingPool.sol";
+
+/// @title PrivacyStakingPoolFactory
+/// @notice Permissionless factory for deploying PrivacyStakingPool instances.
+///         The pool constructor receives the caller as `creator`, so the caller
+///         retains the right to initialize and fund the deployed pool directly.
+contract PrivacyStakingPoolFactory {
+    error ZeroAddressToken();
+
+    address[] private _allPools;
+    mapping(address owner => address[]) private _poolsByOwner;
+
+    event PoolCreated(
+        address indexed owner,
+        address indexed pool,
+        address indexed stakeToken,
+        address rewardToken,
+        uint256 poolCount
+    );
+
+    function createPool(IERC7984 stakeToken_, IERC7984 rewardToken_) external returns (address pool) {
+        if (address(stakeToken_) == address(0) || address(rewardToken_) == address(0)) {
+            revert ZeroAddressToken();
+        }
+
+        pool = address(new PrivacyStakingPool(msg.sender, stakeToken_, rewardToken_));
+
+        _allPools.push(pool);
+        _poolsByOwner[msg.sender].push(pool);
+
+        emit PoolCreated(msg.sender, pool, address(stakeToken_), address(rewardToken_), _allPools.length);
+    }
+
+    function poolCount() external view returns (uint256) {
+        return _allPools.length;
+    }
+
+    function getPoolsByOwner(address owner) external view returns (address[] memory) {
+        return _poolsByOwner[owner];
+    }
+
+    function getAllPools() external view returns (address[] memory) {
+        return _allPools;
+    }
+}
diff --git a/packages/foundry/test/PrivacyStakingPool.t.sol b/packages/foundry/test/PrivacyStakingPool.t.sol
index 32e689f861bbaac94546826c72a952de5b958fa3..a3fa6523c11106efbeea06298fa91982031aa2ef
--- a/packages/foundry/test/PrivacyStakingPool.t.sol
+++ b/packages/foundry/test/PrivacyStakingPool.t.sol
@@ -45,7 +45,7 @@
         rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");

         vm.prank(creator);
-        pool = new PrivacyStakingPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+        pool = new PrivacyStakingPool(creator, IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));

         _mint(stakeToken, alice, 1_000);
         _mint(stakeToken, bob, 1_000);
diff --git a/packages/foundry/test/PrivacyStakingPoolFactory.t.sol b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
new file mode 100644
index 0000000000000000000000000000000000000000..0b5749ded3896c3f2dbf59b61ca0e6b37f8e6ae8
--- /dev/null
+++ b/packages/foundry/test/PrivacyStakingPoolFactory.t.sol
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: MIT
+pragma solidity ^0.8.27;
+
+import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
+import {PrivacyStakingPool} from "../src/PrivacyStakingPool.sol";
+import {PrivacyStakingPoolFactory} from "../src/PrivacyStakingPoolFactory.sol";
+import {ERC7984Mock} from "@openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol";
+import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
+
+contract PrivacyStakingPoolFactoryTest is FhevmTest {
+    uint256 internal constant CREATOR_PK = 0xC0FFEE;
+
+    PrivacyStakingPoolFactory internal factory;
+    ERC7984Mock internal stakeToken;
+    ERC7984Mock internal rewardToken;
+    address internal creator;
+
+    function setUp() public override {
+        super.setUp();
+
+        creator = vm.addr(CREATOR_PK);
+
+        vm.prank(creator);
+        stakeToken = new ERC7984Mock("Stake Token", "STK", "ipfs://stake");
+
+        vm.prank(creator);
+        rewardToken = new ERC7984Mock("Reward Token", "RWD", "ipfs://reward");
+
+        factory = new PrivacyStakingPoolFactory();
+    }
+
+    function test_createPoolTracksDeploymentAndPreservesCreator() public {
+        vm.prank(creator);
+        address poolAddress = factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(rewardToken)));
+
+        PrivacyStakingPool pool = PrivacyStakingPool(poolAddress);
+        address[] memory ownerPools = factory.getPoolsByOwner(creator);
+        address[] memory allPools = factory.getAllPools();
+
+        assertEq(pool.creator(), creator);
+        assertEq(address(pool.stakeToken()), address(stakeToken));
+        assertEq(address(pool.rewardToken()), address(rewardToken));
+        assertEq(factory.poolCount(), 1);
+        assertEq(ownerPools.length, 1);
+        assertEq(ownerPools[0], poolAddress);
+        assertEq(allPools.length, 1);
+        assertEq(allPools[0], poolAddress);
+    }
+
+    function test_createPoolRevertsForZeroAddressToken() public {
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(0)), IERC7984(address(rewardToken)));
+
+        vm.prank(creator);
+        vm.expectRevert(PrivacyStakingPoolFactory.ZeroAddressToken.selector);
+        factory.createPool(IERC7984(address(stakeToken)), IERC7984(address(0)));
+    }
+}

tokens used
64,240

```

## Concise summary

Provider completed successfully. Review the raw output for details.

## Action items

- Review the response and extract decisions you want to apply.
- Capture follow-up implementation tasks if needed.
