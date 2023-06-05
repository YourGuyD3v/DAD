// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Errors 
error TwoPartyAgreement__NotTheBuyer();
error TwoPartyAgreement__NotTheSeller();
error TwoPartyAgreement__AgreementIsNotCreatedYet();
error TwoPartyAgreement__InvalidDeliveryDate();
error TwoPartyAgreement__InvalidAgreementIdOrHeroAddress();
error TwoPartyAgreement__UpkeepNotNeeded();
error TwoPartyAgreement_AgreementMustBeCompleted();
error TwoPartyAgreement__YouCantCancelTheAgreement();

contract TwoPartyAgreement is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Enum, it tells the current status
    enum AgreementStatus {
        Created,
        Completed,
        Cancelled
    } // 

    // Struct to store Local Variables
    struct Agreement {
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
    uint16 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Local Variables
    uint256 internal s_agreementId;
    uint256 public agreementCounter = 0;
    uint256[] private requestIds;
    uint256 private s_lastRequestId;
    address private s_hero;

    // Mapping
    mapping(uint256 => Agreement) internal i_agreements;

    // Events
    event AgreementCreated(
        uint256 agreementId,
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
    modifier onlyBuyer(uint256 _agreementId) {
        if (msg.sender != i_agreements[s_agreementId].buyer) {
            revert TwoPartyAgreement__NotTheBuyer();
        }
        _;
    }

    modifier onlySeller(uint256 _agreementId) {
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
        uint16 callbackGasLimit
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
        string memory _terms,
        address _seller,
        uint256 _price,
        uint256 _deliveryDate
    ) public {
        if (_deliveryDate < block.timestamp) {
            revert TwoPartyAgreement__InvalidDeliveryDate();
        }
        i_agreements[s_agreementId] = Agreement(
            _terms,
            msg.sender,
            _seller,
            _price,
            _deliveryDate,
            AgreementStatus.Created,
            false
        );
        emit AgreementCreated(s_agreementId, _terms, msg.sender, _seller, _price, _deliveryDate);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the agreement created should be true for this to return true.
     */
      function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {   
        bool isAgreement = i_agreements[s_agreementId].status == AgreementStatus.Created;
        upkeepNeeded = (isAgreement);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random AgreementId.
     */
       function performUpkeep(bytes calldata /* performData */) external override {
         (bool upkeepNeeded, ) = checkUpkeep("");
         if (!upkeepNeeded) {
            revert TwoPartyAgreement__UpkeepNotNeeded();
         }
        agreementCounter = agreementCounter + 1;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyHash
            i_subscriptionId,
            i_callbackGasLimit,
            REQUEST_CONFIRMATIONS,
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
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
       uint256 agreementId = (randomWords[0] % s_lastRequestId) + 1; // Generate a random agreement ID within the range of 0 to 10^18
        s_agreementId = agreementId;
    }

    function setUniqueIdForRole(address hero, uint256 _agreementId, string memory uniqueId) external inProgress(_agreementId) returns (string memory) {
        if (s_agreementId != _agreementId || i_agreements[_agreementId].seller != hero) {
            revert TwoPartyAgreement__InvalidAgreementIdOrHeroAddress();
        }
        s_hero = hero;
        return uniqueId;
    }

    function confirmDelivery(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        i_agreements[_agreementId].status = AgreementStatus.Completed;
        emit AgreementCompleted(_agreementId);
    }

    function cancelAgreement(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) {
        if (i_agreements[_agreementId].status == AgreementStatus.Completed) {
            revert TwoPartyAgreement__YouCantCancelTheAgreement();
        }
        i_agreements[_agreementId].status = AgreementStatus.Cancelled;
        delete i_agreements[_agreementId];
        emit AgreementCancelledAndDelete(_agreementId);
    }

    // function releaseFunds(uint256 _agreementId) external onlySeller(_agreementId) {     
    //     if (i_agreements[_agreementId].status != AgreementStatus.Completed) {
    //         revert TwoPartyAgreement_AgreementMustBeCompleted();
    //     }
    //     require(i_agreements[_agreementId].fundsReleased == false, "Funds already released");
    //     i_agreements[_agreementId].fundsReleased = true;
    // }

    // View / Pure Functions

    function getSellerById(uint256 i_agreementSellerId) public view returns (address) {
        return i_agreements[i_agreementSellerId].seller;
    }

    function getBuyerById(uint256 i_agreementBuyerId) public view returns (address) {
        return i_agreements[i_agreementBuyerId].buyer;
    }

    function getAgreementId() external view returns (uint256) {
        return s_agreementId;
    }

    function getTerms(uint256 agreementId) public view  returns (string memory) {
        return i_agreements[agreementId].terms;
    }

    function getHero(uint256 agreementId) public view returns (address) {
        require(s_agreementId == agreementId, "valid");
        return s_hero;
    }

    function getAgreementStatus(uint256 _agreementId) external view returns (AgreementStatus) {
    return i_agreements[_agreementId].status;

    }

  function getCallbackGasLimit() external view returns (uint16) {
    return i_callbackGasLimit;
  }

  function getPrice(uint256 agreementId) public view  returns (uint256) {
    return i_agreements[agreementId].price;
  }

}
