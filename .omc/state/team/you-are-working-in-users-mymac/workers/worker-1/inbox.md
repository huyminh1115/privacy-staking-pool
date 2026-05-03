## REQUIRED: Task Lifecycle Commands

You MUST run these commands. Do NOT skip any step.

1. Claim your task:
   omc team api claim-task --input '{"team_name":"you-are-working-in-users-mymac","task_id":"1","worker":"worker-1"}' --json
   Save the claim_token from the response.
2. Do the work described below.
3. On completion (use claim_token from step 1):
   omc team api transition-task-status --input '{"team_name":"you-are-working-in-users-mymac","task_id":"1","from":"in_progress","to":"completed","claim_token":"<claim_token>"}' --json
4. On failure (use claim_token from step 1):
   omc team api transition-task-status --input '{"team_name":"you-are-working-in-users-mymac","task_id":"1","from":"in_progress","to":"failed","claim_token":"<claim_token>"}' --json
5. ACK/progress replies are not a stop signal. Keep executing your assigned or next feasible work until the task is actually complete or failed, then transition and exit.

## Task Assignment

Task ID: 1
Worker: worker-1
Subject: You are working in /Users/mymac/Workspace/Zama/privacy-staking-pool — a Foundry

You are working in /Users/mymac/Workspace/Zama/privacy-staking-pool — a Foundry project using Zama fhEVM for FHE-encrypted staking.

The main contract is already implemented at packages/foundry/src/PrivacyStakingPool.sol. Your job:

1. Write packages/foundry/test/PrivacyStakingPool.t.sol — comprehensive Foundry tests using FhevmTest base class. The test infrastructure is at forge-fhevm (see packages/foundry/dependencies/forge-fhevm-eba2324/src/FhevmTest.sol). Use ERC7984Mock from @openzeppelin/confidential-contracts/mocks/token/ERC7984Mock.sol for mock tokens. See the existing test at packages/foundry/test/FHECounter.t.sol for patterns. Tests must cover:
   - Pool initialization (creator funds pool with encrypted budget + interval reward)
   - Staking (user encrypts amount, stakes via pool)
   - Full distribution cycle (3 phases: distribute → fulfillDenominator → fulfillIndexDelta)
   - Claiming rewards
   - Unstaking
   - Edge cases: empty pool distribution skip, not-idle revert, interval timing

   Key test helpers: encryptUint64(value, user, target), publicDecrypt(handles), userDecrypt(handle, user, contract, sig), signUserDecrypt(pk, contract). Users must call stakeToken.setOperator(pool, type(uint48).max) before staking. Creator must call rewardToken.setOperator(pool, type(uint48).max) before initialize.

2. Write packages/foundry/script/DeployPrivacyStakingPool.s.sol — simple Foundry deploy script.

3. Run 'cd packages/foundry && forge build' to verify everything compiles. Fix any errors.

Important: Read the existing PrivacyStakingPool.sol, FHECounter.t.sol, FhevmTest.sol, and ERC7984Mock.sol first to understand the APIs and patterns before writing code.

REMINDER: You MUST run transition-task-status before exiting. Do NOT write done.json or edit task files directly.

---

## REQUIRED: Structured Verdict Output

You are acting in the `test-engineer` role. Before you exit, write a JSON verdict to:

    /Users/mymac/Workspace/Zama/privacy-staking-pool/.omc/state/team/you-are-working-in-users-mymac/workers/worker-1/verdict.json

Schema (all keys required; `findings` may be an empty array):

```json
{
  "role": "test-engineer",
  "task_id": "<task id from the assignment above>",
  "verdict": "approve" | "revise" | "reject",
  "summary": "one- or two-sentence overall assessment",
  "findings": [
    {
      "severity": "critical" | "major" | "minor" | "nit",
      "message": "what is wrong and why it matters",
      "file": "optional/path/to/file",
      "line": 42
    }
  ]
}
```

Rules:

- Write valid JSON only (no surrounding prose, no markdown fences in the file).
- `verdict` MUST be one of `approve`, `revise`, or `reject`.
- Each finding MUST carry a `severity` from the enum above.
- Use `approve` only when you have no blocking concerns.
- If you cannot produce a verdict, write `{"verdict":"revise", ...}` with an explanatory finding rather than exiting silently.
- The team leader reads this file to mark the task complete; omitting it leaves the task stuck in_progress pending human review.
