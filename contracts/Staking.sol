// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Staking is UUPSUpgradeable, OwnableUpgradeable {
    // Storage
    mapping(address => mapping(address => mapping(uint => bool))) public userNFTStaked; // nftContract => user => tokenId => isStaked
    mapping(address => uint256[]) nftStaked; // contractAddress => tokenIds 
    mapping(address => uint256) totalNFTStaked; // user => totalNFTStaked
    address[] approvedNFTContracts; 

    function initialize(address[] memory _approvedNFTContracts) external initializer {
        approvedNFTContracts = _approvedNFTContracts;

        __Ownable_init(msg.sender);
    }

    function stakeNFT(address _nftContract, uint256 _tokenId) external {
        IERC721Enumerable(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        
        userNFTStaked[_nftContract][msg.sender][_tokenId] = true;
        unchecked {
            totalNFTStaked[msg.sender]++;
        }       
    }

    function unstakeNFT(address _nftContract, uint256 _tokenId) external {
        require(userNFTStaked[_nftContract][msg.sender][_tokenId], "NFT was not staked");

        IERC721Enumerable(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
        unchecked {
            totalNFTStaked[msg.sender]--;
        }
    }

    function claimableRonixAmount() external view returns (uint256 claimableAmount) {
        uint256 totalNFTs = 0;
        for (uint i = 0; i < approvedNFTContracts.length; ++i) {
            unchecked {
                totalNFTs += IERC721Enumerable(approvedNFTContracts[i]).totalSupply();
            }
        }

        claimableAmount = totalNFTStaked[msg.sender] * 100 / totalNFTs;
    }

    function _setApprovedNftContract(address[] memory _approvedNFTContracts) internal {
        approvedNFTContracts = _approvedNFTContracts;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
