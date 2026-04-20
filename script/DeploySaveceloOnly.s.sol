// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {SaveCelo} from "../src/SaveCelo.sol";

contract DeploySaveceloOnly is Script {

    address constant SAVE_TOKEN  = 0x69D847a5697dd61686F8ed51f2e886fE2103C350;
    address constant CUSD_MAINNET = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        SaveCelo vault = new SaveCelo(SAVE_TOKEN);
        console.log("SaveCelo deployed at:", address(vault));

        vault.addToken(CUSD_MAINNET, "cUSD");
        console.log("cUSD added to vault:", CUSD_MAINNET);

        vm.stopBroadcast();
    }
}