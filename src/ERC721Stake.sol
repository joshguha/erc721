// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RewardToken is ERC20 {
    address public immutable deployer;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        deployer = msg.sender;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == deployer, "Not deployer");
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
        uint256[] tokens;
        mapping(uint256 => uint256) tokenStakeTime;
        uint256 currentTokensRewardClaimed;
    }

    constructor(ERC721Stake _erc721Stake) {
        rewardToken = new RewardToken("Reward", "REW");
        erc721Stake = _erc721Stake;
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(erc721Stake.ownerOf(_tokenId) == _user, "Not the owner");
        Staker storage staker = stakers[_user];
        uint256 tokensLength = staker.tokens.length;

        staker.tokens.push(tokensLength);
        staker.tokenStakeTime[tokensLength] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        erc721Stake.safeTransferFrom(_user, address(this), _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == _user, "Not the owner");
        Staker storage staker = stakers[_user];
        uint256[] memory tokens = staker.tokens;

        uint256 lastToken = tokens[tokens.length - 1];
        uint256 totalTokenEmission = ((block.timestamp -
            staker.tokenStakeTime[lastToken]) / STAKING_TIME) * EMISSION;

        // Assumes user has already claimed all emissions
        staker.currentTokensRewardClaimed = totalTokenEmission >
            staker.currentTokensRewardClaimed // Prevent underflow
            ? 0
            : staker.currentTokensRewardClaimed - totalTokenEmission;

        staker.tokens.pop();
        delete tokenOwner[_tokenId];

        erc721Stake.safeTransferFrom(address(this), _user, _tokenId);
    }

    function claimRewards(address _user) public {
        Staker storage staker = stakers[_user];
        uint256[] memory tokens = staker.tokens;
        uint256 cumulativeReward;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (
                staker.tokenStakeTime[tokens[i]] <
                block.timestamp + STAKING_TIME
            ) {
                uint256 stakedDays = (block.timestamp -
                    staker.tokenStakeTime[tokens[i]]) / STAKING_TIME;

                cumulativeReward += EMISSION * stakedDays;
            }
        }

        uint256 currentClaim = cumulativeReward -
            staker.currentTokensRewardClaimed;

        rewardToken.mint(_user, currentClaim);

        staker.currentTokensRewardClaimed = cumulativeReward;
    }

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
