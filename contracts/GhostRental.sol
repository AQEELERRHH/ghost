// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGhostRegistry {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isForRent(uint256 ghostId) external view returns (bool);
    function isActive(uint256 ghostId) external view returns (bool);
    struct GhostProfile {
        address owner; string name; uint8 riskLevel;
        uint256 minPosition; uint256 maxPosition; bool allowLeverage;
        string[] strategies; bool isActiveFlag; bool isForRentFlag;
        uint256 rentalFeePerHour; uint256 mintedAt; uint256 totalTrades;
        int256 totalPnL; string agentEndpoint; bool x402Enabled;
    }
    function getGhost(uint256 ghostId) external view returns (GhostProfile memory);
}

contract GhostRental is ReentrancyGuard, Ownable {

    IGhostRegistry public immutable registry;
    IERC20 public immutable usdc;
    uint256 public platformFeeBps = 500;
    address public feeRecipient;

    struct RentalSession {
        uint256 ghostId;
        address renter;
        address ghostOwner;
        uint256 startTime;
        uint256 endTime;
        uint256 hourlyRate;
        uint256 depositPaid;
        uint256 numHours;
        bool active;
        bool settled;
    }

    mapping(uint256 => RentalSession) public sessions;
    mapping(uint256 => uint256) public ghostActiveSession;
    mapping(address => uint256[]) public renterSessions;
    mapping(address => uint256) public ownerEarnings;
    uint256 private _sessionCounter;

    event SessionStarted(uint256 indexed sessionId, uint256 indexed ghostId, address indexed renter, uint256 hourlyRate, uint256 numHours);
    event SessionEnded(uint256 indexed sessionId, uint256 refundAmount, uint256 ownerPayout);
    event EarningsWithdrawn(address indexed owner, uint256 amount);

    constructor(address _registry, address _usdc) Ownable(msg.sender) {
        registry = IGhostRegistry(_registry);
        usdc = IERC20(_usdc);
        feeRecipient = msg.sender;
    }

    function rentGhost(uint256 ghostId, uint256 numHours) external nonReentrant returns (uint256 sessionId) {
        require(numHours >= 1 && numHours <= 168, "1-168 hours only");
        require(ghostActiveSession[ghostId] == 0, "Already rented");
        require(registry.isForRent(ghostId), "Not for rent");
        require(registry.isActive(ghostId), "Ghost not active");

        address ghostOwner = registry.ownerOf(ghostId);
        require(ghostOwner != msg.sender, "Cannot rent own Ghost");

        IGhostRegistry.GhostProfile memory ghost = registry.getGhost(ghostId);
        uint256 totalCost = ghost.rentalFeePerHour * numHours;
        require(totalCost > 0, "Cost too low");
        require(usdc.transferFrom(msg.sender, address(this), totalCost), "USDC transfer failed");

        sessionId = ++_sessionCounter;
        sessions[sessionId] = RentalSession({
            ghostId: ghostId,
            renter: msg.sender,
            ghostOwner: ghostOwner,
            startTime: block.timestamp,
            endTime: block.timestamp + (numHours * 3600),
            hourlyRate: ghost.rentalFeePerHour,
            depositPaid: totalCost,
            numHours: numHours,
            active: true,
            settled: false
        });

        ghostActiveSession[ghostId] = sessionId;
        renterSessions[msg.sender].push(sessionId);
        emit SessionStarted(sessionId, ghostId, msg.sender, ghost.rentalFeePerHour, numHours);
    }

    function endSession(uint256 sessionId) external nonReentrant {
        RentalSession storage session = sessions[sessionId];
        require(session.active, "Not active");
        require(
            msg.sender == session.renter ||
            msg.sender == session.ghostOwner ||
            msg.sender == owner(),
            "Not authorized"
        );

        session.active = false;
        session.settled = true;

        uint256 endTime = block.timestamp < session.endTime ? block.timestamp : session.endTime;
        uint256 usedHours = ((endTime - session.startTime) + 3599) / 3600;
        if (usedHours > session.numHours) usedHours = session.numHours;

        uint256 ownerGross = session.hourlyRate * usedHours;
        uint256 platformFee = (ownerGross * platformFeeBps) / 10000;
        uint256 ownerNet = ownerGross - platformFee;
        uint256 refund = session.depositPaid - ownerGross;

        ghostActiveSession[session.ghostId] = 0;
        ownerEarnings[session.ghostOwner] += ownerNet;

        if (platformFee > 0) usdc.transfer(feeRecipient, platformFee);
        if (refund > 0) usdc.transfer(session.renter, refund);

        emit SessionEnded(sessionId, refund, ownerNet);
    }

    function withdrawEarnings() external nonReentrant {
        uint256 amount = ownerEarnings[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        ownerEarnings[msg.sender] = 0;
        require(usdc.transfer(msg.sender, amount), "Transfer failed");
        emit EarningsWithdrawn(msg.sender, amount);
    }

    function getSession(uint256 sessionId) external view returns (RentalSession memory) {
        return sessions[sessionId];
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        feeRecipient = newRecipient;
    }
}
