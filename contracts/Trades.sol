// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract Trades is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    event RequestVolume(bytes32 indexed requestId, string cryptoNames, string cryptoSymbols, uint256 cryptoMaxSupply, uint256 cryptoCirculatingSupply, string cryptoQoutes);

    bytes32 internal i_jobId;
    uint256 internal i_fee;
    uint256 immutable i_updatedInterval = 1 days;
    uint256 immutable i_lastUpdatedTime= 0;

    string internal i_cryptoNames;
    string internal i_cryptoSymbols;
    uint256 internal i_cryptoMaxSupply;
    uint256 internal i_cryptoCirculatingSupply;
    string internal i_cryptoQoutes;

    constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        i_jobId = "7d80a6386ef543a3abb52817f6707e3b";
        i_fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }


    function requestVolumeData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            i_jobId,
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

        req.add("path", "data,1,quote,USD");
        req.add("path", "data,1027,quote,USD");
        req.add("path", "data,1839,quote,USD");

        return sendChainlinkRequest(req, i_fee);
    }

 
    function fulfill(
        bytes32 _requestId,
        string memory cryptoNamesResponse,
        string memory cryptoSymbolsResponse,
        uint256 cryptoMaxSupplyResponse,
        uint256 cryptoCirculatingSupplyResponse,
        string memory cryptoQoutesResponse
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, cryptoNamesResponse, cryptoSymbolsResponse, cryptoMaxSupplyResponse, cryptoCirculatingSupplyResponse,cryptoQoutesResponse);
        i_cryptoNames = cryptoNamesResponse;
        i_cryptoSymbols = cryptoSymbolsResponse;
        i_cryptoMaxSupply = cryptoMaxSupplyResponse;
        i_cryptoCirculatingSupply = cryptoCirculatingSupplyResponse;
        i_cryptoQoutes = cryptoQoutesResponse;
    }

    function fetchPeriodicData() internal  {
        if ( block.timestamp >= i_updatedInterval + i_lastUpdatedTime ) {
            requestVolumeData();
        }
    }

    // View and Pure Functions

    function getCryptoName() external view returns  (string memory) {
        return i_cryptoNames;
    }

    function getCryptoSymbol() external view returns  (string memory) {
        return i_cryptoSymbols;
    }

    function getCryptoMaxSupply() external view  returns (uint256) {
        return i_cryptoMaxSupply;
    }

    function getCryptoCirculatingSupply() external view  returns (uint256) {
        return i_cryptoMaxSupply;      
    }

    function getCryptoQoutes() external view returns (string memory) {
        return i_cryptoQoutes;
    }
        
}
