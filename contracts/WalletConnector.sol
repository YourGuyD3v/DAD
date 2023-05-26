// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

error WalletConnector__NotOwner();

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
    event RequestVolume(bytes32 indexed requestId, Transaction transaction);

    mapping(address => AccountInfo) private connectedWallets;
    mapping(uint256 => Transaction) private transactions;

    bytes32 private constant JOB_ID = bytes32("ca98366cc7314957b8c012c72f05aeeb");
    string internal i_transactionApiUrl;
    uint256 public chainId = block.chainid;
    address public walletAddress;
    string internal endpoint;
    uint256 private constant FEE = (1 * LINK_DIVISIBILITY) / 10;
    bytes32 private s_lastRequestId;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor(string memory transactionApiUrl) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        i_transactionApiUrl = transactionApiUrl;
    }

     /////////////////
    /// Functions ///
   /////////////////

    function connectWallet() external {
        walletAddress = msg.sender;
        AccountInfo memory account = AccountInfo(msg.sender, walletAddress.balance);
        connectedWallets[msg.sender] = account;
        emit WalletConnected(msg.sender, walletAddress.balance);
    }

    function fetchWalletTransactions() public returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(
            JOB_ID,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
            i_transactionApiUrl
        );

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
        if (block.timestamp >= i_updatedInterval + i_lastUpdatedTime) {
            fetchWalletTransactions();
        }
    }

    function fulfill(bytes32 requestId,
     Transaction memory transactionResponse,
     uint256[] memory _data
     ) public recordChainlinkFulfillment(requestId) {
        emit RequestVolume(requestId, transactionResponse);

        transactionResponse.nonce = _data[0];
        transactionResponse.transactionCount = _data[1];
        transactionResponse.transactionHash = toString(_data[2]);
        transactionResponse.blockHash = toString(_data[3]);
        transactionResponse.blockHeight = _data[4];
        transactionResponse.time = _data[5];
        transactionResponse.transactionIndex = _data[6];
        transactionResponse.from = toString(_data[7]);
        transactionResponse.to = toString(_data[8]);
        transactionResponse.value = _data[9];
        transactionResponse.gas = _data[10];
        transactionResponse.gasPrice = _data[11];
        transactionResponse.transactionInputData = toString(_data[12]);
    }

    // View and Pure Funtions

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

    function getTransactionDetailsByAddress() external view returns (Transaction memory) {
    bytes32 ownerBytes = bytes32(uint256(uint160(walletAddress)));
    return transactions[uint256(ownerBytes)];

    }

    function getWalletAddress() external view virtual returns (address) {
        return walletAddress;
    }

    // Helper function to convert uint256 to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }  

}
