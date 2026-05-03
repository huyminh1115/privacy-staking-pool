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
