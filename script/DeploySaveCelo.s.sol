// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SaveCelo.sol";

contract DeploySaveCelo is Script {
    
    function run() external returns (SaveCelo vault) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // ── Change this to your token address ──────────────────────────
        //
        //  Option A: Use the real cUSD on Celo Mainnet
        //    address cUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
        //
        //  Option B: Use cUSD on Alfajores Testnet
        //    address cUSD = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
        //
        //  Option C: Use your own deployed SaveToken address
        //    address cUSD = <output from DeployToken script>;
        //
        address cUSD = vm.envAddress("CUSD_ADDRESS");
        // ───────────────────────────────────────────────────────────────

        vm.startBroadcast(deployerKey);
        vault = new SaveCelo(cUSD);
        vm.stopBroadcast();

        console.log("SaveCelo deployed at:", address(vault));
        console.log("cUSD address set to:", cUSD);
    }
}