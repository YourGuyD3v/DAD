pragma solidity ^0.8.0;

contract TwoPartyAgreement {
    enum AgreementStatus { Created, Completed, Cancelled }

    struct Agreement {
        address buyer;
        address seller;
        uint256 price;
        uint256 deliveryDate;
        AgreementStatus status;
        bool fundsReleased;
    }

    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCount;

    event AgreementCreated(uint256 agreementId, address indexed buyer, address indexed seller, uint256 price, uint256 deliveryDate);
    event AgreementCompleted(uint256 agreementId);
    event AgreementCancelled(uint256 agreementId);

    modifier onlyBuyer(uint256 _agreementId) {
        require(msg.sender == agreements[_agreementId].buyer, "Only the buyer can perform this action");
        _;
    }

    modifier onlySeller(uint256 _agreementId) {
        require(msg.sender == agreements[_agreementId].seller, "Only the seller can perform this action");
        _;
    }

    modifier inProgress(uint256 _agreementId) {
        require(agreements[_agreementId].status == AgreementStatus.Created, "Agreement must be in progress");
        _;
    }

    constructor() {
        agreementCount = 0;
    }

    function createAgreement(address _seller, uint256 _price, uint256 _deliveryDate) external {
        agreementCount++;
        agreements[agreementCount] = Agreement(
            msg.sender,
            _seller,
            _price,
            _deliveryDate,
            AgreementStatus.Created,
            false
        );
        emit AgreementCreated(agreementCount, msg.sender, _seller, _price, _deliveryDate);
    }

    function confirmDelivery(uint256 _agreementId) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        require(block.timestamp >= agreements[_agreementId].deliveryDate, "Delivery date not reached yet");
        agreements[_agreementId].status = AgreementStatus.Completed;
        agreements[_agreementId].fundsReleased = true;
        emit AgreementCompleted(_agreementId);
    }

    function cancelAgreement(uint256 _agreementId) external onlyBuyer(_agreementId) inProgress(_agreementId) {
        agreements[_agreementId].status = AgreementStatus.Cancelled;
        emit AgreementCancelled(_agreementId);
    }

    function releaseFunds(uint256 _agreementId) external onlySeller(_agreementId) {
        require(agreements[_agreementId].status == AgreementStatus.Completed, "Agreement must be completed");
        require(agreements[_agreementId].fundsReleased == false, "Funds already released");
        agreements[_agreementId].fundsReleased = true;
    }
}
