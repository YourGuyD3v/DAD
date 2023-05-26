// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract TrackNFTData is AccessControl, ChainlinkClient  {
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

    //     event NFTAdded(address indexed wallet, uint256 tokenId);
    // event NFTRemoved(address indexed wallet, uint256 tokenId);

    mapping(bytes32 => NftMetadata[]) internal i_nftMetadata;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 private jobId;
    uint256 private fee;
    string internal i_nftApiUrl;

    constructor(string memory nftApiUrl) {
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(0x0000000000000000000000000000000000000000));
         setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        i_nftApiUrl = nftApiUrl;
    }

    ///////////////
   /// Funtion ///
  ///////////////
    
       function requestNftData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillNftMetadeta.selector
        );
        req.add(
            "get",
            i_nftApiUrl
        );
        req.add("path", "items,id");
        req.add("path", "items,id,asset_contract_address");
        req.add("path", "items,id,asset_contract_address,token_id");
        req.add("path", "items,id,asset_contract_address,token_id,name");
        req.add("path", "items,id,asset_contract_address,token_id,name,description");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price,created_at");
        req.add("path", "items,id,asset_contract_address,token_id,name,description,image_url,price,created_at,updated_at,owner");

        return sendChainlinkRequest(req, fee);
    }

     function fulfillNftMetadeta(
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

    //     function addNFT(address wallet, uint256 tokenId) external {
    //     require(wallet != address(0), "Invalid wallet address");
    //     require(IERC721(msg.sender).ownerOf(tokenId) == wallet, "Not the owner of the NFT");

    //     connectedWallets[wallet].nftTokens.push(tokenId);
    //     emit NFTAdded(wallet, tokenId);
    // }

    // function removeNFT(address wallet, uint256 tokenId) external {
    //     require(wallet != address(0), "Invalid wallet address");
    //     uint256[] storage nftTokens = connectedWallets[wallet].nftTokens;
    //     uint256 index = getNFTIndex(nftTokens, tokenId);
    //     require(index < nftTokens.length, "NFT not found");

    //     nftTokens[index] = nftTokens[nftTokens.length - 1];
    //     nftTokens.pop();
    //     emit NFTRemoved(wallet, tokenId);
    // }

    //    function programmaticallyAddNFT(address wallet, uint256 tokenId) external {
    //     require(wallet != address(0), "Invalid wallet address");
    //     require(IERC721(msg.sender).ownerOf(tokenId) == wallet, "Not the owner of the NFT");

    //     connectedWallets[wallet].nftTokens.push(tokenId);
    //     emit NFTAdded(wallet, tokenId);
    // }

    function updateNftData(uint256 tokenId, string calldata newData ) external onlyRole(OWNER_ROLE)  {}

    // View and Pure Functions

    
    // function getNFTIndex(uint256[] storage nftTokens, uint256 tokenId) internal view returns (uint256) {
    //     for (uint256 i = 0; i < nftTokens.length; i++) {
    //         if (nftTokens[i] == tokenId) {
    //             return i;
    //         }
    //     }
    //     return nftTokens.length; // Return a value outside the valid index range to indicate not found
    // }

    
    function isAuthorized(address account) public view returns (bool) { 
    return hasRole(ADMIN_ROLE, account);

    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}
