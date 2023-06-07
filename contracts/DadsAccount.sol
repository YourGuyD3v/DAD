// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TwoPartyAgreement.sol";

error DadsAccount__InvalidAmount();

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

        // Modifier
    modifier onlySeller(uint256 agreementId) override {_;}

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit,
        address twoPartyAgreementAddress
    ) TwoPartyAgreement( 
        vrfCoordinatorV2, 
        gasLane, 
        subscriptionId, 
        callbackGasLimit
    ) {
        twoPartyAgreement = TwoPartyAgreement(twoPartyAgreementAddress);
    }

    /////////////////
    /// Functions ///
    /////////////////

function enterFunds(uint256 _amount, uint256 agreementId) public payable {
    uint256 setPrice = twoPartyAgreement.getPrice(agreementId);
    if (_amount != setPrice) {
        revert DadsAccount__InvalidAmount();
    }
    s_amounts[agreementId] = _amount;
    _agreementId = agreementId;
}



    function fundWithdraw(uint256 agreementId) external nonReentrant onlySeller(_agreementId) {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Created ||
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Completed ||
            i_agreements[s_agreementId].fundsReleased == false ||
            s_agreementId == agreementId
            )
         {
            s_beneficiaries[_agreementId] = i_agreements[s_agreementId].seller;
            (bool success, ) = payable(s_beneficiaries[_agreementId]).call{value: s_amounts[_agreementId]}(""); // Transfer the funds to the seller
            if (success) {
            s_released = true;
            i_agreements[s_agreementId].fundsReleased = true;
            }
        }
    }

    function moneyReturned() external nonReentrant {
        if (
            i_agreements[s_agreementId].status == TwoPartyAgreement.AgreementStatus.Cancelled &&
            i_agreements[s_agreementId].fundsReleased == false &&
            s_agreementId == _agreementId 
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
