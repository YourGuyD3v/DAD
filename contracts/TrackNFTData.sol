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

    address private immutable i_oracle;
    bytes32 private immutable i_jobId;
    uint256 private immutable i_fee;
    string internal i_nftApiUrl;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor(string memory _nftApiUrl, address _oracle, bytes32 _jobId, uint256 _fee, address _link) {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        i_nftApiUrl = _nftApiUrl;
        i_oracle = _oracle;
        i_jobId = _jobId;
        i_fee = _fee;
    }


    /////////////////
   /// Functions ///
  /////////////////
    
       function requestNftData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            i_jobId,
            address(this),
            this.fulfillNftMetadata.selector
        );

        req.add(
            "get", "https://fluent-smart-asphalt.ethereum-sepolia.discover.quiknode.pro/dab918dcf19dae58a972267bfacce198a77d42a5/");

            req.add("qn_fetchN", "");

       return sendChainlinkRequestTo(i_oracle, req, i_fee);
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
