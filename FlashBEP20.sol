// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FlashBEP20
 * @notice BEP-20 token for BNB Smart Chain with configurable supply and expiry.
 *         BEP-20 is interface-compatible with ERC-20, so this contract is a
 *         standard BEP-20 token on BSC and a standard ERC-20 on Sepolia/Ethereum.
 *
 *         After `expiry`, normal transfers revert. Mint and burn remain
 *         available so the deployer can still manage supply.
 */
contract FlashBEP20 is ERC20 {
    /// @notice Address that deployed the contract (the only privileged role).
    address public immutable deployer;

    /// @notice Unix timestamp after which normal transfers are blocked.
    uint256 public immutable expiry;

    /// @notice Emitted once when the token expires (for off-chain indexing).
    event TokenExpired(uint256 timestamp);

    /**
     * @param _name            Token name, e.g. "Tether"
     * @param _symbol          Token symbol, e.g. "USDT"
     * @param _initialSupply   Whole units minted to the deployer, e.g. 1000000
     * @param _durationSeconds Seconds until expiry, e.g. 86400 for 1 day
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _durationSeconds
    ) ERC20(_name, _symbol) {
        require(_durationSeconds > 0, "FlashBEP20: duration must be > 0");
        require(_initialSupply > 0, "FlashBEP20: supply must be > 0");

        deployer = msg.sender;
        expiry = block.timestamp + _durationSeconds;

        _mint(msg.sender, _initialSupply * 10**decimals());
    }

    /**
     * @notice Returns true once the token has expired.
     */
    function isExpired() public view returns (bool) {
        return block.timestamp >= expiry;
    }

    /**
     * @notice Returns seconds remaining until expiry (0 if expired).
     */
    function timeUntilExpiry() public view returns (uint256) {
        if (block.timestamp >= expiry) return 0;
        return expiry - block.timestamp;
    }

    /**
     * @dev Blocks normal transfers after expiry.
     *      Mint (from == 0) and burn (to == 0) stay allowed.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (from != address(0) && to != address(0)) {
            require(block.timestamp < expiry, "FlashBEP20: token expired");
        }
        super._update(from, to, value);
    }

    /**
     * @notice Deployer-only mint. Adds supply before or after expiry.
     * @param to     Recipient address
     * @param amount Amount in whole units
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == deployer, "FlashBEP20: not deployer");
        require(amount > 0, "FlashBEP20: amount must be > 0");
        _mint(to, amount * 10**decimals());
    }

    /**
     * @notice Burn your own tokens. Works after expiry too.
     * @param amount Amount in whole units
     */
    function burn(uint256 amount) external {
        require(amount > 0, "FlashBEP20: amount must be > 0");
        _burn(msg.sender, amount * 10**decimals());
    }

    /**
     * @notice Deployer-only burn from any address.
     * @param from   Address to burn from
     * @param amount Amount in whole units
     */
    function burnFrom(address from, uint256 amount) external {
        require(msg.sender == deployer, "FlashBEP20: not deployer");
        require(amount > 0, "FlashBEP20: amount must be > 0");
        _burn(from, amount * 10**decimals());
    }
}
