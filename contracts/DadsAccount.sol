// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TwoPartyAgreement.sol";

error DadsAccount__InvalidAmountOrPasOrAgreementId();

contract DadsAccount is TwoPartyAgreement, ReentrancyGuard {

    /* State Variable */
    // Local Variables
    TwoPartyAgreement private twoPartyAgreement;
    bool private s_released;
    string internal _uniqueId;
    uint256 internal _agreementId;
    string private receipt;

    mapping(uint256 => address) private s_beneficiaries;
    mapping(uint256 => uint256) private s_amounts;

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit
    ) TwoPartyAgreement( 
        vrfCoordinatorV2, 
        gasLane, 
        subscriptionId, 
        callbackGasLimit
    ) {}

    /////////////////
    /// Functions ///
    /////////////////

 function enterFund(uint256 _amount, string memory pas, uint256 agreementId) public payable {
    string memory uniqueId = twoPartyAgreement.setUniqueIdForRole(i_agreements[s_agreementId].seller, s_agreementId, pas);
    bytes memory pasBytes = abi.encodePacked(pas);
    bytes memory uniqueIdBytes = abi.encodePacked(uniqueId);
    if (keccak256(pasBytes) != keccak256(uniqueIdBytes) || _amount != i_agreements[s_agreementId].price || s_agreementId != agreementId) {
        revert DadsAccount__InvalidAmountOrPasOrAgreementId();
    }
    s_amounts[agreementId] = _amount;
    _uniqueId = uniqueId;
    _agreementId = agreementId;
}


    function fundRelease(uint256 agreementId) internal onlySeller(_agreementId) nonReentrant {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Created ||
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Completed ||
            i_agreements[s_agreementId].fundsReleased == false ||
            s_agreementId == agreementId ||
            bytes(_uniqueId).length != 0 ||
            i_agreements[s_agreementId].seller == twoPartyAgreement.getHero(_agreementId
            )
        ) {
            s_beneficiaries[_agreementId] = i_agreements[s_agreementId].seller;
            (bool success, ) = payable(s_beneficiaries[_agreementId]).call{value: s_amounts[_agreementId]}(""); // Transfer the funds to the seller
            if (success) {
            s_released = true;
            i_agreements[s_agreementId].fundsReleased = true;
            }
        }
    }

    function moneyReturned() internal nonReentrant {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Cancelled &&
            i_agreements[s_agreementId].fundsReleased == false &&
            s_agreementId == _agreementId &&
            bytes(_uniqueId).length != 0 &&
            i_agreements[s_agreementId].seller == twoPartyAgreement.getHero(s_agreementId)
        ) {
            address buyer = i_agreements[s_agreementId].buyer;
            (bool success, ) = payable(buyer).call{value: s_amounts[_agreementId]}("");// Return the funds to the buyer
            if (success) {
            s_released = false;
            i_agreements[s_agreementId].fundsReleased = false;
            }
        }
    }

    // View & Pure Functions
    function getBeneficiary(uint256 agreementId) public view returns (address) {
        return s_beneficiaries[agreementId];
    }

    function getAmount(uint256 agreementId) public view returns (uint256) {
        return s_amounts[agreementId];
    }
}
