// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/PrimeCounter.sol";

contract PrimeCounterTest is Test {
    MyEnumerableNFT public nft;
    PrimeCounter public primeCounter;

    function setUp() public virtual {
        nft = new MyEnumerableNFT("NFT", "SYM");
        primeCounter = new PrimeCounter(nft);
    }

    function testPrimeCounter() public {
        for (uint256 i; i < 10; i++) {
            nft.mint(address(nft)); // Mint first 10 elsewhere
        }
        for (uint256 i; i < 4; i++) {
            nft.mint(address(this)); // Mint 10, 11, 12, 12 to this contract
        }
        uint256 count = primeCounter.countPrimes(address(this));
        assertEq(count, 2);
    }
}
