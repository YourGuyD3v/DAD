// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract WalletConnector is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    struct AccountInfo {
        address connectorAddress;
        uint256 currentBalance;
    }

    event WalletConnected(address sender, uint256 accountBalance);
    event DataFullfilled(bytes32 requestId, bytes32 data);

    mapping(address => AccountInfo) private connectedWallets;

    bytes32 public data;

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
    request.add("get", "https://api-sepolia.etherscan.io/api?module=account&action=txlist&address");

        return sendChainlinkRequest(request, i_fee);
    }
    
    function requestPeriodicData() internal {
        if (block.timestamp >= i_lastUpdatedTime + i_updatedInterval) {
            requestTransactionsData();
        }
    }

    function fulfill(bytes32 requestId, bytes32 _data) public recordChainlinkFulfillment(requestId) {
        data = _data;
        emit DataFullfilled(requestId, data);
    }

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

    // function getTransactionDetailsByAddress() public view returns (Transaction memory) {
    //     bytes32 ownerBytes = bytes32(uint256(uint160(walletAddress)));
    //     return transactions[uint256(ownerBytes)];
    // }

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
