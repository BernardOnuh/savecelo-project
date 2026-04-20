// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SaveToken.sol";

contract DeployToken is Script {
    function run() external returns (SaveToken token) {
        // Load private key from .env
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        token = new SaveToken(
            "Save Dollar",   // name
            "SUSD",          // symbol
            18,              // decimals
            1_000_000_000        // initial supply: 1,000,000,000 SUSD minted to deployer
        );

        vm.stopBroadcast();

        console.log("SaveToken deployed at:", address(token));
    }
}