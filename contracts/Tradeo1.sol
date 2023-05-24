// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract APIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    bytes32 private  cryptoData;
    bytes32 private jobId;
    uint256 private fee;
    uint256 immutable i_updatedInterval = 1 days;
    uint256 immutable i_lastUpdatedTime= 0;

    event RequestVolume(bytes32 indexed requestId, bytes32 volume);

    constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7da2702f37fd48e5b1b9a5715e3509b6";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }


    function requestVolumeData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add(
            "get",
            "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?CMC_PRO_API_KEY=0d13079e-077f-42d3-9c62-f903e46992bd"
        );

        req.add("path", "data"); // Chainlink nodes 1.0.0 and later support this format


        return sendChainlinkRequest(req, fee);
    }

 
    function fulfill(
        bytes32 _requestId,
        bytes32 _cryptoData
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _cryptoData);
        cryptoData = _cryptoData;
    }

    function fetchPeriodicData() internal  {
        if ( block.timestamp >= i_updatedInterval + i_lastUpdatedTime ) {
            requestVolumeData();
        }
    }

    // View and Pure Functions

    function getCryptoData() public view returns  (bytes32) {
        return cryptoData;
    }

}
