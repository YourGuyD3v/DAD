// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TwoPartyAgreement.sol";

error DadsCrowAccount__InvalidAmountOrPasOrAgreementId();

contract DadsCrowAccount is TwoPartyAgreement, ReentrancyGuard {

    /* State Variable */
    // Local Variables
    TwoPartyAgreement private twoPartyAgreement;
    bool private s_released;
    address private s_beneficiary;
    uint256 private s_amount;
    string internal _uniqueId;
    uint256 internal _agreementId;
    string private receipt;

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit,
        uint256 updateInterval
    ) TwoPartyAgreement( 
        vrfCoordinatorV2, 
        gasLane, 
        subscriptionId, 
        callbackGasLimit, 
        updateInterval 
    ) {}

    /////////////////
    /// Functions ///
    /////////////////

     function enterFund(uint256 _amount, string memory pas, uint256 agreementId) public payable onlyBuyer(s_agreementId) {
        string memory uniqueId = twoPartyAgreement.setUniqueIdForRole(i_agreements[s_agreementId].seller, s_agreementId, pas);
        bytes memory pasBytes = abi.encodePacked(pas);
        bytes memory uniqueIdBytes = abi.encodePacked(uniqueId);
        if (keccak256(pasBytes) != keccak256(uniqueIdBytes) && _amount <= 0 && s_agreementId != agreementId) {
            revert DadsCrowAccount__InvalidAmountOrPasOrAgreementId();
        }
        s_amount = _amount;
        _uniqueId = uniqueId;
        _agreementId = agreementId;
    }

    function fundRelease() internal nonReentrant {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Created &&
            i_agreements[s_agreementId].fundsReleased == false &&
            s_agreementId == _agreementId &&
            bytes(_uniqueId).length != 0 &&
            i_agreements[s_agreementId].seller == twoPartyAgreement.getHero(s_agreementId)
        ) {
            s_beneficiary = i_agreements[s_agreementId].seller;
            (bool success, ) = payable(s_beneficiary).call{value: s_amount}(""); // Transfer the funds to the seller
            if (success) {
            s_released = true;
            i_agreements[s_agreementId].fundsReleased = true;
            }
        }
    }

    function moneyReturned() internal {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Cancelled &&
            i_agreements[s_agreementId].fundsReleased == false &&
            s_agreementId == _agreementId &&
            bytes(_uniqueId).length != 0 &&
            i_agreements[s_agreementId].seller == twoPartyAgreement.getHero(s_agreementId)
        ) {
            address buyer = i_agreements[s_agreementId].buyer;
            (bool success, ) = payable(buyer).call{value: s_amount}("");// Return the funds to the buyer
            if (success) {
            s_released = false;
            i_agreements[s_agreementId].fundsReleased = false;
            }
        }
    }

    // View & Pure Functions
    function beneficiary(uint256 agreementId) public view returns (address) {
        require(s_agreementId == agreementId, "");
        return s_beneficiary;
    }
}
