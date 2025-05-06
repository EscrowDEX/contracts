# **Fees Structure & Mechanics**  

## **1. Overview**  
The escrow contract charges a **3% fee** on all transactions to maintain the service and support dispute resolution. This fee is automatically deducted when the buyer deposits funds into escrow.  

## **2. How Fees Work**  

### **2.1 Fee Calculation**  
- **Fee Percentage:** Fixed at **3%** of the total deposit.  
- **Example:**  
  - Deposit: **100 USDT**  
  - Fee: **3 USDT** (100 × 3%)  
  - Amount in Escrow: **97 USDT**  

### **2.2 Fee Distribution**  
- Fees accumulate in the **admin's balance** within the contract.  
- The admin can withdraw fees at any time to a designated wallet.  

### **2.3 Where Fees Go**  
| Amount | Destination | Purpose |  
|--------|------------|---------|  
| **3%** | Admin wallet | Covers operational costs, dispute resolution, and protocol maintenance. |  

## **3. When Are Fees Applied?**  
Fees are **only charged once**, when the buyer creates the deal:  

1. **Buyer deposits funds** → 3% fee is deducted.  
2. **Remaining amount (97%)** is locked in escrow.  
3. **No additional fees** on withdrawals or dispute resolutions.  

## **4. Why Do Fees Exist?**  
- **Sustain the protocol** (smart contract maintenance, upgrades).  
- **Fund dispute resolution** (admin arbitration, security audits).  
- **Prevent spam** (minimal fee discourages fake deals).  

## **5. Comparing Fees to Alternatives**  
| Service | Fee | Notes |  
|---------|-----|-------|  
| **This Escrow Contract** | **3%** | Transparent, one-time, on-chain. |  
| **Traditional Escrow** | **5–10%** | Higher fees, slower, centralized. |  
| **Direct Transfer** | **0% (but risky)** | No protection against scams. |  

## **6. How to Check Fees**  
You can verify fees in two ways:  

### **6.1 On-Chain Verification**  
- View the `DealCreated` event, which shows:  
  ```solidity
  event DealCreated(
      uint256 dealId,
      uint256 amount,
      uint256 fee,
      uint256 amountAfterFee
  );
  ```
- Example: A deposit of **100 USDT** emits:  
  ```json
  {
      "amount": 100,
      "fee": 3,
      "amountAfterFee": 97
  }
  ```

### **6.2 Via Smart Contract Functions**  
- **Admin fees:** `getAdminBalance(tokenAddress)` → Returns total fees collected.  
- **User balance:** `getUserBalance(userAddress, tokenAddress)` → Shows available funds (excludes fees).  

---

### **Summary**  
✅ **3% fee** → Deducted at deposit.  
✅ **No hidden costs** → Only charged once.  
✅ **Transparent tracking** → On-chain visibility.  
✅ **Funds protocol growth** → Supports security & arbitration.  