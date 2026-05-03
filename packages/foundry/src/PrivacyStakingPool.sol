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

    /// @notice Supply the decrypted blinded denominator and isEmpty flag with KMS proof.
    ///         If the pool is empty, the interval is skipped (no reward deducted).
    /// @param cleartexts [denBlindedClear, isEmptyClear] from publicDecrypt
    /// @param decryptionProof KMS decryption signature
    function fulfillDenominator(uint256[] calldata cleartexts, bytes calldata decryptionProof) external {
        require(distState == DistState.AwaitingDenominator, WrongPhase());
        require(cleartexts.length == 2, BadLength());

        // Verify KMS decryption proof
        bytes32[] memory handles = new bytes32[](2);
        handles[0] = _pendingDenHandle;
        handles[1] = _pendingIsEmptyHandle;
        FHE.checkSignatures(handles, abi.encode(cleartexts), decryptionProof);

        uint256 denBlindedClear = cleartexts[0];
        bool isEmpty = cleartexts[1] != 0;

        emit DistributePhase2(denBlindedClear, isEmpty);

        // Empty pool → skip interval, advance timestamp, no reward deducted
        if (isEmpty || denBlindedClear == 0) {
            lastDistributionTimestamp = block.timestamp;
            lastIntervalIndexDelta = 0;
            _clearTransients();
            distState = DistState.Idle;
            return;
        }

        // indexDelta_enc = numBlinded / denBlindedClear  (enc ÷ clear)
        euint128 indexDeltaEnc = FHE.allowThis(FHE.div(_pendingNumBlinded, uint128(denBlindedClear)));

        // Request public decryption of indexDelta
        _pendingIndexDeltaHandle = euint128.unwrap(FHE.makePubliclyDecryptable(indexDeltaEnc));

        distState = DistState.AwaitingIndexDelta;
    }

    // =========================================================================
    //  Distribution — Phase 3 (keeper callback with decrypted index delta)
    // =========================================================================

    /// @notice Supply the decrypted index delta with KMS proof. Finalizes the interval:
    ///         advances the cumulative index, deducts reward from budget, goes Idle.
    /// @param cleartexts [indexDeltaClear] from publicDecrypt
    /// @param decryptionProof KMS decryption signature
    function fulfillIndexDelta(uint256[] calldata cleartexts, bytes calldata decryptionProof) external {
        require(distState == DistState.AwaitingIndexDelta, WrongPhase());
        require(cleartexts.length == 1, BadLength());

        // Verify KMS decryption proof
        bytes32[] memory handles = new bytes32[](1);
        handles[0] = _pendingIndexDeltaHandle;
        FHE.checkSignatures(handles, abi.encode(cleartexts), decryptionProof);

        uint256 indexDeltaClear = cleartexts[0];

        cumulativeIndex += indexDeltaClear;
        lastIntervalIndexDelta = indexDeltaClear;
        lastDistributionTimestamp = block.timestamp;

        // Deduct interval reward from budget
        _rewardBudget = FHE.allowThis(FHE.sub(_rewardBudget, _pendingIntervalReward));

        _clearTransients();
        distState = DistState.Idle;

        emit DistributePhase3(indexDeltaClear, cumulativeIndex);
    }

    // =========================================================================
    //  Internal — Per-user settlement (Compound/MasterChef index pattern)
    // =========================================================================

    function _settle(address user) private {
        uint256 delta = cumulativeIndex - _userIndex[user];
        if (delta > 0 && FHE.isInitialized(_userStake[user])) {
            // Widen to euint128 for multiplication: accrued = userStake * delta / INDEX_SCALE
            euint128 stake128 = FHE.asEuint128(_userStake[user]);
            euint128 accrued128 = FHE.div(FHE.mul(stake128, uint128(delta)), uint128(INDEX_SCALE));
            euint64 accrued = FHE.asEuint64(accrued128);

            _userPendingReward[user] = FHE.allowThis(FHE.allow(FHE.add(_userPendingReward[user], accrued), user));
        }
        _userIndex[user] = cumulativeIndex;
    }

    function _clearTransients() private {
        _pendingNumBlinded = euint128.wrap(bytes32(0));
        _pendingIntervalReward = euint64.wrap(bytes32(0));
        _pendingDenHandle = bytes32(0);
        _pendingIsEmptyHandle = bytes32(0);
        _pendingIndexDeltaHandle = bytes32(0);
    }

    // =========================================================================
    //  View Functions
    // =========================================================================

    function getUserIndex(address user) external view returns (uint256) {
        return _userIndex[user];
    }

    function getUserStake(address user) external view returns (euint64) {
        return _userStake[user];
    }

    function getUserPendingReward(address user) external view returns (euint64) {
        return _userPendingReward[user];
    }

    function totalStaked() external view returns (euint64) {
        return _totalStaked;
    }

    function rewardBudget() external view returns (euint64) {
        return _rewardBudget;
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }

    /// @notice Returns handles needed by keepers to call publicDecrypt.
    function getPendingHandles()
        external
        view
        returns (bytes32 denHandle, bytes32 isEmptyHandle, bytes32 indexDeltaHandle)
    {
        return (_pendingDenHandle, _pendingIsEmptyHandle, _pendingIndexDeltaHandle);
    }

    /// @notice Annualized return based on the last interval's index delta.
    ///         APR = lastIntervalIndexDelta * (365 days / INTERVAL) / INDEX_SCALE
    function getAPR() external view returns (uint256) {
        return lastIntervalIndexDelta * 1460;
    }
}
