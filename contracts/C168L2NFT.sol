// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract C168L2NFT is ERC721, ERC721Burnable, Ownable {
    constructor(address initialOwner)
        ERC721("C168L2Token", "C168L2NFT")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }
}
