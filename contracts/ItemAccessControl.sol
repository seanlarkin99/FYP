// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemAccessControl is Ownable{


    address public ceoAddress;
    
    address[5] public MinecraftExecutiveAddresses;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    bool public MinecraftPaused = false;

    constructor(){
        ceoAddress = msg.sender;
        MinecraftExecutiveAddresses[0] = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMinecraftExecutive(){
        bool isMinecraftExecutive = false;
        uint i = 0;
        while((i<MinecraftExecutiveAddresses.length) && (!isMinecraftExecutive)){
            if(msg.sender == MinecraftExecutiveAddresses[i]){
                isMinecraftExecutive = true;
            }
            i++;
        }
        require(isMinecraftExecutive);
        _;
    }

    modifier onlyMinecraftCEO(){
        require(msg.sender == MinecraftExecutiveAddresses[0]);
        _;
    }

    function addNewMinecraftExecutive(
        address _newMinecraftExecutive
    ) external onlyMinecraftExecutive{
        require(_newMinecraftExecutive != address(0));
        require(!isAlreadyMinecraftExecutive(_newMinecraftExecutive), "This account is already a minecraft executive");
        
        uint i = 1;// i = 1 to start after CEO address which is at i=0
        bool executiveSet = false;
        while((i< MinecraftExecutiveAddresses.length) && (!executiveSet)){
            if(MinecraftExecutiveAddresses[i]==address(0)){
                MinecraftExecutiveAddresses[i] = _newMinecraftExecutive;
                executiveSet = true;
            }
            i++;
        }
        if((!executiveSet) && (i == MinecraftExecutiveAddresses.length)){
            revert("Maximum exectuives already set, please remove one before adding another");
        }
    }

    function removeMinecraftExecutive(
        address _minecraftExecToBeRemoved
    ) external onlyMinecraftExecutive{
        //ensure CEO is not getting removed
        require(_minecraftExecToBeRemoved != MinecraftExecutiveAddresses[0]);
        require(MinecraftExecutiveAddresses.length > 1);
        bool successfullyRemovedAddress = false;
        uint i =1;
        //use this code if the exectuive addresses array is fixed:
        while((i<MinecraftExecutiveAddresses.length) && (!successfullyRemovedAddress)){
            if(MinecraftExecutiveAddresses[i] == _minecraftExecToBeRemoved){
                MinecraftExecutiveAddresses[i] = address(0);
                successfullyRemovedAddress = true;
            }
            i++;
        }

    }

    function setMinecraftCEO(
        address _newMinecraftCEO
    ) external onlyMinecraftCEO{
        require(_newMinecraftCEO != address(0));
        if(isAlreadyMinecraftExecutive(_newMinecraftCEO)){
            bool swapped = false;
            uint i = 1;//again starting at one to not parse the current CEO
            while((i<MinecraftExecutiveAddresses.length) && (!swapped)){
                if(MinecraftExecutiveAddresses[i]==_newMinecraftCEO){
                    MinecraftExecutiveAddresses[i] = MinecraftExecutiveAddresses[0]; //Keeps CEO as an executive
                    swapped = true;
                }
                i++;
            }
        }
        MinecraftExecutiveAddresses[0] = _newMinecraftCEO;
    }


    modifier onlyCLevel() {
        require(
            //msg.sender == cooAddress ||
            msg.sender == ceoAddress /*||*/
            //msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }

    modifier whenMinecraftNotPaused() {
        require(!MinecraftPaused);
        _;
    }

    modifier whenMinecraftPaused {
        require(MinecraftPaused);
        _;
    }

    function pauseMinecraft() external onlyMinecraftExecutive whenMinecraftNotPaused {
        MinecraftPaused = true;
    }

    function unpauseMinecraft() public onlyMinecraftCEO whenMinecraftPaused {
        MinecraftPaused = false;
    }

    function isAlreadyMinecraftExecutive(address _newAddress) private view returns(bool){
        require(_newAddress!=address(0));
        bool isExectuive = false;
        for(uint i = 0; i<MinecraftExecutiveAddresses.length; i++){
            if(MinecraftExecutiveAddresses[i]==_newAddress){
                isExectuive = true;
            }
        }
        return isExectuive;
    }

}