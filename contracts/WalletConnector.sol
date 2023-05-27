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
    event RequestVolumeEvent(bytes32 indexed requestId, Transaction transaction);

    mapping(address => AccountInfo) private connectedWallets;
    mapping(uint256 => Transaction) private transactions;

    bytes32 private constant JOB_ID = bytes32("ca98366cc7314957b8c012c72f05aeeb");
    string internal i_transactionApiUrl;
    address internal walletAddress;
    uint256 private constant FEE = (1 * LINK_DIVISIBILITY) / 10;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor(string memory transactionApiUrl) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        i_transactionApiUrl = transactionApiUrl;
    }

    function connectWallet() external {
        walletAddress = msg.sender;
        AccountInfo memory account = AccountInfo(msg.sender, walletAddress.balance);
        connectedWallets[msg.sender] = account;
        emit WalletConnected(msg.sender, walletAddress.balance);
    }

    function fetchTransactionsData() public returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(
            JOB_ID,
            address(this),
            this.fulfill.selector
        );

        req.add("get", i_transactionApiUrl);

        req.add("path", "height,hash,time,median_time,nonce");
        req.add("path", "height,hash,time,median_time,nonce,difficulty,total_difficulty,size,stripped_size,weight,block_reward,coinbase,transaction_count");
        req.add("path", "transactions,hash");
        req.add("path", "transactions,hash,block_hash");
        req.add("path", "transactions,hash,block_hash,block_height");
        req.add("path", "transactions,hash,block_hash,block_height,time");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from,to");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from,to,value");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from,to,value,gas");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from,to,value,gas,gas_price");
        req.add("path", "transactions,hash,block_hash,block_height,time,transaction_index,from,to,value,gas,gas_price,input");

        // Sends the request
        return sendChainlinkRequest(req, FEE);
    }

    function fetchPeriodicData() internal {
        if (block.timestamp >= i_lastUpdatedTime + i_updatedInterval) {
            fetchTransactionsData();
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

        emit RequestVolumeEvent(requestId, transactionResponse);
    }

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

    function getTransactionDetailsByAddress() external view returns (Transaction memory) {
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
