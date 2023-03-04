// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title ERC721AllowList - ERC721 with presale
 * @author Josh Guha
 * @notice Presale stores whitelist in allowList mapping
 */

contract ERC721AllowList is ERC721, ERC2981 {
    uint256 public totalSupply;
    mapping(address => uint256) public allowList;

    uint256 constant MAX_SUPPLY = 10;
    uint256 constant PRICE = 0.1e18; // 0.1 MATIC price

    address public immutable deployer;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        deployer = msg.sender;
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
        require(totalSupply < MAX_SUPPLY);

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
     * @dev Max number of NFTs claimable is stored in allowList[msg.sender]
     */
    function presale() external {
        // Total supply check
        uint256 _totalSupply = totalSupply;
        require(totalSupply < MAX_SUPPLY);

        // Allow list check
        uint256 allowance = allowList[msg.sender];
        require(allowance > 0, "Not allowed");

        // Update allow list
        unchecked {
            allowance -= 1;
        }
        allowList[msg.sender] = allowance;

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
        require(msg.sender == deployer, "Not deployer"); // Access control

        uint256 balance = address(this).balance;
        (bool success, ) = deployer.call{value: balance}("");
        require(success, "Failed to send MATIC");
    }

    /**
     * @dev Function to update the whitelist allowance
     * @dev Only deployer can call
     */
    function updateAllowance(address target, uint256 newAllowance) external {
        require(msg.sender == deployer, "Not deployer");
        allowList[target] = newAllowance;
    }

    receive() external payable {
        require(false, "Can only receive MATIC through mint");
    }

    fallback() external payable {
        require(false, "Can only receive MATIC through mint");
    }
}
