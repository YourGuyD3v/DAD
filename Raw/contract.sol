// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract WalletConnector is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    struct AccountInfo {
        address connectorAddress;
        uint256 currentBalance;
    }
  
    struct Transaction {
        uint256 nonce;
        uint256 transactionCount;
        string transactionHash;
        string blockHash;
        uint256 blockHeight;
        uint256 time;
        uint256 transactionIndex;
        string from;
        string to;
        uint256 value;
        uint256 gas;
        uint256 gasPrice;
        string transactionInputData;
    }

    event WalletConnected(address sender, uint256 accountBalance);
    event DataFullfilled(Transaction transaction);

    mapping(address => AccountInfo) private connectedWallets;
    mapping(uint256 => Transaction) private transactions;

    address private immutable i_oracle;
    bytes32 private immutable i_jobId;
    uint256 private immutable i_fee;
    string internal i_transactionApi;
    address internal walletAddress;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor(string memory transactionApi, address _oracle, bytes32 _jobId, uint256 _fee, address _link) {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        i_transactionApi = transactionApi;
        i_oracle = _oracle;
        i_jobId = _jobId;
        i_fee = _fee;
    }

    function connectWallet() external {
        walletAddress = msg.sender;
        AccountInfo memory account = AccountInfo(msg.sender, walletAddress.balance);
        connectedWallets[msg.sender] = account;
        emit WalletConnected(msg.sender, walletAddress.balance);
    }

    function requestTransactionsData() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            i_jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
    request.add("get", "https://api-sepolia.etherscan.io/api?module=account&action=txlist&address=0x0fAb9901C9A8aFD3Dc9d4A9C0413f8eB1F1F6B69&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey=QHY6H8ANHUTC4IYIZZYSUN53HZ9QJ2DTQ1");
    request.add("get", string(abi.encodePacked("https://api-sepolia.etherscan.io/api?module=account&action=txlist&address=", walletAddress)));

    // Add the remaining URL parameters
    // request.add("address", abi.encodePacked(bytes32ToString(bytes(walletAddress))));
    request.add("startblock", "0");
    request.add("endblock", "99999999");
    request.add("page", "1");
    request.add("offset", "10");
    request.add("sort", "asc");
    request.add("apikey", i_transactionApi);

    request.add("path", "result,blockNumber");

    int256 timesAmount = 10 ** 18;
    request.addInt("times", timesAmount);

        return sendChainlinkRequestTo(i_oracle, request, i_fee);
    }
    
    function requestPeriodicData() internal {
        if (block.timestamp >= i_lastUpdatedTime + i_updatedInterval) {
            requestTransactionsData();
        }
    }

    function fulfill(bytes32 requestId, bytes32[] memory _data) public recordChainlinkFulfillment(requestId) {
        Transaction memory transactionResponse;

        transactionResponse.nonce = uint256(_data[0]);
        transactionResponse.transactionCount = uint256(_data[1]);
        transactionResponse.transactionHash = bytes32ToString(_data[2]);
        transactionResponse.blockHash = bytes32ToString(_data[3]);
        transactionResponse.blockHeight = uint256(_data[4]);
        transactionResponse.time = uint256(_data[5]);
        transactionResponse.transactionIndex = uint256(_data[6]);
        transactionResponse.from = bytes32ToString(_data[7]);
        transactionResponse.to = bytes32ToString(_data[8]);
        transactionResponse.value = uint256(_data[9]);
        transactionResponse.gas = uint256(_data[10]);
        transactionResponse.gasPrice = uint256(_data[11]);
        transactionResponse.transactionInputData = bytes32ToString(_data[12]);

        transactions[transactionResponse.blockHeight] = transactionResponse;

        emit DataFullfilled(transactionResponse);
    }

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

    function getTransactionDetailsByAddress() public view returns (Transaction memory) {
        bytes32 ownerBytes = bytes32(uint256(uint160(walletAddress)));
        return transactions[uint256(ownerBytes)];
    }

    function getWalletAddress() external view returns (address) {
        return walletAddress;
    }

    // Helper function to convert bytes32 to string
    function bytes32ToString(bytes32 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            buffer[i] = value[i];
        }
        return string(buffer);
    }
}
