// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint() external payable returns (bool) {
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

        return true;
    }

    function presale() external returns (bool) {
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

        return true;
    }

    function withdraw() external returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = deployer.call{value: balance}("");
        require(success, "Failed to send MATIC");
        return true;
    }

    function updateAllowance(
        address target,
        uint256 newAllowance
    ) external returns (bool) {
        require(msg.sender == deployer, "Not deployer");
        allowList[target] = newAllowance;
        return true;
    }

    receive() external payable {
        require(false, "Can only receive MATIC through mint");
    }

    fallback() external payable {
        require(false, "Can only receive MATIC through mint");
    }
}
