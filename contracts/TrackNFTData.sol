// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract TrackNFTData is ChainlinkClient  {
        using Chainlink for Chainlink.Request;

        struct NftMetadata {
            uint256 id;
            address contrctAddress;
            uint256 tokenId;
            string name;
            string symbol;
            string description;
            string imageUrl;
            uint256 price;
            string createdAt;
            address owner;
        }

    event RequestVolume(
        bytes32 indexed requestId,
        NftMetadata nftMetadata
    );

    mapping(bytes32 => NftMetadata[]) internal i_nftMetadata;

    bytes32 internal constant JOB_ID = "7d80a6386ef543a3abb52817f6707e3b";
    uint256 internal constant FEE = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    string internal i_nftApiUrl;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor(string memory nftApiUrl) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        i_nftApiUrl = nftApiUrl;
    }


    /////////////////
   /// Functions ///
  /////////////////
    
       function requestNftData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            JOB_ID,
            address(this),
            this.fulfillNftMetadata.selector
        );

        req.add(
            "get", i_nftApiUrl);
            
        req.add("path", "items,id");
        req.add("path", "items,id,asset_contract_address");
        req.add("path", "items,id,asset_contract_address,token_id");
        req.add("path", "items,id,asset_contract_address,token_id,name");
        req.add("path", "items,id,asset_contract_address,token_id,name,description");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price,created_at");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price,created_at,updated_at,owner");

        return sendChainlinkRequest(req, FEE);
    }

    function fetchPeriodicDataForRequestNftData() internal {
        if (block.timestamp >= i_updatedInterval + i_lastUpdatedTime) {
            requestNftData();
        }
    }

     function fulfillNftMetadata(
        bytes32 _requestId,
         NftMetadata memory nftMetadataResponse,
         bytes32[] memory _Data 
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, nftMetadataResponse);
        nftMetadataResponse.id = uint256(_Data[0]);
        nftMetadataResponse.contrctAddress = address(uint160(uint256(_Data[1])));
        nftMetadataResponse.tokenId = uint256(_Data[2]);
        nftMetadataResponse.name = bytes32ToString(_Data[3]);
        nftMetadataResponse.symbol = bytes32ToString(_Data[4]);
        nftMetadataResponse.description = bytes32ToString(_Data[5]);
        nftMetadataResponse.imageUrl = bytes32ToString(_Data[6]);
        nftMetadataResponse.price = uint256(_Data[7]);
        nftMetadataResponse.createdAt = bytes32ToString(_Data[8]);
        nftMetadataResponse.owner = address(uint160(uint256(_Data[9])));

        i_nftMetadata[_requestId].push(nftMetadataResponse);

    }

    // View and Pure Functions

    
    function getNFTIndex(uint256[] storage nftTokens, uint256 tokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < nftTokens.length; i++) {
            if (nftTokens[i] == tokenId) {
                return i;
            }
        }
        return nftTokens.length; // Return a value outside the valid index range to indicate not found
    }

    function getNftByAddress() public view returns (NftMetadata[] memory) {
    bytes32 ownerBytes = bytes32(uint256(uint160(msg.sender)));
    return i_nftMetadata[ownerBytes];
    }

    function bytes32ToString(bytes32 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            buffer[i] = value[i];
        }
        return string(buffer);
    }  

}
