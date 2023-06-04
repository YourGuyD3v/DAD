// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TwoPartyAgreement.sol";

error DadsCrowAccount__InvalidAmountOrPas();
error DadsCrowAccount__FundCantRelease();

contract DadsCrowAccount is TwoPartyAgreement, ReentrancyGuard {

    /* State Variable */
    // Local Variables
    uint256 private s_released;
    address private s_beneficiary;
    uint256 private s_start;
    uint256 private s_duration;
    uint256 private s_amount;
    string private receipt;
    TwoPartyAgreement private twoPartyAgreement;

        constructor(address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit,
        uint256 updateInterval) TwoPartyAgreement( 
            vrfCoordinatorV2, 
            gasLane, 
            subscriptionId, 
            callbackGasLimit, 
            updateInterval 
            ) {}

     /////////////////
    /// Functions ///
   /////////////////

    function enterFund(uint256 _amount, string memory pas) public payable onlyBuyer(s_agreementId) returns (string memory) {
        string memory uniqueId = twoPartyAgreement.setUniqueIdForRole(msg.sender, s_agreementId, pas);
          bytes memory pasBytes = abi.encodePacked(pas);
         bytes memory uniqueIdBytes = abi.encodePacked(uniqueId);
        if (keccak256(pasBytes) != keccak256(uniqueIdBytes) && _amount <= 0 ) {
            revert DadsCrowAccount__InvalidAmountOrPas();
        }
        s_amount = _amount;
    }

    function receiveFund() internal  {
        if (twoPartyAgreement.getHero(s_agreementId).s_hero && s_agreementId && uniqueId) {}
    }
 
    function moneyReturend() internal {}

    // View & Pure Functions
    function beneficiary() public view  returns (address) {
        return s_beneficiary;
    }
}