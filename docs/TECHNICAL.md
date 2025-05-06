# **Technical Whitepaper – Decentralized Escrow Smart Contract**

## **1. Introduction**
This document describes a secure, decentralized escrow system implemented as an Ethereum smart contract. The protocol enables trustless peer-to-peer transactions with built-in dispute resolution while maintaining full transparency through blockchain verification.

## **2. Core Features**
- **Secure fund custody** with time-bound protections
- **Cryptographic term verification** using keccak256 hashing
- **Automated fee distribution** (3% transaction fee)
- **Multi-party confirmation** requirement
- **Admin-mediated dispute resolution**
- **Non-custodial balance management**
- **ERC-20 token compatibility**

## **3. System Actors**

### **3.1 Participants**
- **Buyer**: Initiates transactions by depositing funds
- **Seller**: Receives funds upon successful completion
- **Admin**: Privileged role for dispute arbitration and fee collection

### **3.2 Smart Contract Components**
- **Escrow vault**: Holds funds until conditions are met
- **Deal registry**: Trades with associated metadata
- **Balance ledger**: Tracks owed amounts per user/token
- **Term verification**: Stores hashed agreement terms

## **4. Deal Lifecycle**

### **4.1 Creation Phase**
1. Parties agree to terms off-chain
2. Buyer submits:
   - Seller address
   - ERC-20 token address
   - Deposit amount
   - keccak256 hash of terms
3. Contract:
   - Deducts 3% fee
   - Stores remaining amount in escrow
   - Generates unique deal ID
   - Records terms hash immutably

### **4.2 Execution Phase**
- **Mutual Acceptance Path**:
  1. Both parties confirm acceptance
  2. Funds release to seller
  3. Deal marked complete

- **Dispute Path**:
  1. Either party flags dispute
  2. Admin arbitrates resolution
  3. Funds distributed per ruling

- **Timeout Path** (new):
  1. 30-day inactivity period
  2. Eligible party can trigger expiration
  3. Funds return to buyer

## **5. Security Architecture**

### **5.1 Fund Protection**
- Reentrancy guards on all transfers
- Segregated balance accounting
- Time-locked expiration as fail-safe

### **5.2 Term Integrity**
- Cryptographic hashing of agreements
- On-chain hash storage
- Immutable record per deal

### **5.3 Access Control**
- Participant-only modifiers
- Admin-restricted arbitration
- Self-custody withdrawals

## **6. Technical Implementation**

### **6.1 Storage Structure**
```solidity
struct Deal {
    address buyer;
    address seller;
    uint256 amount;
    uint256 timestamp;
    bool disputed;
    bool resolved;
    bool buyerAccepted;
    bool sellerAccepted;
    bytes32 termsHash;
    address tokenAddress;
}

mapping(uint256 => Deal) public deals;
mapping(address => mapping(address => uint256)) public bankroll;
```

### **6.2 Key Functions**
- `createDeal()`: Initiate new escrow
- `acceptDeal()`: Confirm participation
- `disputeDeal()`: Flag disagreement
- `resolveDispute()`: Admin arbitration
- `expireDeal()`: Timeout handler
- `withdraw()`: Claim available funds

### **6.3 Event Tracking**
```solidity
event DealCreated(uint256 dealId, address buyer, address seller...);
event DealAccepted(uint256 dealId, bool buyerAccepted...);
event DealDisputed(uint256 dealId, address by);
event DealResolved(uint256 dealId, bool favorBuyer...);
event DealExpired(uint256 dealId);
```

## **7. Economic Model**
- **Fixed 3% transaction fee**
- Fee accumulation in admin bankroll
- No recurring costs
- Gas-efficient dispute resolution

## **8. Integration Guide**

### **8.1 For DApps**
1. Encode terms as UTF-8 string
2. Generate termsHash:
   ```javascript
   const termsHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(termsText));
   ```
3. Call createDeal() with hash

### **8.2 For Users**
- Verify terms hash matches agreement
- Monitor deal status via events
- Withdraw funds to self-custody wallet

## **9. Compliance Features**
- Transparent audit trail
- Non-custodial design
- Immutable records
- No admin fund access beyond fees

## **Appendix A: Security Audit Summary**
The contract implements industry-standard protections including:
- Reentrancy guards
- Input validation
- SafeERC20 transfers
- Timeout safeguards
- Privilege separation

## **Appendix B: Sample Term Structure**
Recommended term format:
```
1. Delivery Timeline: [date]
2. Quality Standards: [specs]
3. Inspection Period: [days]
4. Jurisdiction: [location]
5. Arbitration: [process]
```