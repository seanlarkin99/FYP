// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ItemCoreInterface{
    
    function mint(
        address _gameContract, 
        address _userAddress, 
        uint256 _gameItemArray, 
        uint256 _gameItemArrayIndex,
        uint256 _amount,
        bool _activeInGame
    ) external returns (uint256);

    function balanceOf(
        address _address, uint256 _tokenId
    ) external view returns (uint256);

    function getItemInformation(
        uint256 _tokenId
    ) external view returns (address, uint256, uint256);

    function updateItemInGameStatus(
        address _gameContract, 
        address _userAddress, 
        uint256 _tokenId,
        bool _newStatus
    ) external;
}