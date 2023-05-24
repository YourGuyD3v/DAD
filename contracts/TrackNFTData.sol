// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract TrackNFTData is ERC721, AccessControl, ChainlinkClient  {
        using Chainlink for Chainlink.Request;

    event RequestVolume(
        bytes32 indexed requestId
    );

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string internal i_name;
    string internal i_symbol;
    bytes32 private jobId;
    uint256 private fee;

    constructor() ERC721(i_name, i_symbol) {
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(0x0000000000000000000000000000000000000000));
         setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    ///////////////
   /// Funtion ///
  ///////////////
    
       function requestVolumeData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add(
            "get",
            "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD"
        );
        req.add("path", "RAW,ETH,USD,VOLUME24HOUR"); 
        return sendChainlinkRequest(req, fee);
    }

     function fulfill(
        bytes32 _requestId
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId);
    }

    function NftUrl() external {}

    function NftImageUrl() external {}

    function NftMetadata() external {}

    function NftPrice() external {}

    function updateNftData(uint256 tokenId, string calldata newData ) external onlyRole(OWNER_ROLE)  {}

    function storeNftData() internal {}

    // View and Pure Functions

    function getNftUrl() public view  returns (string memory) {}

    function getImageUrl() public view  returns (string memory) {}

    function getNftMetadata() public view  returns (string memory) {}

    function getNftPrice() public view  returns (uint256) {}

    function getStoredNftData() public view  returns (bytes32) {}

    function isAuthorized(address account) public view returns (bool) {
    return hasRole(ADMIN_ROLE, account);
}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
}


}