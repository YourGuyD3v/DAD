// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract TrackNFTData is AccessControl, ChainlinkClient  {
        using Chainlink for Chainlink.Request;

        struct NftMetadata {
            string name;
            string symbol;
            string description;
            string price;
            string imageUrl;
            string createdAt;
            string owner;
            string isHidden;
            string isFeatured;
        }

    event RequestVolume(
        bytes32 indexed requestId,
        NftMetadata nftMetadata
    );

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 private jobId;
    uint256 private fee;
    string internal i_apiUrl;

    constructor(string memory apiUrl) {
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(0x0000000000000000000000000000000000000000));
         setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        i_apiUrl = apiUrl;
    }

    ///////////////
   /// Funtion ///
  ///////////////
    
       function requestNftData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add(
            "get",
            i_apiUrl
        );
        req.add("path", "collection,name");
        req.add("path", "collection,name,description");
        req.add("path", "collection,name,description,image_url");
        req.add("path", "collection,name,description,image_url,total_supply,created_at");
        req.add("path", "collection,name,description,image_url,total_supply,created_at,owner");
        req.add("path", "collection,name,description,image_url,total_supply,created_at,owner,slug");

        req.add("path", "listings,token_id");
        req.add("path", "listings,token_id,owner,permalink,price");
        req.add("path", "listings,token_id,owner,permalink,price,created_at,last_updated,is_sold,is_hidden");
        req.add("path", "listings,token_id,owner,permalink,price,created_at,last_updated,is_sold,is_hidden,is_featured");

        return sendChainlinkRequest(req, fee);
    }

     function fulfill(
        bytes32 _requestId, NftMetadata memory nftMetadata
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, nftMetadata);
        // nftMetadata.name = name;
    }

    function nftUrl() external {}

    function nftImageUrl() external {}

    function nftMetadata() external {}

    function nftPrice() external {}

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

}
