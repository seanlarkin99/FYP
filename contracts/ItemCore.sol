// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ItemAccessControl.sol";

contract ItemCore is ERC1155, ItemAccessControl{

    struct itemIdentity{
        address gameContractAddress;
        uint256 gameItemArray;
        uint256 gameItemArrayIndex;
        bool activeInGame;
    }

    itemIdentity[] public items;

    /**** CONSTANTS ****/



    constructor() ERC1155("") {
        ceoAddress = msg.sender;
    }

    function mint(
        address _gameContract, 
        address _userAddress, 
        uint256 _gameItemArray, 
        uint256 _gameItemArrayIndex,
        uint256 _amount,
        bool _activeInGame
    ) public returns(uint256){
        itemIdentity memory newItemIdentity = itemIdentity({
            gameContractAddress: _gameContract,
            gameItemArray: _gameItemArray,
            gameItemArrayIndex: _gameItemArrayIndex,
            activeInGame: _activeInGame
        });

        items.push(newItemIdentity);
        uint256 tokenId = items.length -1;
        _mint(_userAddress, tokenId, _amount, "");
        return tokenId;
    }

    function transferItemOwnershipFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        require(!items[_tokenId].activeInGame, 
        "This item is active in game, please export the item before transferring it");
        require(_from == msg.sender, 
        "You do not own the account from which you are trying to transfer this token, you cannot transfer it");
        require((balanceOf(_from, _tokenId)>0), 
        "You do not own a sufficient amount of this token to transfer it.");
        _safeTransferFrom(_from, _to, _tokenId, _amount, "0x00");
    }

    function getItemInformation(uint256 _tokenId) public view returns(address, uint256, uint256){
        return (
            items[_tokenId].gameContractAddress, 
            items[_tokenId].gameItemArray,
            items[_tokenId].gameItemArrayIndex
            //add the active in game bool here
        );    
    }

    function updateItemInGameStatus(
        address _gameContract, 
        address _userAddress, 
        uint256 _tokenId,
        bool _newStatus
        ) public {
        require(balanceOf(_userAddress, _tokenId)>0);
        require(_gameContract == items[_tokenId].gameContractAddress);
        items[_tokenId].activeInGame = _newStatus;
    }

}