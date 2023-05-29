// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


contract Trades is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    event RequestVolume(bytes32 indexed requestId, string cryptoNames, string cryptoSymbols, uint256 cryptoMaxSupply, uint256 cryptoCirculatingSupply, string cryptoQoutes);

    address private immutable i_oracle;
    bytes32 private immutable i_jobId;
    uint256 private immutable i_fee;
    string internal i_tradeApiUrl;
    uint256 immutable i_updatedInterval = 1 days;
    uint256 immutable i_lastUpdatedTime= 0;

    string internal i_cryptoNames;
    string internal i_cryptoSymbols;
    uint256 internal i_cryptoMaxSupply;
    uint256 internal i_cryptoCirculatingSupply;
    string internal i_cryptoQoutes;

    constructor(string memory tradeApiUrl, address _oracle, bytes32 _jobId, uint256 _fee, address _link) {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        i_tradeApiUrl = tradeApiUrl;
        i_oracle = _oracle;
        i_jobId = _jobId;
        i_fee = _fee;
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
            i_tradeApiUrl
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
