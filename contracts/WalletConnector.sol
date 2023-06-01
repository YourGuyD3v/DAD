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

    mapping(address => AccountInfo) private connectedWallets;

    bytes32 public data;

    address internal walletAddress;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor() {}

    function connectWallet() external {
        walletAddress = msg.sender;
        AccountInfo memory account = AccountInfo(msg.sender, walletAddress.balance);
        connectedWallets[msg.sender] = account;
        emit WalletConnected(msg.sender, walletAddress.balance);
    }

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

    function getWalletAddress() external view returns (address) {
        return walletAddress;
    }
}
