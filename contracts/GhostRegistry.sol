// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GhostRegistry is ERC721URIStorage, Ownable {

    uint256 private _tokenIdCounter;

    struct GhostProfile {
        address owner;
        string name;
        uint8 riskLevel;
        uint256 minPosition;
        uint256 maxPosition;
        bool allowLeverage;
        string[] strategies;
        bool isActive;
        bool isForRent;
        uint256 rentalFeePerHour;
        uint256 mintedAt;
        uint256 totalTrades;
        int256 totalPnL;
        string agentEndpoint;
        bool x402Enabled;
    }

    mapping(uint256 => GhostProfile) public ghosts;
    mapping(address => uint256[]) public ownerGhosts;
    mapping(uint256 => address) public ghostExecutors;
    mapping(uint256 => address) public activeRenter;

    event GhostMinted(uint256 indexed ghostId, address indexed owner, string name, uint8 riskLevel);
    event GhostActivated(uint256 indexed ghostId);
    event GhostDeactivated(uint256 indexed ghostId);
    event GhostListedForRent(uint256 indexed ghostId, uint256 feePerHour);
    event GhostStatUpdated(uint256 indexed ghostId, uint256 totalTrades, int256 totalPnL);
    event ExecutorSet(uint256 indexed ghostId, address indexed executor);

    constructor() ERC721("GHOST Agent", "GHOST") Ownable(msg.sender) {}

    function mintGhost(
        string memory name,
        uint8 riskLevel,
        uint256 minPosition,
        uint256 maxPosition,
        bool allowLeverage,
        string[] memory strategies,
        string memory agentURI,
        string memory agentEndpoint,
        bool x402Enabled
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Ghost needs a name");
        require(riskLevel >= 1 && riskLevel <= 5, "Risk level 1-5");
        require(minPosition <= maxPosition, "Min must be <= max");
        require(strategies.length > 0 && strategies.length <= 5, "1-5 strategies");

        uint256 ghostId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(msg.sender, ghostId);
        _setTokenURI(ghostId, agentURI);

        ghosts[ghostId] = GhostProfile({
            owner: msg.sender,
            name: name,
            riskLevel: riskLevel,
            minPosition: minPosition,
            maxPosition: maxPosition,
            allowLeverage: allowLeverage,
            strategies: strategies,
            isActive: false,
            isForRent: false,
            rentalFeePerHour: 0,
            mintedAt: block.timestamp,
            totalTrades: 0,
            totalPnL: 0,
            agentEndpoint: agentEndpoint,
            x402Enabled: x402Enabled
        });

        ownerGhosts[msg.sender].push(ghostId);
        emit GhostMinted(ghostId, msg.sender, name, riskLevel);
        return ghostId;
    }

    function activateGhost(uint256 ghostId) external {
        require(ownerOf(ghostId) == msg.sender, "Not your Ghost");
        ghosts[ghostId].isActive = true;
        emit GhostActivated(ghostId);
    }

    function deactivateGhost(uint256 ghostId) external {
        require(ownerOf(ghostId) == msg.sender, "Not your Ghost");
        ghosts[ghostId].isActive = false;
        emit GhostDeactivated(ghostId);
    }

    function listForRent(uint256 ghostId, uint256 feePerHour) external {
        require(ownerOf(ghostId) == msg.sender, "Not your Ghost");
        require(ghosts[ghostId].isActive, "Activate Ghost first");
        require(feePerHour > 0, "Fee must be > 0");
        ghosts[ghostId].isForRent = true;
        ghosts[ghostId].rentalFeePerHour = feePerHour;
        emit GhostListedForRent(ghostId, feePerHour);
    }

    function setExecutor(uint256 ghostId, address executor) external {
        require(ownerOf(ghostId) == msg.sender, "Not your Ghost");
        ghostExecutors[ghostId] = executor;
        emit ExecutorSet(ghostId, executor);
    }

    function updateStats(uint256 ghostId, uint256 totalTrades, int256 totalPnL) external {
        require(
            ghostExecutors[ghostId] == msg.sender || ownerOf(ghostId) == msg.sender,
            "Not authorized"
        );
        ghosts[ghostId].totalTrades = totalTrades;
        ghosts[ghostId].totalPnL = totalPnL;
        emit GhostStatUpdated(ghostId, totalTrades, totalPnL);
    }

    function getGhost(uint256 ghostId) external view returns (GhostProfile memory) {
        return ghosts[ghostId];
    }

    function getStrategies(uint256 ghostId) external view returns (string[] memory) {
        return ghosts[ghostId].strategies;
    }

    function getOwnerGhosts(address _owner) external view returns (uint256[] memory) {
        return ownerGhosts[_owner];
    }

    function totalGhosts() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function isActive(uint256 ghostId) external view returns (bool) {
        return ghosts[ghostId].isActive;
    }

    function isForRent(uint256 ghostId) external view returns (bool) {
        return ghosts[ghostId].isForRent;
    }
}
