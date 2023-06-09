// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TwoPartyAgreement.sol";

error DadsAccount__InvalidAmount();

/**@title DAds Account
 * @author Shurjeel khan
 * @notice This contract is for storing money
 */
contract DadsAccount is TwoPartyAgreement, ReentrancyGuard {

    /* State Variable */
    // Local Variables
    TwoPartyAgreement private twoPartyAgreement;
    bool public s_released;
    string internal _uniqueId;
    uint256 internal _agreementId;
    string private receipt;

        // Modifier
     modifier onlySeller(uint256 agreementId) override  {
    if (msg.sender != twoPartyAgreement.getSellerById(agreementId)) {
        revert TwoPartyAgreement__NotTheSeller();
    }
    _;
     }


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

    /**
     * @dev buyer can fund
     */
    function enterFunds(uint256 agreementId) public payable {
     uint256 setPrice = twoPartyAgreement.getPrice(agreementId);
    if (msg.value != setPrice) {
        revert DadsAccount__InvalidAmount();
    }
    _agreementId = agreementId;

    }

     /**
     * @dev seller can withdraw
     */
    function fundWithdraw(uint256 agreementId) external nonReentrant onlySeller(agreementId) {
        if (
            twoPartyAgreement.getAgreementStatus(agreementId) == TwoPartyAgreement.AgreementStatus.Completed ||
            twoPartyAgreement.getFundReleaseUpdate(agreementId) == false ||
            msg.sender == twoPartyAgreement.getSellerById(agreementId) 
            )
         {
            address seller = twoPartyAgreement.getSellerById(agreementId);
            uint256 setPrice = twoPartyAgreement.getPrice(agreementId);  
            (bool success, ) = payable(seller).call{value: setPrice}(""); // Transfer the funds to the seller
            if (success) {
            s_released = true;
            i_agreements[agreementId].fundsReleased = true;
            }
        }
    }
    
    /**
     * @dev seller can get return
     */
    function fundReturned(uint256 agreementId) external nonReentrant {
        if (
            twoPartyAgreement.getAgreementStatus(agreementId) == TwoPartyAgreement.AgreementStatus.Cancelled ||
            msg.sender == twoPartyAgreement.getBuyerById(agreementId) 
        ) {
            address buyer = twoPartyAgreement.getBuyerById(agreementId);
            uint256 setPrice = twoPartyAgreement.getPrice(agreementId);
            (bool success, ) = payable(buyer).call{value: setPrice}("");// Return the funds to the buyer
            if (success) {
            s_released = false;
            }
        }
    }

}
