// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SaveCelo
 * @notice Multi-token savings vault on Celo with waitlist support.
 *         - Admin can add/remove supported tokens
 *         - Users can join the waitlist and be approved by admin
 *         - Approved users can deposit/withdraw any supported token
 */
contract SaveCelo {

    // ─────────────────────────────────────────────
    //  Access Control
    // ─────────────────────────────────────────────

    address public owner;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyApproved() {
        _onlyApproved();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "Not owner");
    }

    function _onlyApproved() internal view {
        require(_approved[msg.sender], "Not approved: join the waitlist");
    }

    // ─────────────────────────────────────────────
    //  Token Registry
    // ─────────────────────────────────────────────

    /// @notice List of all token addresses ever added
    address[] public supportedTokens;

    /// @notice True if a token is currently active
    mapping(address => bool) public tokenEnabled;

    /// @notice Human-readable label for each token (e.g. "cUSD", "cEUR")
    mapping(address => string) public tokenLabel;

    // ─────────────────────────────────────────────
    //  Waitlist
    // ─────────────────────────────────────────────

    enum WaitlistStatus { None, Pending, Approved, Rejected }

    mapping(address => WaitlistStatus) private _waitlistStatus;
    mapping(address => bool) private _approved;

    /// @notice Ordered list of every address that ever joined the waitlist
    address[] public waitlist;

    // ─────────────────────────────────────────────
    //  Balances  (user => token => amount)
    // ─────────────────────────────────────────────

    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => uint256)) private _totalDeposited;

    // ─────────────────────────────────────────────
    //  Events
    // ─────────────────────────────────────────────

    event TokenAdded(address indexed token, string label);
    event TokenDisabled(address indexed token);
    event TokenEnabled(address indexed token);

    event WaitlistJoined(address indexed user);
    event WaitlistApproved(address indexed user);
    event WaitlistRejected(address indexed user);

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    event OwnershipTransferred(address indexed previous, address indexed newOwner);

    // ─────────────────────────────────────────────
    //  Constructor
    // ─────────────────────────────────────────────

    /**
     * @param cUsd  Address of the first accepted token (e.g. cUSD or your SaveToken).
     *              Registered automatically with the label "cUSD".
     */
    constructor(address cUsd) {
        owner = msg.sender;
        _addToken(cUsd, "cUSD");
    }

    // ─────────────────────────────────────────────
    //  Admin: Token Management
    // ─────────────────────────────────────────────

    /**
     * @notice Add a new ERC-20 token to the accepted list.
     * @param token  Contract address of the token.
     * @param label  Short name shown in events, e.g. "cEUR".
     */
    function addToken(address token, string calldata label) external onlyOwner {
        require(token != address(0), "Zero address");
        require(!tokenEnabled[token], "Already enabled");
        _addToken(token, label);
    }

    /**
     * @notice Disable an existing token (deposits blocked; withdrawals still allowed).
     */
    function disableToken(address token) external onlyOwner {
        require(tokenEnabled[token], "Not enabled");
        tokenEnabled[token] = false;
        emit TokenDisabled(token);
    }

    /**
     * @notice Re-enable a previously disabled token.
     */
    function enableToken(address token) external onlyOwner {
        require(!tokenEnabled[token], "Already enabled");
        require(bytes(tokenLabel[token]).length > 0, "Token never added");
        tokenEnabled[token] = true;
        emit TokenEnabled(token);
    }

    /**
     * @notice Returns all supported token addresses (enabled or disabled).
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens;
    }

    // ─────────────────────────────────────────────
    //  Admin: Waitlist Management
    // ─────────────────────────────────────────────

    /**
     * @notice Approve a user who is on the waitlist.
     */
    function approveUser(address user) external onlyOwner {
        require(
            _waitlistStatus[user] == WaitlistStatus.Pending,
            "User not pending"
        );
        _waitlistStatus[user] = WaitlistStatus.Approved;
        _approved[user] = true;
        emit WaitlistApproved(user);
    }

    /**
     * @notice Reject a user who is on the waitlist.
     */
    function rejectUser(address user) external onlyOwner {
        require(
            _waitlistStatus[user] == WaitlistStatus.Pending,
            "User not pending"
        );
        _waitlistStatus[user] = WaitlistStatus.Rejected;
        emit WaitlistRejected(user);
    }

    /**
     * @notice Revoke access from a previously approved user.
     */
    function revokeUser(address user) external onlyOwner {
        require(_approved[user], "User not approved");
        _approved[user] = false;
        _waitlistStatus[user] = WaitlistStatus.Rejected;
        emit WaitlistRejected(user);
    }

    /**
     * @notice Returns the full waitlist array (admin use).
     */
    function getWaitlist() external view returns (address[] memory) {
        return waitlist;
    }

    // ─────────────────────────────────────────────
    //  Admin: Ownership
    // ─────────────────────────────────────────────

    /**
     * @notice Transfer ownership to a new address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ─────────────────────────────────────────────
    //  User: Waitlist
    // ─────────────────────────────────────────────

    /**
     * @notice Join the waitlist. Can only be called once per address.
     */
    function joinWaitlist() external {
        require(
            _waitlistStatus[msg.sender] == WaitlistStatus.None,
            "Already on waitlist"
        );
        _waitlistStatus[msg.sender] = WaitlistStatus.Pending;
        waitlist.push(msg.sender);
        emit WaitlistJoined(msg.sender);
    }

    /**
     * @notice Returns the caller's waitlist status.
     */
    function myWaitlistStatus() external view returns (WaitlistStatus) {
        return _waitlistStatus[msg.sender];
    }

    /**
     * @notice Returns any address's waitlist status.
     */
    function waitlistStatusOf(address user) external view returns (WaitlistStatus) {
        return _waitlistStatus[user];
    }

    // ─────────────────────────────────────────────
    //  User: Savings
    // ─────────────────────────────────────────────

    /**
     * @notice Deposit `amount` of `token` into savings.
     *         Caller must be approved and token must be enabled.
     * @param token   Address of the ERC-20 token to deposit.
     * @param amount  Amount in the token's native decimals.
     */
    function deposit(address token, uint256 amount) external onlyApproved {
        require(amount > 0, "Amount must be > 0");
        require(tokenEnabled[token], "Token not supported");
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        _balances[msg.sender][token] += amount;
        _totalDeposited[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    /**
     * @notice Withdraw a specific `amount` of `token`.
     * @param token   Address of the ERC-20 token to withdraw.
     * @param amount  Amount in the token's native decimals.
     */
    function withdraw(address token, uint256 amount) external onlyApproved {
        require(amount > 0, "Amount must be > 0");
        require(_balances[msg.sender][token] >= amount, "Insufficient savings");
        _balances[msg.sender][token] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, token, amount);
    }

    /**
     * @notice Withdraw the full balance of a specific `token`.
     * @param token  Address of the ERC-20 token to fully withdraw.
     */
    function withdrawAll(address token) external onlyApproved {
        uint256 amount = _balances[msg.sender][token];
        require(amount > 0, "No savings to withdraw");
        _balances[msg.sender][token] = 0;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, token, amount);
    }

    // ─────────────────────────────────────────────
    //  View Helpers
    // ─────────────────────────────────────────────

    /**
     * @notice Current savings balance of `user` for `token`.
     */
    function getBalance(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }

    /**
     * @notice Total ever deposited by `user` for `token`.
     */
    function totalDeposited(address user, address token) external view returns (uint256) {
        return _totalDeposited[user][token];
    }

    // ─────────────────────────────────────────────
    //  Internal
    // ─────────────────────────────────────────────

    function _addToken(address token, string memory label) internal {
        supportedTokens.push(token);
        tokenEnabled[token] = true;
        tokenLabel[token] = label;
        emit TokenAdded(token, label);
    }
}
