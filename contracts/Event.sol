// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AttendEvent {

address public owner;
IERC721 public nftAddress;

mapping (address => bool) internal attended;

event AttendedEvent(address attendee);

error NotOwner();
function onlyOwner () private view {
    if (msg.sender != owner){
        revert NotOwner();
    }
}
    constructor(address _nftAddress) {
        nftAddress = IERC721(_nftAddress);
        owner = msg.sender;
    }

    function enterEventOnce() external {
        require(msg.sender != address(0), "address 0 found");
        require(nftAddress.balanceOf(msg.sender) > 0, "you don't own this nft");
        require(attended[msg.sender] == false, "you have checked into this event already");

        attended[msg.sender] = true;
        emit AttendedEvent(msg.sender);
    }

    function changeNftAddress(IERC721 _newAddress) private{
        onlyOwner();
        nftAddress = _newAddress;
    }
}
