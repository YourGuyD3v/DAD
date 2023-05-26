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

    string private Url = "https://sepolia.infura.io/v3/";
    uint256 private chainId = 1;
    address private walletAddress = 0x9F6713Aac16Ca947E37c5d5512090E0195c30EF9;
    string private endpoint;

    mapping(address => Transaction[]) private s_walletTransactions;
    mapping(bytes32 => ResponseData) private requestIdToData;

    // Functions

    function fetchWalletData() public returns (bytes32) {
        endpoint = string(abi.encodePacked(Url, "?chainId=", (chainId), "&address=", addressToString(walletAddress)));
        Chainlink.Request memory req = buildChainlinkRequest(
            JOB_ID,
            address(this),
            this.fulfill.selector
        );
        req.add("get", endpoint);
        req.add("path", "sender");
        req.add("path", "receiver");
        req.add("path", "balance");
        req.add("path", "timeStamp");
        return sendChainlinkRequestTo(address(0), req, 0);
    }

  function fulfill(bytes32 requestId, bytes memory responseData) public recordChainlinkFulfillment(requestId) {
    ResponseData storage data = requestIdToData[requestId];
    (address[] memory senders, address[] memory receivers, uint256[] memory balances, uint256[] memory timeStamps) = abi.decode(responseData, (address[], address[], uint256[], uint256[]));
    data.senders = senders;
    data.receivers = receivers;
    data.balances = balances;
    data.timeStamps = timeStamps;
}

    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
    uint256 index = digits - 1;
    temp = value;
    
    while (temp != 0) {
        buffer[index--] = bytes1(uint8(48 + temp % 10));
        temp /= 10;
    }
    
    return string(buffer);
}

function addressToString(address value) internal pure returns (string memory) {
    bytes32 data = bytes32(uint256(uint160(value)));
    bytes memory alphabet = "0123456789abcdef";
    
    bytes memory result = new bytes(42);
    result[0] = "0";
    result[1] = "x";
    
    for (uint256 i = 0; i < 20; i++) {
        result[2 + i * 2] = alphabet[uint8(data[i + 12] >> 4)];
        result[3 + i * 2] = alphabet[uint8(data[i + 12] & 0x0f)];
    }
    
    return string(result);
}


    // Pure and View Functions

    function getWalletData() public view returns (Transaction[] memory) {
        return s_walletTransactions[msg.sender];
    }
}
