// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Errors 
error TwoPartyAgreement__NotTheBuyer();
error TwoPartyAgreement__NotTheSeller();
error TwoPartyAgreement__MustBeInProgress();

contract TwoPartyAgreement is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Enum, it tells the current status
    enum AgreementStatus {
        Created,
        Completed,
        Cancelled
    }

    // Struct to store Local Variables
    struct Agreement {
        bytes32 terms;
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
    uint256 internal s_agreementId = type(uint256).max;
    uint256 public immutable interval;
    uint256 public lastBlockNumber;

    // Mapping
    mapping(uint256 => Agreement) internal i_agreements;

    // Events
    event AgreementCreated(
        uint256 agreementId,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 deliveryDate
    );
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementCancelled(uint256 indexed agreementId);
    event RequestAgreementId(uint256 indexed requestId);

    // Modifier
    modifier onlyBuyer(uint256 _agreementId) {
        if (msg.sender != i_agreements[_agreementId].buyer) {
            revert TwoPartyAgreement__NotTheBuyer();
        }
        _;
    }

    modifier onlySeller(uint256 _agreementId) {
        if (msg.sender != i_agreements[_agreementId].seller) {
            revert TwoPartyAgreement__NotTheSeller();
        }
        _;
    }

    modifier inProgress(uint256 _agreementId) {
        if (i_agreements[_agreementId].status == AgreementStatus.Created) {
            revert TwoPartyAgreement__MustBeInProgress();
        }
        _;
    }

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit,
        uint256 updateInterval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        interval = updateInterval;
        lastBlockNumber = block.number;
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
        bytes32 _terms,
        address _seller,
        uint256 _price,
        uint256 _deliveryDate
    ) external {
        i_agreements[s_agreementId] = Agreement(
            _terms,
            msg.sender,
            _seller,
            _price,
            _deliveryDate,
            AgreementStatus.Created,
            false
        );
        emit AgreementCreated(s_agreementId, msg.sender, _seller, _price, _deliveryDate);
    }

      function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.number - lastBlockNumber) > interval;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.number - lastBlockNumber) > interval) {
            lastBlockNumber = block.number;
        }
  
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // keyHash
            i_subscriptionId,
            i_callbackGasLimit,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS
        );

        emit RequestAgreementId(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal virtual override {
        uint256 indexedRequestId = randomWords[0] % 9999999999999999;
        uint256 agreementId = indexedRequestId;
        for (uint256 i = 0; i < agreementId; i++) {
            indexedRequestId = randomWords[0] % 99999999999999999;
            agreementId = indexedRequestId;
        }
        s_agreementId = agreementId;

    }

    function confirmDelivery(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        require(
            block.timestamp >= i_agreements[_agreementId].deliveryDate,
            "Delivery date not reached yet"
        );
        i_agreements[_agreementId].status = AgreementStatus.Completed;
        i_agreements[_agreementId].fundsReleased = true;
        emit AgreementCompleted(_agreementId);
    }

    function cancelAgreement(
        uint256 _agreementId
    ) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        i_agreements[_agreementId].status = AgreementStatus.Cancelled;
        emit AgreementCancelled(_agreementId);
    }

    function releaseFunds(uint256 _agreementId) external onlySeller(_agreementId) {
        require(
            i_agreements[_agreementId].status == AgreementStatus.Completed,
            "Agreement must be completed"
        );
        require(i_agreements[_agreementId].fundsReleased == false, "Funds already released");
        i_agreements[_agreementId].fundsReleased = true;
    }

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

}
