// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SaveCelo.sol";
import "../src/SaveToken.sol";

/**
 * @notice Deploys SaveToken + SaveCelo in one broadcast.
 *         At the end of the script both tokens are live in the vault:
 *           - SaveToken  (your custom token, e.g. SUSD)
 *           - cUSD       (real Celo stable coin)
 *
 * Usage:
 *   forge script script/DeployAll.s.sol \
 *     --rpc-url https://forno.celo.org \
 *     --broadcast --verify \
 *     --verifier-url https://api.celoscan.io/api \
 *     --etherscan-api-key $CELOSCAN_API_KEY \
 *     --legacy -vvvv
 */
contract DeployAll is Script {

    // ── Real Celo Mainnet stable coin addresses ──────────────────
    address constant CUSD_MAINNET = env.CUSD_Mainnet;
    // ─────────────────────────────────────────────────────────────

    function run() external {
        uint256 deployerKey     = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerKey);

        // ── Read token config from .env ──────────────────────────
        string  memory tokenName   = vm.envOr("TOKEN_NAME",   string("Save Dollar"));
        string  memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("SUSD"));
        uint256 initialSupply      = vm.envOr("TOKEN_SUPPLY",  uint256(1_000_000_000));
        // ─────────────────────────────────────────────────────────

        vm.startBroadcast(deployerKey);

        // 1. Deploy your custom token
        SaveToken saveToken = new SaveToken(
            tokenName,
            tokenSymbol,
            18,
            initialSupply  // minted to deployer wallet
        );
        console.log("SaveToken deployed at :", address(saveToken));
        console.log("  Name               :", tokenName);
        console.log("  Symbol             :", tokenSymbol);
        console.log("  Initial supply     :", initialSupply, tokenSymbol);
        console.log("  Minted to          :", deployerAddress);

        // 2. Deploy SaveCelo vault — SaveToken is registered as first token
        //    inside the constructor automatically
        SaveCelo vault = new SaveCelo(address(saveToken));
        console.log("SaveCelo deployed at  :", address(vault));

        // 3. Register real cUSD so the vault accepts it at launch
        vault.addToken(CUSD_MAINNET, "cUSD");
        console.log("cUSD added to vault   :", CUSD_MAINNET);

        vm.stopBroadcast();

        // ── Summary ──────────────────────────────────────────────
        console.log("--------------------------------------------");
        console.log("DEPLOYMENT COMPLETE");
        console.log("SaveToken  :", address(saveToken));
        console.log("SaveCelo   :", address(vault));
        console.log("Tokens live in vault:");
        console.log("  [0]", tokenSymbol, "->", address(saveToken));
        console.log("  [1] cUSD  ->", CUSD_MAINNET);
        console.log("Owner      :", deployerAddress);
        console.log("--------------------------------------------");
    }
}
