// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Staking is UUPSUpgradeable, OwnableUpgradeable {
    // Storage
    address[] approvedNFTContracts; 
    mapping(address => mapping(address => mapping(uint => bool))) public userNFTStaked; // nftContract => user => tokenId => isStaked
    mapping(address => uint256[]) nftStaked; // contractAddress => tokenIds 

    function initialize(address[] memory _approvedNFTContracts) external initializer {
        approvedNFTContracts = _approvedNFTContracts;

        __Ownable_init(msg.sender);
    }

    function stakeNFT(address _nftContract, uint256 _tokenId) external {
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        
        userNFTStaked[_nftContract][msg.sender][_tokenId] = true;
    }

    function unstakeNFT(address _nftContract, uint256 _tokenId) external {
        require(userNFTStaked[_nftContract][msg.sender][_tokenId], "NFT was not staked");

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
    }

    function claimableRonixAmount() external view returns (uint256 claimableAmount) {

    }

    function _setApprovedNftContract(address[] memory _approvedNFTContracts) internal {
        approvedNFTContracts = _approvedNFTContracts;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
