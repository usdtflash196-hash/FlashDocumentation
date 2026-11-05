

# FlashBEP20 Smart Contract Documentation

## 1. Overview
**FlashBEP20** is a standard BEP-20 (Binance Smart Chain) / ERC-20 (Ethereum) compliant token with a built-in **expiration mechanism**. 

Unlike a standard token, this contract allows the deployer to set a specific lifespan for the token (e.g., 24 hours). Once that time has passed, the token becomes "frozen," and all standard transfers are permanently blocked. However, the deployer retains the ability to mint (create) or burn (destroy) tokens even after expiration.

*   **Standard:** BEP-20 (Interface-identical to ERC-20)
*   **Solidity Version:** `^0.8.30`
*   **Dependencies:** OpenZeppelin Contracts (`ERC20.sol`)
*   **License:** MIT

---

## 2. Core State Variables

| Variable | Type | Description |
| :--- | :--- | :--- |
| `deployer` | `address` | The wallet address that deployed the contract. It is immutable (cannot be changed) and holds special privileges (minting and forced burning). |
| `expiry` | `uint256` | A Unix timestamp representing the exact moment the token will expire. It is calculated as `block.timestamp + _durationSeconds` at the time of deployment. |

---

## 3. Events

*   **`TokenExpired(uint256 timestamp)`**: Emitted off-chain to allow indexing tools (like Etherscan/BscScan) to know exactly when the token's transfer functionality has ended.

---

## 4. Constructor

When deploying the contract, you must provide four arguments:

```solidity
constructor(
    string memory _name,
    string memory _symbol,
    uint256 _initialSupply,
    uint256 _durationSeconds
)
```

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| `_name` | `string` | `"Tether"` | The full name of the token. |
| `_symbol` | `string` | `"USDT"` | The ticker symbol of the token. |
| `_initialSupply` | `uint256` | `1000000` | The number of **whole tokens** to mint to the deployer upon creation. *(The contract automatically multiplies this by `10**18` for decimals).* |
| `_durationSeconds` | `uint256` | `86400` | The lifespan of the token in seconds. *(e.g., 86400 = 24 hours, 604800 = 7 days).* |

---

## 5. Functions

### 🟢 View Functions (Read-Only)

*   **`isExpired() returns (bool)`**
    *   Returns `true` if the current time is greater than or equal to the `expiry` timestamp. Returns `false` otherwise.
*   **`timeUntilExpiry() returns (uint256)`**
    *   Returns the number of seconds remaining until the token expires. If already expired, it returns `0`.

### 🟠 State-Changing Functions (Write)

*   **`mint(address to, uint256 amount)`**
    *   **Access:** Deployer Only.
    *   **Description:** Creates new tokens and sends them to the specified address. The `amount` is entered in whole units (e.g., `100` will mint 100 tokens). Works both before and after expiry.
*   **`burn(uint256 amount)`**
    *   **Access:** Anyone.
    *   **Description:** Destroys the specified amount of tokens from the caller's own wallet balance. Works both before and after expiry.
*   **`burnFrom(address from, uint256 amount)`**
    *   **Access:** Deployer Only.
    *   **Description:** Allows the deployer to forcefully destroy tokens from any other wallet address. Works both before and after expiry.

---

## 6. The Expiry Logic (`_update` Override)

This is the most important part of the contract. OpenZeppelin's `_update` function handles *all* token movements (transfers, minting, and burning). We override it to add the timer:

```solidity
function _update(address from, address to, uint256 value) internal override {
    // If it's a normal transfer (not a mint or burn), check the timer
    if (from != address(0) && to != address(0)) {
        require(block.timestamp < expiry, "FlashBEP20: token expired");
    }
    super._update(from, to, value);
}
```
*   If `from` is `0x0`, it’s a **mint** (allows it to bypass the timer).
*   If `to` is `0x0`, it’s a **burn** (allows it to bypass the timer).
*   If it’s a normal wallet-to-wallet transfer, it checks the current time against `expiry`.

---

## 7. Behavior Matrix: Before vs. After Expiry

| Action | Before Expiry | After Expiry |
| :--- | :--- | :--- |
| **Transfer tokens** | ✅ Allowed | ❌ Reverts (`"FlashBEP20: token expired"`) |
| **Approve spending** | ✅ Allowed | ✅ Allowed (Approvals don't move tokens) |
| **Mint (Deployer)** | ✅ Allowed | ✅ Allowed |
| **Burn (Self)** | ✅ Allowed | ✅ Allowed |
| **BurnFrom (Deployer)** | ✅ Allowed | ✅ Allowed |
| **Check Balances/Info** | ✅ Allowed | ✅ Allowed |

---

## 8. How to Deploy (Remix IDE)

1.  **Compile:** Open Remix, go to the Solidity Compiler tab, select version **0.8.30** or higher, and compile the file.
2.  **Environment:** Go to the Deploy & Run Transactions tab. Set the Environment to **Injected Provider - MetaMask**.
3.  **Network:** Ensure MetaMask is connected to **BNB Smart Chain** (Testnet or Mainnet).
4.  **Arguments:** Fill in the constructor arguments:
    *   `_name`: `"Tether"`
    *   `_symbol`: `"USDT"`
    *   `_initialSupply`: `1000000`
    *   `_durationSeconds`: `86400` (for 1 day)
5.  **Deploy:** Click **Deploy** and confirm the transaction in MetaMask.
6.  **Import:** Copy the deployed contract address, open MetaMask, click **Import Tokens**, and paste the address to see your balance.

---
