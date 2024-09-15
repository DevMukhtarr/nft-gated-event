// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EventNft is ERC721 {
    address public owner;
    uint256 public tokenId;
    error NotOwner();

    event NftMinted(address receiver, uint256 Id);
    function onlyOwner() private view {
        if( msg.sender != owner ){
            revert NotOwner();
        }
    }

    constructor() ERC721("CelebrateIt", "CIT") {
        owner = msg.sender;
        tokenId = 0;
    }


    function mint(address to) external {
        uint256 _newTokenId = tokenId++;
        onlyOwner();
        _mint(to, _newTokenId);
        emit NftMinted(to, _newTokenId);
    }
}