// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract Trades is ChainlinkClient {
    using Chainlink for Chainlink.Request;


    bytes32 private jobId;
    uint256 private fee;
    uint256 immutable i_updatedInterval = 1 days;
    uint256 immutable i_lastUpdatedTime= 0;

    event RequestVolume(bytes32 indexed requestId);

    constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
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

        req.add("path", "data,1,name");
        req.add("path", "data,1027,name");
        req.add("path", "data,1839,name");
        req.add("path", "data,1,name,symbol");
        req.add("path", "data,1027,name,symbol");
        req.add("path", "data,1839,name,symbol");

        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");

        req.add("path", "data,1,quote,USD,price");
        req.add("path", "data,1027,quote,USD,price");
        req.add("path", "data,1839,quote,USD,price");
        req.add("path", "data,1,quote,USD,price,volume_24h");
        req.add("path", "data,1027,quote,USD,price,volume_24h");
        req.add("path", "data,1839,quote,USD,price,volume_24h");
        req.add("path", "data,1,quote,USD,price,volume_24h,volume_change_24h");
        req.add("path", "data,1027,quote,USD,price,volume_24h,volume_change_24h");
        req.add("path", "data,1839,quote,USD,price,volume_24h,volume_change_24h");
        req.add("path", "data,1,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h");
        req.add("path", "data,1027,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h");
        req.add("path", "data,1839,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h");
        req.add("path", "data,1,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h");
        req.add("path", "data,1027,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h");
        req.add("path", "data,1839,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h");
        req.add("path", "data,1,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d");
        req.add("path", "data,1027,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d");
        req.add("path", "data,1839,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d");
        req.add("path", "data,1,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d,percent_change_30d");
        req.add("path", "data,1027,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d,percent_change_30d");
        req.add("path", "data,1839,quote,USD,price,volume_24h,volume_change_24h,percent_change_1h,percent_change_24h,percent_change_7d,percent_change_30d");

        return sendChainlinkRequest(req, fee);
    }

 
    function fulfill(
        bytes32 _requestId
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId);
    }

    function fetchPeriodicData() internal  {
        if ( block.timestamp >= i_updatedInterval + i_lastUpdatedTime ) {
            requestVolumeData();
        }
    }

    // View and Pure Functions

    function getCryptoData() public view returns  (string memory) {

    }
        
}