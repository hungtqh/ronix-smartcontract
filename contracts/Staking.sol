// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking is UUPSUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    struct StakingReward {
        uint128 blockNumber;
        uint128 amount;
    }

    mapping(address => mapping(address => mapping(uint => bool)))
        public userNFTStaked; // contractAddr => userAddr => tokenId => isStaked
    mapping(address => uint256[]) nftStaked; // contractAddress => tokenIds
    mapping(uint256 => mapping(address => uint256)) usersTotalNFTStaked; // blockNumber => address => usersTotalNFTStaked
    address[] approvedNFTContracts;
    address usdtAddress;
    address ronixAddress;
    bytes32 public constant COLLATERAL_ROLE = keccak256("COLLATERAL_ROLE");
    mapping(uint256 => StakingReward) blockRewards; // roundId => blockNumber => reward
    mapping(uint256 => mapping(address => bool)) rewardClaimed; // roundId => address => isClaimed
    uint256 public totalNFTStaked;

    function initialize(
        address[] calldata _approvedNFTContracts,
        address _usdtAddress,
        address _ronixAddress
    ) external initializer {
        approvedNFTContracts = _approvedNFTContracts;
        usdtAddress = _usdtAddress;
        ronixAddress = _ronixAddress;

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function stakeNFT(address _nftContract, uint256 _tokenId) external {
        IERC721Enumerable(_nftContract).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        userNFTStaked[_nftContract][msg.sender][_tokenId] = true;
        unchecked {
            totalNFTStaked++;
            uint blockNFTStaked = usersTotalNFTStaked[block.number][msg.sender];

            usersTotalNFTStaked[block.number][msg.sender] = blockNFTStaked == 0
                ? usersTotalNFTStaked[block.number - 1][msg.sender] + 1
                : blockNFTStaked + 1;
        }
    }

    function unstakeNFT(address _nftContract, uint256 _tokenId) external {
        require(
            userNFTStaked[_nftContract][msg.sender][_tokenId],
            "NFT was not staked"
        );

        IERC721Enumerable(_nftContract).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        unchecked {
            totalNFTStaked--;
            uint blockNFTStaked = usersTotalNFTStaked[block.number][msg.sender];

            usersTotalNFTStaked[block.number][msg.sender] = blockNFTStaked == 0
                ? usersTotalNFTStaked[block.number - 1][msg.sender] - 1
                : usersTotalNFTStaked[block.number][msg.sender] - 1;
        }
    }

    function setBlockReward(
        uint256 _roundId,
        uint256 _blockNumber,
        uint256 _ronixAmount
    ) external onlyRole(COLLATERAL_ROLE) {
        blockRewards[_roundId] = StakingReward({
            amount: uint128(_ronixAmount),
            blockNumber: uint128(_blockNumber)
        });
    }

    function ronixEarned(
        uint256 _roundId
    ) public view returns (uint256 claimableAmount) {
        uint256 totalNFTs = 0;
        for (uint i = 0; i < approvedNFTContracts.length; ++i) {
            unchecked {
                totalNFTs += IERC721Enumerable(approvedNFTContracts[i])
                    .totalSupply();
            }
        }

        StakingReward memory stakingReward = blockRewards[_roundId];
        uint256 blockNFTStaked = usersTotalNFTStaked[stakingReward.blockNumber][
            msg.sender
        ];

        require(blockNFTStaked > 0, "No NFT staked");
        claimableAmount = (stakingReward.amount * blockNFTStaked) / totalNFTs;
    }

    function claimRonix(uint256 _roundId) external {
        require(!rewardClaimed[_roundId][msg.sender], "Already claimed");

        uint256 amountRonix = ronixEarned(_roundId);
        require(amountRonix > 0, "No rewards to claim");

        rewardClaimed[_roundId][msg.sender] = true;
        IERC20(ronixAddress).transfer(msg.sender, amountRonix);
    }

    function _setApprovedNftContract(
        address[] calldata _approvedNFTContracts
    ) internal {
        approvedNFTContracts = _approvedNFTContracts;
    }

    function withdrawToken(
        address _tokenAddress,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    function getUserTotalNFTStaked(address _walletAddress) external view returns (uint256) {
        return usersTotalNFTStaked[block.number][_walletAddress];
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
