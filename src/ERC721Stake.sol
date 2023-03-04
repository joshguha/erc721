// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Staking Contract
 * @author Josh Guha
 * @notice StakeContract accepts ERC721Stake as stake asset and pays out RewardToken as stake reward
 */

contract RewardToken is ERC20 {
    address public immutable deployer;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        deployer = msg.sender;
    }

    /**
     * @dev Mints new ERC20 Reward Tokens
     * @dev Only the deployer can mint new tokens
     * @param account Address to mint to
     * @param amount Amount to mint
     */
    function mint(address account, uint256 amount) external {
        require(msg.sender == deployer, "Not deployer"); // Access control
        _mint(account, amount);
    }
}

contract ERC721Stake is ERC721 {
    uint256 public totalSupply;
    address public immutable deployer;

    uint256 constant MAX_SUPPLY = 5000;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        deployer = msg.sender;
    }

    /**
     * @dev Mints new ERC721Stake NFTs
     * @dev Only the deployer can mint new NFTs
     * @param to Address to mint to
     */
    function safeMint(address to) external payable {
        // Access control
        require(msg.sender == deployer, "Not deployer");

        // Total supply check
        uint256 _totalSupply = totalSupply;
        require(_totalSupply < MAX_SUPPLY, "Mint cap reached");

        // Mint NFT
        _safeMint(to, _totalSupply);
        unchecked {
            _totalSupply++;
        }
        totalSupply = _totalSupply;
    }
}

contract StakeContract is IERC721Receiver {
    RewardToken private rewardToken;
    ERC721Stake private erc721Stake;

    uint256 constant STAKING_TIME = 1 days;
    uint256 constant EMISSION = 10e18;

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    struct Staker {
        uint256 stakedTokenCount;
        mapping(uint256 => uint256) tokenStakeTime;
        uint256 currentTokensRewardClaimed;
    }

    constructor(ERC721Stake _erc721Stake) {
        rewardToken = new RewardToken("Reward", "REW");
        erc721Stake = _erc721Stake;
    }

    /**
     * @dev Stakes ERC721Stake in this contract
     * @dev Only the deployer can mint new NFTs
     * @dev From the perspective of stake reward calculation, the stake tokens are considered fungible
     * @param _user Address which owns nft
     * @param _tokenId tokenId of nft
     */
    function _stake(address _user, uint256 _tokenId) internal {
        require(erc721Stake.ownerOf(_tokenId) == _user, "Not the owner");
        Staker storage staker = stakers[_user];

        // staker.tokens does not discriminate between tokenIds
        staker.tokenStakeTime[++staker.stakedTokenCount] = block.timestamp;
        tokenOwner[_tokenId] = _user;

        // External calls at the end to prevent reentrancy attacks
        erc721Stake.safeTransferFrom(_user, address(this), _tokenId);
    }

    /**
     * @dev Unstakes ERC721Stake from this contract
     * @dev when a user unstakes, the latest staked item is unstaked (only from reward calculation perspective)
     * @notice User can lose claimable reward tokens if he/she unstakes a token without claiming stake rewards
     * @param _user Address to unstake to (must be the same address that staked)
     * @param _tokenId tokenId of ERC721Stake
     */
    function _unstake(address _user, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == _user, "Not the owner");
        Staker storage staker = stakers[_user];

        uint256 totalTokenEmission = ((block.timestamp -
            staker.tokenStakeTime[staker.stakedTokenCount--]) / STAKING_TIME) *
            EMISSION;

        // Assumes user has already claimed all emissions
        staker.currentTokensRewardClaimed = totalTokenEmission >
            staker.currentTokensRewardClaimed // Prevent underflow
            ? 0
            : staker.currentTokensRewardClaimed - totalTokenEmission;

        delete tokenOwner[_tokenId];

        erc721Stake.safeTransferFrom(address(this), _user, _tokenId);
    }

    /**
     * @dev Claim rewards from staking
     * @param _user Address to of user to claim reward for
     */
    function claimRewards(address _user) public {
        Staker storage staker = stakers[_user];
        uint256 stakedTokenCount = staker.stakedTokenCount;
        uint256 cumulativeReward;

        for (uint256 i = 0; i < stakedTokenCount; i++) {
            uint256 tokenStakeTime = staker.tokenStakeTime[i];
            if (tokenStakeTime < block.timestamp + STAKING_TIME) {
                uint256 stakedDays = (block.timestamp - tokenStakeTime) /
                    STAKING_TIME;

                cumulativeReward += EMISSION * stakedDays;
            }
        }

        uint256 currentClaim = cumulativeReward -
            staker.currentTokensRewardClaimed;

        rewardToken.mint(_user, currentClaim);

        staker.currentTokensRewardClaimed = cumulativeReward;
    }

    /**
     * @dev Implementation of IERC721Receiver.onERC721Received
     */
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
