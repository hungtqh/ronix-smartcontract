// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking is UUPSUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    struct RebaseData {
        uint128 blockNumber;
        uint128 amount;
    }

    // Storage
    mapping(address => mapping(address => mapping(uint => bool)))
        public userNFTStaked; // contractAddr => userAddr => tokenId => isStaked
    mapping(address => uint256[]) nftStaked; // contractAddress => tokenIds
    mapping(uint256 => mapping(address => uint256)) totalNFTStaked; // blockNumber => address => totalNFTStaked
    address[] approvedNFTContracts;
    address usdtAddress;
    bytes32 public constant COLLATERAL_ROLE = keccak256("COLLATERAL_ROLE");
    mapping(uint256 => RebaseData) blockRewards; // roundId => blockNumber => reward

    function initialize(
        address[] memory _approvedNFTContracts,
        address _usdtAddress,
        address _collateralContract
    ) external initializer {
        approvedNFTContracts = _approvedNFTContracts;
        usdtAddress = _usdtAddress;

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COLLATERAL_ROLE, _collateralContract);
    }

    // calculate reward using block.number
    // block.number => totalReward
    // block.number => totalStakedNFTByUser

    // TODO: snapshot total nft staked by user using block.number
    function stakeNFT(address _nftContract, uint256 _tokenId) external {
        IERC721Enumerable(_nftContract).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        userNFTStaked[_nftContract][msg.sender][_tokenId] = true;
        unchecked {
            uint blockNFTStaked = totalNFTStaked[block.number][msg.sender];

            totalNFTStaked[block.number][msg.sender] = blockNFTStaked == 0
                ? totalNFTStaked[block.number - 1][msg.sender] + 1
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
            uint blockNFTStaked = totalNFTStaked[block.number][msg.sender];

            totalNFTStaked[block.number][msg.sender] = blockNFTStaked == 0
                ? totalNFTStaked[block.number - 1][msg.sender] - 1
                : totalNFTStaked[block.number][msg.sender] - 1;
        }
    }

    function setBlockReward(
        uint256 _roundId,
        uint256 _blockNumber,
        uint256 _ronixAmount
    ) external onlyRole(COLLATERAL_ROLE) {
        blockRewards[_roundId] = RebaseData({
            amount: uint128(_ronixAmount),
            blockNumber: uint128(_blockNumber)
        });
    }

    // function claimableRonixAmount()
    //     external
    //     view
    //     returns (uint256 claimableAmount)
    // {
    //     uint256 totalNFTs = 0;
    //     for (uint i = 0; i < approvedNFTContracts.length; ++i) {
    //         unchecked {
    //             totalNFTs += IERC721Enumerable(approvedNFTContracts[i])
    //                 .totalSupply();
    //         }
    //     }

    //     uint256 blockReward = claimableAmount =
    //         (IERC20(usdtAddress).balanceOf(address(this)) *
    //             totalNFTStaked[msg.sender]) /
    //         totalNFTs;
    // }

    function _setApprovedNftContract(
        address[] memory _approvedNFTContracts
    ) internal {
        approvedNFTContracts = _approvedNFTContracts;
    }

    // TODO: withdraw ERC20 function

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
