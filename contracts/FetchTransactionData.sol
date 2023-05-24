// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

error InvalidResponse();

contract TransactionData is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    struct Transaction {
        address sender;
        address receiver;
        uint256 balance;
        uint256 timeStamp;
    }

      struct ResponseData {
        address[] senders;
        address[] receivers;
        uint256[] balances;
        uint256[] timeStamps;
    }

    bytes32 private constant JOB_ID = "ca98366cc7314957b8c012c72f05aeeb";
    string public Url = "https://sepolia.infura.io/v3/";
    uint256 public chainId = 11155111;
    address public walletAddress = 0x9F6713Aac16Ca947E37c5d5512090E0195c30EF9;
    string internal endpoint;
    uint256 private constant PRICE = (1 * LINK_DIVISIBILITY) / 10;
    bytes32 private s_lastRequestId;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    mapping(address => Transaction[]) private s_walletTransactions;
    mapping(bytes32 => ResponseData) private requestIdToData;

     constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);

    }

    // Functions

    function fetchWalletData() public virtual returns (bytes32) {
        endpoint = string(abi.encodePacked(Url, "?chainId=", chainId, "&address=", walletAddress));
        Chainlink.Request memory req = buildChainlinkRequest(
            JOB_ID ,
            address(this),
            this.fulfill.selector
        );
        req.add("get", endpoint);
        req.add("path", "sender");
        req.add("path", "receiver");
        req.add("path", "balance");
        req.add("path", "timeStamp");
        return sendChainlinkRequest(req, PRICE);
    }

    function fetchPeriodicData() internal {
        if(block.timestamp >= i_updatedInterval + i_lastUpdatedTime) {
            fetchWalletData();
        }
    }

  function fulfill(bytes32 requestId, bytes memory responseData) public recordChainlinkFulfillment(requestId) {
    ResponseData storage data = requestIdToData[requestId];
    (address[] memory senders, address[] memory receivers, uint256[] memory balances, uint256[] memory timeStamps) = abi.decode(responseData, (address[], address[], uint256[], uint256[]));
    data.senders = senders;
    data.receivers = receivers;
    data.balances = balances;
    data.timeStamps = timeStamps;
    s_lastRequestId = requestId;

     for (uint256 i = 0; i < senders.length; i++) {
    Transaction memory transaction = Transaction({
      sender: senders[i],
      receiver: receivers[i],
      balance: balances[i],
      timeStamp: timeStamps[i]
    });
    s_walletTransactions[msg.sender].push(transaction);
  }
}

    // Pure and View Functions

    function getLastRequestId() public view returns(bytes32) {
        return s_lastRequestId;
    }

   function getWalletData() public view returns (Transaction[] memory) {
    ResponseData storage data = requestIdToData[getLastRequestId()];
    Transaction[] memory transactions = new Transaction[](data.senders.length);
    
    for (uint256 i = 0; i < data.senders.length; i++) {
        transactions[i] = Transaction(
            data.senders[i],
            data.receivers[i],
            data.balances[i],
            data.timeStamps[i]
        );
    }
    
    return transactions;
}

function getWalletTransactions() public view returns (Transaction[] memory) {
    return s_walletTransactions[msg.sender];
}
}
