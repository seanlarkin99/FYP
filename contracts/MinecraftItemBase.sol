// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ItemAccessControl.sol";
import "./ItemCoreInterface.sol";

contract MinecraftItemBase is ItemAccessControl {
    struct Sword{

        /*
        LIST OF BEDROCK EDITION IDs
        wooden_sword 308
        stone_sword 312	
        iron_sword 307
        diamond_sword 316
        golden_sword 322	
        netherite_sword	604	
         */

        uint256 swordType;// identified by Bedrock Edition Numeric ID
        uint256 maxDurability;
        uint256 currentDurability;

        //take enchantments in as a fixed-size uint256 array where index 0 
        //corresponds to hasMending,
        //index 1 corresponds to has CurseOfVanishing, etc.
        //enchantments ordered by Max Level on 
        //https://minecraft.fandom.com/wiki/Sword
        uint256 hasMending;
        uint256 hasCurseOfVanishing;
        uint256 hasFireAspect;
        uint256 hasKnockback;
        uint256 hasLooting;
        uint256 hasUnbreaking;
        //uint256 hasSweepingEdge;//JE only
        uint256 hasSharpness;
        uint256 hasSmite;
        uint256 hasBaneOfArthopods;

        //bool isRepairable;// is this needed --> yes, will it be be implemented by Fri 25th? maybe not...
        //bool isEnchanted;// not 100% sure this is necessary but we'll see
        //string name;
    }

    /*** CONSTANTS ***/
    // this is stored here to prevent players tampering with the durability.
    mapping(uint256 => uint256) swordTypeToMaxDurability;
    mapping(uint256 => bool) public swordInGameStatus;
    mapping(uint256 => uint256) public swordIdToGlobalId;
    mapping(uint256 => uint256) public globalIdToSwordId;
    uint256 swordArray = 0;// index of sword array amongst other arrays

    /*** GLOBAL VARIABLES ***/
    address public itemCoreAddress;

    /*** ItemArrays ***/
    Sword[] public swords;

    constructor(){
        swordTypeToMaxDurability[308] = 60;
        swordTypeToMaxDurability[312] = 132;
        swordTypeToMaxDurability[307] = 251;
        swordTypeToMaxDurability[316] = 1562;
        swordTypeToMaxDurability[322] = 33;
        swordTypeToMaxDurability[604] = 2032;
        itemCoreAddress = initItemCoreAddress();
    }

    function mintSword(
        uint256 _swordType,
        uint256 _currentDurability,
        uint256[9] memory _enchantmentsList/*,
        bytes memory _name*/
    ) public returns (uint256){
        //ensure the swordType provided corresponds to an accepted sword
        require(
            (isValidSwordId(_swordType)), 
            "The item id number provided is not equal to an accepted sword"
        );

        //ensure current durability is between 0 and the swordType's max durability
        require(
            (_currentDurability>=0) && (_currentDurability<=swordTypeToMaxDurability[_swordType]),
            "The sword provided does not have acceptable durability"
        );

        require(validateSwordEnchantments(_enchantmentsList), 
            "The enchantments on this sword are not valid in the vanilla version of minecraft"
        );

        //add conditions to enchantments to ensure swords never have enchantments that don't exist Eg Sharpness X
        Sword memory _sword = Sword({
            swordType: _swordType,
            maxDurability: swordTypeToMaxDurability[_swordType],
            currentDurability: _currentDurability,
            hasMending: _enchantmentsList[0],
            hasCurseOfVanishing: _enchantmentsList[1],
            hasFireAspect: _enchantmentsList[2],
            hasKnockback: _enchantmentsList[3],
            hasLooting: _enchantmentsList[4],
            hasUnbreaking: _enchantmentsList[5],
            //hasSweepingEdge;//JE only
            hasSharpness: _enchantmentsList[6],
            hasSmite: _enchantmentsList[7],
            hasBaneOfArthopods: _enchantmentsList[8]
            //name: string(_name)
        });

        swords.push(_sword);
        uint256 newSwordId = swords.length - 1;
        swordInGameStatus[newSwordId] = true;

        //mint this as an item
        swordIdToGlobalId[newSwordId] = ItemCoreInterface(itemCoreAddress).mint(
            address(this),
            msg.sender,
            swordArray,
            newSwordId,
            1,
            swordInGameStatus[newSwordId]
        );
        globalIdToSwordId[swordIdToGlobalId[newSwordId]] = newSwordId;

        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        //require(newKittenId == uint256(uint32(newKittenId)));

        return newSwordId;
    }

    function exportSword(
            uint256 _tokenId, 
            /*uint256 _amount,*/ // don't need this for sword specific exports
            uint256 _swordType,
            uint256 _currentDurability,
            uint256[9] memory _enchantmentsList
        ) public {
        //verify ownership of that tokenId
        require(
            ItemCoreInterface(itemCoreAddress).balanceOf(msg.sender, _tokenId) > 0, 
            "The account trying to export does not own this token"
        );

        //don't need this for sword specific exports
        /*
        require(
            ItemCoreInterface(itemCoreAddress).balanceOf(msg.sender, _tokenId) >= _amount, 
            "The account trying to export does not own the amount of these tokens that it wishes to export"
        );*/

        //update its stats
        (address thisAddress, uint256 itemArray, uint256 itemArrayIndex) =
        ItemCoreInterface(itemCoreAddress).getItemInformation(_tokenId);

        require(thisAddress == address(this), "Item does not correspond to this game-contract");
        require(itemArray == swordArray, "The item's local array is not of type sword");
        require(swordInGameStatus[itemArrayIndex], "This sword is not currently in game and thus can't be exported");
        require(
            (isValidSwordId(_swordType)), 
            "The item id number provided is not equal to an accepted sword"
        );

        //ensure current durability is between 0 and the swordType's max durability
        require(
            (_currentDurability>=0) && (_currentDurability<=swordTypeToMaxDurability[_swordType]),
            "The sword provided does not have acceptable durability"
        );

        require(validateSwordEnchantments(_enchantmentsList), 
            "The enchantments on this sword are not valid in the vanilla version of minecraft"
        );

        //update the stats of that specific sword item
        swords[itemArrayIndex] = Sword({
            swordType: _swordType,
            maxDurability: swordTypeToMaxDurability[_swordType],
            currentDurability: _currentDurability,
            hasMending: _enchantmentsList[0],
            hasCurseOfVanishing: _enchantmentsList[1],
            hasFireAspect: _enchantmentsList[2],
            hasKnockback: _enchantmentsList[3],
            hasLooting: _enchantmentsList[4],
            hasUnbreaking: _enchantmentsList[5],
            //hasSweepingEdge;//JE only
            hasSharpness: _enchantmentsList[6],
            hasSmite: _enchantmentsList[7],
            hasBaneOfArthopods: _enchantmentsList[8]
            //name: string(_name)
        });

        //set state to not active in game
        swordInGameStatus[itemArrayIndex] = false;
        ItemCoreInterface(itemCoreAddress).updateItemInGameStatus(
            address(this), 
            msg.sender, 
            swordIdToGlobalId[itemArrayIndex], 
            swordInGameStatus[itemArrayIndex]
        );
    }

    function importSword(uint256 _tokenId) public {
        //verify ownership of item
        require(
            ItemCoreInterface(itemCoreAddress).balanceOf(msg.sender, _tokenId) > 0, 
            "The account trying to import does not own this token"
        );
        (address thisAddress, uint256 itemArray, uint256 itemArrayIndex) =
        ItemCoreInterface(itemCoreAddress).getItemInformation(_tokenId);
        require(thisAddress == address(this), "Item does not correspond to this game-contract");
        require(itemArray == swordArray, "The item's local array is not of type sword");
        require(!swordInGameStatus[itemArrayIndex], "This sword is currently in-game and thus can't be imported");
        //change in-game status to "in-game"
        swordInGameStatus[itemArrayIndex] = true;
        ItemCoreInterface(itemCoreAddress).updateItemInGameStatus(
            address(this), 
            msg.sender, 
            swordIdToGlobalId[itemArrayIndex], 
            swordInGameStatus[itemArrayIndex]
        );
    }

    function validateSwordEnchantments(
        uint256[9] memory _enchantmentsList
    ) private pure returns (bool){
        //each comparison number is the maximum level of its corresponding enchantment
        bool validEnchantments = true;
        if((_enchantmentsList[0]<0) || (_enchantmentsList[0]>1)){validEnchantments = false;}
        if((_enchantmentsList[1]<0) || (_enchantmentsList[1]>1)){validEnchantments = false;}
        if((_enchantmentsList[2]<0) || (_enchantmentsList[2]>2)){validEnchantments = false;}
        if((_enchantmentsList[3]<0) || (_enchantmentsList[3]>2)){validEnchantments = false;}
        if((_enchantmentsList[4]<0) || (_enchantmentsList[4]>3)){validEnchantments = false;}
        if((_enchantmentsList[5]<0) || (_enchantmentsList[5]>3)){validEnchantments = false;}
        //ensure no sword can have smite, sharpness & bane of arthropods, as this is not in vanilla game
        if(
            (_enchantmentsList[6]<0) || 
            (_enchantmentsList[6]>5) ||
            ((_enchantmentsList[6]>0) && ((_enchantmentsList[7]!=0) || (_enchantmentsList[8]!=0)))
        ){validEnchantments = false;}
        if(
            (_enchantmentsList[7]<0) || 
            (_enchantmentsList[7]>5) || 
            ((_enchantmentsList[7]>0) && ((_enchantmentsList[6]!=0) || (_enchantmentsList[8]!=0)))
        ){validEnchantments = false;}
        if(
            (_enchantmentsList[8]<0) || 
            (_enchantmentsList[8]>5) || 
            ((_enchantmentsList[8]>0) && ((_enchantmentsList[6]!=0) || (_enchantmentsList[7]!=0)))
        ){validEnchantments = false;}

        return validEnchantments;
    }

    function isValidSwordId(uint256 _swordType) private pure returns (bool){
        bool isValid = false;
        if(
            (_swordType == 308) || 
            (_swordType == 312) ||
            (_swordType == 307) ||
            (_swordType == 316) ||
            (_swordType == 322) ||
            (_swordType == 604)
        ){
            isValid = true;
        }
        return isValid;
    }

    function initItemCoreAddress() private pure returns(address) {
        return 0x73F2840f7EBf97f4C06865da7fbbBc83De2cE7D4;
    }
    
    function updateItemCoreAddress(address _newItemCoreAddress) public onlyMinecraftExecutive{
        itemCoreAddress = _newItemCoreAddress;
    }
}