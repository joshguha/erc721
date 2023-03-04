// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title ERC721MerkleProof - ERC721 with presale
 * @author Josh Guha
 * @notice Presale uses merkle proof to authenticate whitelist user
 */

contract ERC721MerkleProof is ERC721, ERC2981 {
    uint256 public totalSupply;

    uint256 constant MAX_SUPPLY = 10;
    uint256 constant PRICE = 0.1e18; // 0.1 MATIC price

    address public immutable deployer;
    bytes32 public immutable merkleRoot;

    // Storage variable for bitmap
    uint256 private bitmap =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; //2^256 - 1 (MAX_INT)

    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleRoot_
    ) ERC721(name, symbol) {
        deployer = msg.sender;
        merkleRoot = merkleRoot_;
        _setDefaultRoyalty(msg.sender, 250);
    }

    /**
     * @dev Override ERC721 and ERC2981 supportsInterface methods
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function to purchase new NFTs for constant price
     */
    function mint() external payable {
        // Total supply check
        uint256 _totalSupply = totalSupply;
        require(_totalSupply < MAX_SUPPLY);

        // Price check
        require(msg.value == PRICE, "Wrong price");

        // Mint NFT
        _mint(msg.sender, _totalSupply);
        unchecked {
            _totalSupply++;
        }
        totalSupply = _totalSupply;
    }

    /**
     * @dev Function to claim whitelist NFT
     * @param merkleProof Merkle proof to submit - grows logarithmically with the total number of users in the whitelist
     * @param ticketNumber Index of claimable NFT in user's whitelist allowance
     */
    function presale(
        bytes32[] calldata merkleProof,
        uint256 ticketNumber
    ) external {
        // Total supply check
        uint256 _totalSupply = totalSupply;
        require(totalSupply < MAX_SUPPLY);

        // Merkle root check
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticketNumber));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        // Ticket number check
        require(ticketNumber < MAX_SUPPLY, "too large");
        uint256 offsetWithin256 = ticketNumber % 256;
        uint256 storedBit = (bitmap >> offsetWithin256) & uint256(1);
        require(storedBit == 1, "already taken");

        // Update bitmap
        bitmap = bitmap & ~(uint256(1) << offsetWithin256);

        // Mint NFT
        _mint(msg.sender, _totalSupply);
        unchecked {
            _totalSupply++;
        }
        totalSupply = _totalSupply;
    }

    /**
     * @dev Function to withdraw funds from contract
     * @dev Only deployer can call
     */
    function withdraw() external {
        require(msg.sender == deployer, "Not deployer");

        uint256 balance = address(this).balance;
        (bool success, ) = deployer.call{value: balance}("");
        require(success, "Failed to send MATIC");
    }

    receive() external payable {
        require(false, "Can only receive MATIC through mint");
    }

    fallback() external payable {
        require(false, "Can only receive MATIC through mint");
    }
}
