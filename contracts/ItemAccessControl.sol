// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

//**************************** NEEDS TO BE MADE UPGRADABLE **************************************
//IDEALLY ONLY UPGRADABLE BY CEO FOR NOW
/*Would aslo be cool for users to be able to vote to remove a CEO/Exec
Whether that's game players (or token holders?) or only executives or whatever, good to add an element of democracy to it
That's why Polkadot is the place to be :))
*/
contract ItemAccessControl is Ownable{
    //event ContractUpgrade(address newContract);
    //that's potentially very interesting but that's down the line :))

    address public ceoAddress;
    //let these addresses correspoond to official roles, eg index [0] = MinecraftCEO, [1] = MinecraftCTO etc.
    //could also be an option to declare an array of fixed size, good for numerous reasons:
    //1. It limits potential iterations through the array saving on gas
    //2. It reduces the likelihood of a hostile attack if there is only ever a certain number of addresses with exec privileges
    //3. It's also obviously requires less memory
    //4. Every address could have a specific purpose and accountability/responsibility
    //Arguments against that are as follows:
    //1. if big orgs want to allow lots of people exec privilege to reduce the burden on one then they can't be limited by array length
    address[5] public MinecraftExecutiveAddresses;//set it initally as CEO address?
    //address public cfoAddress;
    //address public cooAddress;

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
        // add the following if address array is dynamic: MinecraftExecutiveAddresses.push(_newMinecraftExecutive);
        //use the below while the array is fixed size (tested with fixed size = 5):
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

        /*   use the below if the exec addresses array is dynamic: 
        while((i<MinecraftExecutiveAddresses.length) && (!successfullyRemovedAddress)){
            if(MinecraftExecutiveAddresses[i] == _minecraftExecToBeRemoved){
                delete MinecraftExecutiveAddresses[i];
                successfullyRemovedAddress = true;
            }
            if((successfullyRemovedAddress) && (i+1<MinecraftExecutiveAddresses.length)){
                MinecraftExecutiveAddresses[i] = MinecraftExecutiveAddresses[i+1];
            }
            i++;
        }
        MinecraftExecutiveAddresses.pop();
        */
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

    /*/// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }*/

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

    /*/// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }*/

    /*** Pausable functionality adapted from OpenZeppelin ***/

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