// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SaveToken
 * @notice A simple ERC-20 token with owner-controlled minting.
 *         Deploy this to create your own savings token, or use
 *         the real cUSD address on Celo for production.
 */

contract SaveToken is ERC20, Ownable {

    uint8 private _decimals;

    /**
     * @param name_       Full token name, e.g. "Save Dollar"
     * @param symbol_     Ticker, e.g. "SUSD"
     * @param decimals_   Usually 18 (same as cUSD)
     * @param initialSupply  Amount minted to deployer (in whole tokens, NOT wei)
     */
     
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _decimals = decimals_;
        // Mint initial supply to deployer
        _mint(msg.sender, initialSupply * (10 ** decimals_));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mint new tokens. Only callable by owner.
     * @param to      Recipient address
     * @param amount  Amount in wei (multiply by 1e18 for whole tokens)
     */
     
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @notice Burn tokens from caller's wallet.
     */

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}