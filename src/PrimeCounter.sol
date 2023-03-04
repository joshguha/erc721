// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title ERC721Enumerable and PrimeCounter
 * @author Josh Guha
 * @dev PrimeCounter counts number of tokens with prime number token ids which a user has
 */

contract MyEnumerableNFT is ERC721Enumerable {
    uint256 constant MAX_SUPPLY = 20;

    address public immutable deployer;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        deployer = msg.sender;
    }

    /**
     * @dev Function to mint tokens with tokenId in set [1, 2, ... 20]
     * @param to Address to mint tokens to
     */
    function mint(address to) external payable {
        // Access control
        require(msg.sender == deployer);

        // Total supply check
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);

        // Mint NFT
        _mint(to, _totalSupply + 1); // Token ids 1 - 20
    }
}

contract PrimeCounter {
    ERC721Enumerable private erc721Enumerable;

    uint256[8] PRIMES = [2, 3, 5, 7, 11, 13, 17, 19];

    constructor(ERC721Enumerable _erc721Enumerable) {
        erc721Enumerable = _erc721Enumerable;
    }

    /**
     * @dev Function to count number of tokens with prime number token ids of a given user
     * @dev Uses double for loop - O(n^2)
     * @param owner Owner of NFT
     */
    function countPrimes(address owner) public view returns (uint) {
        uint256 balance = erc721Enumerable.balanceOf(owner);
        uint256 count;

        for (uint256 i; i < balance; i++) {
            uint256 tokenIndex = erc721Enumerable.tokenOfOwnerByIndex(owner, i);

            for (uint256 j; j < PRIMES.length; j++) {
                if (tokenIndex == PRIMES[j]) {
                    count++;
                    break; // Prevent unnecessary checks once match found
                }
            }
        }

        return count;
    }
}
