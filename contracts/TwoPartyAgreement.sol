// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Errors 
error TwoPartyAgreement__NotTheBuyer();
error TwoPartyAgreement__NotTheSeller();
error TwoPartyAgreement__AgreementIsNotCreatedYet();
error TwoPartyAgreement__InvalidDeliveryDateOrGeneratedId();
error TwoPartyAgreement__InvalidAgreementIdOrHeroAddress();
error TwoPartyAgreement__UpkeepNotNeeded();
error TwoPartyAgreement_AgreementMustBeCompleted();
error TwoPartyAgreement__YouCantCancelTheAgreement();
error TwoPartyAgreement__youCantCancelTheAgreement();

/**@title Two party Agreement
 * @author Shurjeel khan
 * @notice This contract is for creating a agreement
 * @dev This implements the Chainlink VRF
 */
contract TwoPartyAgreement is VRFConsumerBaseV2 {
    // Enum, it tells the current status
    enum AgreementStatus {
        Created,
        Completed,
        Cancelled
    } // 

    // Struct to store Local Variables
    struct Agreement {
        string product;
        string terms;
        address buyer;
        address seller;
        uint256 price;
        uint256 deliveryDate;
        AgreementStatus status;
        bool fundsReleased;
    }

    /* State Variable */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Local Variables
    uint256 internal s_agreementId;
    uint256 public agreementCounter = 0;
    uint256[] private requestIds;
    uint256 private s_lastRequestId;
    uint256 public generatedId;

    // Mapping
    mapping(uint256 => Agreement) internal i_agreements;

    // Events
    event AgreementCreated(
        string _product,
        uint256 indexed agreementId,
        string terms,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 deliveryDate
    );
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementCancelledAndDelete(uint256 indexed agreementId);
    event RequestAgreementId(uint256 indexed requestId);

    // Modifier
    modifier onlyBuyer(uint256 _agreementId) virtual {
        if (msg.sender != i_agreements[_agreementId].buyer) {
            revert TwoPartyAgreement__NotTheBuyer();
        }
        _;
    }

    modifier onlySeller(uint256 _agreementId) virtual {
        if (msg.sender != i_agreements[s_agreementId].seller) {
            revert TwoPartyAgreement__NotTheSeller();
        }
        _;
    }

    modifier inProgress(uint256 _agreementId) {
        if (i_agreements[s_agreementId].status != AgreementStatus.Created) {
            revert TwoPartyAgreement__AgreementIsNotCreatedYet();
        }
        _;
    }

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /////////////////
    /// Functions ///
    /////////////////

    /**
     * @dev Creates a new agreement between a buyer and a seller.
     * @param _terms The terms of the agreement.
     * @param _seller The address of the seller.
     * @param _price The price of the agreement.
     * @param _deliveryDate The delivery date of the agreement.
     */

    function createAgreement(
        string memory _product,
        string memory _terms,
        address _seller,
        uint256 _price,
        uint256 _deliveryDate,
        uint256 agreementId
    ) public {
        if (_deliveryDate < block.timestamp || agreementId != generatedId  ) {
            revert TwoPartyAgreement__InvalidDeliveryDateOrGeneratedId();
        }
        i_agreements[agreementId] = Agreement(
            _product,
            _terms,
            msg.sender,
            _seller,
            _price,
            _deliveryDate,
            AgreementStatus.Created,
            false
        );
        s_agreementId = agreementId;
        emit AgreementCreated(_product, agreementId, _terms, msg.sender, _seller, _price, _deliveryDate);
    }

    /**
     * @dev requestAgreementId kicks off a Chainlink VRF call to get a random AgreementId.
     */
       function requestAgreementId() external {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        requestIds.push(requestId);
        s_lastRequestId = requestId;

        emit RequestAgreementId(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to give random Agreement ID.
     */
    function fulfillRandomWords(
        uint256 requestId ,
        uint256[] memory randomWords
    ) internal override {
   agreementCounter = agreementCounter + 1;
    uint256 indexOfAgreementId = (randomWords[0] % (10**7)); // Generate a random agreement ID within the range of 1 to agreementCounter
        if (requestId <= 2) {
        indexOfAgreementId = requestId;
            }
               generatedId = indexOfAgreementId;
    }

        /**
     * @dev buyer confirms the delivery so seller can withraw funds
     */
    function confirmDelivery(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        i_agreements[_agreementId].status = AgreementStatus.Completed;
        emit AgreementCompleted(_agreementId);
    }

        /**
     * @dev buyer can cancel the agreement
     */
    function cancelAgreementByBuyer(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) {
        if (i_agreements[_agreementId].status == AgreementStatus.Completed) {
            revert TwoPartyAgreement__YouCantCancelTheAgreement();
        }
        i_agreements[_agreementId].status = AgreementStatus.Cancelled;
            i_agreements[_agreementId].fundsReleased = true;
        delete i_agreements[_agreementId];
        emit AgreementCancelledAndDelete(_agreementId);
    }

    /**
     * @dev seller can cancel the agreement
     */
    function cancelAgreementBySeller(uint256 _agreementId) external onlySeller(_agreementId){
        if (i_agreements[_agreementId].status == AgreementStatus.Completed ) {
           revert TwoPartyAgreement__youCantCancelTheAgreement();
        }
        i_agreements[_agreementId].status = AgreementStatus.Cancelled;
            i_agreements[_agreementId].fundsReleased = true;
        delete i_agreements[_agreementId];
        emit AgreementCancelledAndDelete(_agreementId);
    }

    // View / Pure Functions

    function getSellerById(uint256 _agreementId) public view returns (address) {
        return i_agreements[_agreementId].seller;
    }

    function getBuyerById(uint256 _agreementId) public view returns (address) {
        return i_agreements[_agreementId].buyer;
    }

    function getAgreementId() external view returns (uint256) {
        return s_agreementId;
    }

    function getTerms(uint256 agreementId) public view  returns (string memory) {
        return i_agreements[agreementId].terms;
    }

    function getAgreementStatus(uint256 _agreementId) external view returns (AgreementStatus) {
    return i_agreements[_agreementId].status;
    }

  function getCallbackGasLimit() external view returns (uint32) {
    return i_callbackGasLimit;
  }

  function getPrice(uint256 agreementId) public view virtual returns (uint256) {
    return i_agreements[agreementId].price;
  }

  function getFundReleaseUpdate(uint256 agreementId) public view returns (bool) {
    return i_agreements[agreementId].fundsReleased;
  }

  function getProduct(uint256 agreementId) public view returns (string memory) {
    return i_agreements[agreementId].product;
  }

  function getDeliveryDate(uint256 agreementId) public view returns (uint256) {
    return i_agreements[agreementId].deliveryDate;
  }

}
