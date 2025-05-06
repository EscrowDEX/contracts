// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public admin;
    uint256 public constant FEE_PERCENTAGE = 3;
    uint256 public constant DEAL_TIMEOUT = 30 days;

    mapping(address => mapping(address => uint256)) public bankroll;
    uint256 public dealIdCounter;

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

    event DealCreated(
        uint256 dealId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 fee,
        uint256 amountAfterFee,
        bytes32 termsHash,
        uint256 timestamp,
        address tokenAddress
    );

    event DealAccepted(
        uint256 dealId,
        address buyer,
        address seller,
        bool buyerAccepted,
        bool sellerAccepted
    );

    event DealDisputed(uint256 dealId, address by, bool disputed);

    event DealResolved(
        uint256 dealId,
        bool favorBuyer,
        address resolvedBy,
        uint256 amountTransferred
    );

    event DealExpired(uint256 dealId, address initiatedBy);

    event FeesWithdrawn(address admin, uint256 amount, address tokenAddress);

    event Withdrawn(address target, uint256 amount, address tokenAddress);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }

    modifier onlyParticipant(uint256 _dealId) {
        Deal storage deal = deals[_dealId];
        require(
            msg.sender == deal.buyer || msg.sender == deal.seller,
            "Not a participant in this deal"
        );
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        require(
            _amount >= 100,
            "Amount must be at least 100 to avoid zero fees"
        );
        _;
    }

    modifier onlyNonResolvedDeal(uint256 _dealId) {
        require(!deals[_dealId].resolved, "Deal already resolved");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createDeal(
        address _seller,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _termsHash
    )
        external
        onlyValidAmount(_amount)
        onlyValidAddress(_seller)
        onlyValidAddress(_tokenAddress)
        nonReentrant
    {
        uint256 fee = (_amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = _amount - fee;

        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        dealIdCounter++;

        deals[dealIdCounter] = Deal({
            buyer: msg.sender,
            seller: _seller,
            amount: amountAfterFee,
            timestamp: block.timestamp,
            disputed: false,
            resolved: false,
            buyerAccepted: false,
            sellerAccepted: false,
            termsHash: _termsHash,
            tokenAddress: _tokenAddress
        });

        bankroll[admin][_tokenAddress] += fee;
        bankroll[address(this)][_tokenAddress] += amountAfterFee;

        emit DealCreated(
            dealIdCounter,
            msg.sender,
            _seller,
            _amount,
            fee,
            amountAfterFee,
            _termsHash,
            block.timestamp,
            _tokenAddress
        );
    }

    function acceptDeal(
        uint256 _dealId
    )
        external
        onlyParticipant(_dealId)
        onlyNonResolvedDeal(_dealId)
        nonReentrant
    {
        Deal storage deal = deals[_dealId];
        require(
            block.timestamp <= deal.timestamp + DEAL_TIMEOUT,
            "Deal has expired"
        );

        uint256 balanceBefore = IERC20(deal.tokenAddress).balanceOf(
            address(this)
        );

        if (msg.sender == deal.buyer) {
            deal.buyerAccepted = true;
        } else if (msg.sender == deal.seller) {
            deal.sellerAccepted = true;
        }

        if (deal.buyerAccepted && deal.sellerAccepted) {
            _completeDeal(_dealId, deal.seller, deal.amount, deal.tokenAddress);

            uint256 balanceAfter = IERC20(deal.tokenAddress).balanceOf(
                address(this)
            );

            require(
                balanceAfter == balanceBefore,
                "Token transfer failed or incorrect amount"
            );

            emit DealAccepted(
                _dealId,
                deal.buyer,
                deal.seller,
                deal.buyerAccepted,
                deal.sellerAccepted
            );
        }
    }

    function _completeDeal(
        uint256 _dealId,
        address _recipient,
        uint256 _amount,
        address _tokenAddress
    ) private {
        deals[_dealId].resolved = true;
        bankroll[_recipient][_tokenAddress] += _amount;
        bankroll[address(this)][_tokenAddress] -= _amount;
    }

    function disputeDeal(
        uint256 _dealId
    ) external onlyParticipant(_dealId) onlyNonResolvedDeal(_dealId) {
        deals[_dealId].disputed = true;
        emit DealDisputed(_dealId, msg.sender, true);
    }

    function resolveDispute(
        uint256 _dealId,
        bool _favorBuyer
    ) external onlyAdmin onlyNonResolvedDeal(_dealId) nonReentrant {
        Deal storage deal = deals[_dealId];
        require(deal.disputed, "Deal is not disputed");
        deal.resolved = true;

        address recipient = _favorBuyer ? deal.buyer : deal.seller;
        bankroll[recipient][deal.tokenAddress] += deal.amount;
        bankroll[address(this)][deal.tokenAddress] -= deal.amount;

        emit DealResolved(_dealId, _favorBuyer, msg.sender, deal.amount);
    }

    function expireDeal(
        uint256 _dealId
    )
        external
        onlyParticipant(_dealId)
        onlyNonResolvedDeal(_dealId)
        nonReentrant
    {
        Deal storage deal = deals[_dealId];
        require(
            block.timestamp > deal.timestamp + DEAL_TIMEOUT,
            "Deal has not expired yet"
        );
        require(!deal.disputed, "Disputed deals cannot expire");

        uint256 balanceBefore = IERC20(deal.tokenAddress).balanceOf(
            address(this)
        );

        _completeDeal(_dealId, deal.buyer, deal.amount, deal.tokenAddress);

        uint256 balanceAfter = IERC20(deal.tokenAddress).balanceOf(
            address(this)
        );

        require(
            balanceAfter == balanceBefore,
            "Token transfer failed or incorrect amount"
        );

        emit DealExpired(_dealId, msg.sender);
    }

    function withdrawFees(
        address _to,
        address _tokenAddress
    ) external onlyAdmin onlyValidAddress(_to) nonReentrant {
        uint256 amount = bankroll[admin][_tokenAddress];
        require(amount > 0, "No fees to withdraw");

        bankroll[admin][_tokenAddress] = 0;
        IERC20(_tokenAddress).safeTransfer(_to, amount);

        emit FeesWithdrawn(_to, amount, _tokenAddress);
    }

    function withdraw(
        address _to,
        uint256 amount,
        address _tokenAddress
    ) external nonReentrant {
        require(
            bankroll[msg.sender][_tokenAddress] >= amount,
            "Insufficient balance"
        );
        require(_to == msg.sender, "You can only withdraw to your own address");

        bankroll[msg.sender][_tokenAddress] -= amount;
        IERC20(_tokenAddress).safeTransfer(_to, amount);

        emit Withdrawn(_to, amount, _tokenAddress);
    }

    function getAdminBalance(
        address _tokenAddress
    ) external view returns (uint256) {
        return bankroll[admin][_tokenAddress];
    }

    function getUserBalance(
        address _user,
        address _tokenAddress
    ) external view returns (uint256) {
        return bankroll[_user][_tokenAddress];
    }

    function getContractBalance(
        address _tokenAddress
    ) external view returns (uint256) {
        return bankroll[address(this)][_tokenAddress];
    }

    function getTermsHash(uint256 _dealId) external view returns (bytes32) {
        return deals[_dealId].termsHash;
    }

    function getDeal(uint256 _dealId) external view returns (Deal memory) {
        return deals[_dealId];
    }
}
