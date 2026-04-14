// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GhostReputation is Ownable {

    struct TradeRecord {
        uint256 ghostId;
        uint256 timestamp;
        string tokenIn;
        string tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        int256 pnlBps;
        bool hedgeAction;
        string txHash;
    }

    struct ReputationScore {
        uint256 ghostId;
        uint256 totalTrades;
        uint256 successfulTrades;
        uint256 totalHedges;
        uint256 successfulHedges;
        int256 cumulativePnLBps;
        uint256 longevityDays;
        uint256 rentalCount;
        uint256 score;
        uint256 lastUpdated;
    }

    struct RenterReview {
        uint256 ghostId;
        address renter;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }

    mapping(uint256 => ReputationScore) public reputations;
    mapping(uint256 => TradeRecord[]) public tradeHistory;
    mapping(uint256 => RenterReview[]) public reviews;
    mapping(uint256 => address) public authorizedReporters;
    mapping(uint256 => mapping(address => bool)) public hasReviewed;

    address public registryContract;

    event TradeRecorded(uint256 indexed ghostId, int256 pnlBps, string txHash);
    event HedgeRecorded(uint256 indexed ghostId, bool successful, string txHash);
    event ScoreUpdated(uint256 indexed ghostId, uint256 newScore);
    event ReviewSubmitted(uint256 indexed ghostId, address indexed renter, uint8 rating);

    constructor(address _registry) Ownable(msg.sender) {
        registryContract = _registry;
    }

    function authorizeReporter(uint256 ghostId, address reporter) external {
        require(msg.sender == registryContract || msg.sender == owner(), "Not authorized");
        authorizedReporters[ghostId] = reporter;
    }

    function recordTrade(
        uint256 ghostId,
        string memory tokenIn,
        string memory tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        int256 pnlBps,
        string memory txHash
    ) external {
        require(authorizedReporters[ghostId] == msg.sender || msg.sender == owner(), "Not authorized");

        tradeHistory[ghostId].push(TradeRecord({
            ghostId: ghostId,
            timestamp: block.timestamp,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: amountOut,
            pnlBps: pnlBps,
            hedgeAction: false,
            txHash: txHash
        }));

        ReputationScore storage rep = reputations[ghostId];
        rep.ghostId = ghostId;
        rep.totalTrades++;
        rep.cumulativePnLBps += pnlBps;
        if (pnlBps >= 0) rep.successfulTrades++;
        rep.lastUpdated = block.timestamp;

        _recomputeScore(ghostId);
        emit TradeRecorded(ghostId, pnlBps, txHash);
    }

    function recordHedge(
        uint256 ghostId,
        bool successful,
        int256 lossAvoided,
        string memory txHash
    ) external {
        require(authorizedReporters[ghostId] == msg.sender || msg.sender == owner(), "Not authorized");

        tradeHistory[ghostId].push(TradeRecord({
            ghostId: ghostId,
            timestamp: block.timestamp,
            tokenIn: "RISK_ASSET",
            tokenOut: "USDC",
            amountIn: 0,
            amountOut: 0,
            pnlBps: successful ? lossAvoided : int256(0),
            hedgeAction: true,
            txHash: txHash
        }));

        ReputationScore storage rep = reputations[ghostId];
        rep.totalTrades++;
        rep.totalHedges++;
        if (successful) {
            rep.successfulHedges++;
            rep.cumulativePnLBps += lossAvoided;
        }
        rep.lastUpdated = block.timestamp;
        _recomputeScore(ghostId);
        emit HedgeRecorded(ghostId, successful, txHash);
    }

    function submitReview(uint256 ghostId, uint8 rating, string memory comment) external {
        require(rating >= 1 && rating <= 5, "Rating 1-5");
        require(!hasReviewed[ghostId][msg.sender], "Already reviewed");
        hasReviewed[ghostId][msg.sender] = true;
        reviews[ghostId].push(RenterReview({
            ghostId: ghostId,
            renter: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        }));
        emit ReviewSubmitted(ghostId, msg.sender, rating);
        _recomputeScore(ghostId);
    }

    function incrementRentalCount(uint256 ghostId) external {
        require(msg.sender == owner() || msg.sender == registryContract, "Not authorized");
        reputations[ghostId].rentalCount++;
        _recomputeScore(ghostId);
    }

    function _recomputeScore(uint256 ghostId) internal {
        ReputationScore storage rep = reputations[ghostId];
        uint256 score = 0;

        if (rep.totalTrades > 0)
            score += (rep.successfulTrades * 300) / rep.totalTrades;

        if (rep.cumulativePnLBps > 0) {
            uint256 pnlScore = uint256(rep.cumulativePnLBps) >= 5000
                ? 300
                : (uint256(rep.cumulativePnLBps) * 300) / 5000;
            score += pnlScore;
        }

        score += rep.totalHedges > 0
            ? (rep.successfulHedges * 200) / rep.totalHedges
            : 100;

        uint256 rentalScore = rep.rentalCount > 20 ? 100 : rep.rentalCount * 5;
        uint256 reviewScore = 0;
        if (reviews[ghostId].length > 0) {
            uint256 total = 0;
            for (uint256 i = 0; i < reviews[ghostId].length; i++)
                total += reviews[ghostId][i].rating;
            reviewScore = (total / reviews[ghostId].length) * 20;
        }
        score += rentalScore + reviewScore;

        rep.score = score;
        emit ScoreUpdated(ghostId, score);
    }

    function getReputation(uint256 ghostId) external view returns (ReputationScore memory) {
        return reputations[ghostId];
    }

    function getScore(uint256 ghostId) external view returns (uint256) {
        return reputations[ghostId].score;
    }

    function getWinRate(uint256 ghostId) external view returns (uint256) {
        ReputationScore memory rep = reputations[ghostId];
        if (rep.totalTrades == 0) return 0;
        return (rep.successfulTrades * 10000) / rep.totalTrades;
    }
}
