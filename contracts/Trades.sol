// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Trades is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    struct TrackTrading {
        string currencyName;
        uint256 amount;
        uint256 currencyPrice;
        uint256 dateNtime;
    }

    event RequestCrypto(
        bytes32 indexed requestId,
        uint256 s_maxSupply,
        uint256 s_circulatingSupply,
        uint256 s_totalSupply,
        string btcName,
        string ethName,
        string bnbName,
        string btcSymbol,
        string ethSymbol,
        string bnbSymbol
    );

    event TrackTradingEvents(
        uint256 indexed dayNtime,
        string indexed currency,
        uint256 cryptoAmount,
        uint256 indexed price
    );


    bytes32 private jobId;
    uint256 private fee;

    uint256 private s_btcMaxSupply;
    uint256 private s_ethMaxSupply;
    uint256 private s_bnbMaxSupply;
    uint256 private s_circulatingSupply;
    uint256 private s_totalSupply;
    string private btcName;
    string private ethName;
    string private bnbName;
    string private btcSymbol;
    string private ethSymbol;
    string private bnbSymbol;
    uint256 public s_exchangeRate;

    mapping(uint256 => TrackTrading) private s_trackTrading;

    constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0.1 LINK (Varies by network and job)
    }

     /////////////////
    /// Functions ///
   /////////////////

    function createTrack(
        uint256 _dateNtime,
        string memory _currencyName,
        uint256 _amount,
        uint256 _currencyPrice
    ) external {
        TrackTrading memory newTrackTrading = TrackTrading(
            _currencyName,
            _amount,
            _currencyPrice,
            _dateNtime
        );
        s_trackTrading[_dateNtime] = newTrackTrading;
        emit TrackTradingEvents(
            _dateNtime,
            _currencyName,
            _currencyPrice,
            _amount
        );
    }

    function requestCryptoDataInString() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

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

        return sendChainlinkRequest(req, fee);

    }

     function requestCryptoDataInUint256() public returns (bytes32 requestId) {
       
   Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
            "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?CMC_PRO_API_KEY=0d13079e-077f-42d3-9c62-f903e46992bd"
        );

        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply");
        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply");
        req.add("path", "data,1,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");
        req.add("path", "data,1027,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");
        req.add("path", "data,1839,name,symbol,slug,num_market_pairs,date_added,tags,max_supply,circulating_supply,total_supply");



        return sendChainlinkRequest(req, fee);

    }

    function fulfill(
        bytes32 requestId,
        uint256 _maxSupplyResponse,
        uint256 _btcMaxSupplyResponse,
        uint256 _bnbMaxSupplyResponse,
        uint256 _circulatingSupplyResponse,
        uint256 _totalSupplyResponse,
        string memory _btcResponse,
        string memory _ethResponse,
        string memory _bnbResponse,
        string memory _btcSymbolResponse,
        string memory _ethSymbolResponse,
        string memory _bnbSymbolResponse
    ) public  recordChainlinkFulfillment(requestId) {

        emit RequestCrypto( requestId, 
            _maxSupplyResponse,
         _circulatingSupplyResponse,
        _totalSupplyResponse,
        _btcResponse, 
        _ethResponse,
         _bnbResponse,
          _btcSymbolResponse, 
          _ethSymbolResponse, 
          _bnbSymbolResponse
          );

        s_btcMaxSupply = _maxSupplyResponse;
        s_circulatingSupply = _circulatingSupplyResponse;
        s_totalSupply = _totalSupplyResponse;
        btcName = _btcResponse;
        ethName = _ethResponse;
        bnbName = _bnbResponse;
        btcSymbol = _btcSymbolResponse;
        ethSymbol = _ethSymbolResponse;
        bnbSymbol = _bnbSymbolResponse;
    }

    // View and Pure Functions

    //  function getbtc() public view returns (uint256) {
    //     return btcName;
    // }

    function getbtcName() public view returns (string memory) {
        return btcName;
    }

    function getethName() public view returns (string memory) {
        return ethName;
    }

    function getbnbName() public view returns (string memory) {
        return bnbName;
    }

    function getBtcSymbol() public view returns (string memory) {
        return btcSymbol;
    }

    function getEthSymbol() public view returns (string memory) {
        return ethSymbol;
    }

    function getBnbSymbol() public view returns (string memory) {
        return bnbSymbol;
    }


    function getCreateTrading(uint256 _dateNtime)
        public
        view
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        TrackTrading memory trackTrading = s_trackTrading[_dateNtime];
        return (
            trackTrading.currencyPrice,
            trackTrading.currencyName,
            trackTrading.amount
        );
    }
}