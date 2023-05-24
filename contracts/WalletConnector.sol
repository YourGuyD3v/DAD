// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract WalletConnector is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    struct AccountInfo {
        address walletAddress;
        uint256[] currentBalance;
        uint256[] nftTokens;
        uint256[] transactionIds;
    }
  
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 timeStamp;
    }

    event WalletConnected(address sender);
    event TransactionUpdated(address indexed wallet, uint256 transactionId, address sender, address receiver, uint256 amount);
    event NFTAdded(address indexed wallet, uint256 tokenId);
    event NFTRemoved(address indexed wallet, uint256 tokenId);

    mapping(address => AccountInfo) private connectedWallets;
    mapping(uint256 => Transaction) private transactions;
    mapping(address => Transaction[]) private s_walletTransactions;

    bytes32 private constant JOB_ID = bytes32("ca98366cc7314957b8c012c72f05aeeb");
    string public Url = "https://sepolia.infura.io/v3/";
    uint256 public chainId = block.chainid;
    address public walletAddress = walletAddress;
    string internal endpoint;
    uint256 private constant PRICE = (1 * LINK_DIVISIBILITY) / 10;
    bytes32 private s_lastRequestId;
    uint256 internal i_updatedInterval = 1 days;
    uint256 internal i_lastUpdatedTime = 0;

    constructor() {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
    }

     /////////////////
    /// Functions ///
   /////////////////

    function connectWallet() external {
        require(msg.sender != address(0), "Please connect your Wallet!");

        AccountInfo memory account = AccountInfo( msg.sender, new uint256[](0),  new uint256[](0), new uint256[](0));
        connectedWallets[msg.sender] = account;
        emit WalletConnected(msg.sender);
    }

    function fetchRecentWalletTransactions() public virtual returns (bytes32) {
        endpoint = string(abi.encodePacked(Url, "?chainId=", uint256ToString(chainId), "&address=", addressToString(walletAddress)));
        Chainlink.Request memory req = buildChainlinkRequest(JOB_ID, address(this), this.fulfill.selector);
        req.add("get", endpoint);
        req.add("path", "sender");
        req.add("path", "receiver");
        req.add("path", "amount");
        req.add("path", "timeStamp");
        return sendChainlinkRequest(req, PRICE);
    }

    function fetchPeriodicData() internal {
        if (block.timestamp >= i_updatedInterval + i_lastUpdatedTime) {
            fetchRecentWalletTransactions();
        }
    }

    function fulfill(bytes32 requestId, bytes memory responseData) public recordChainlinkFulfillment(requestId) {
        (address[] memory senders, address[] memory receivers, uint256[] memory amounts, uint256[] memory timeStamps) =
            abi.decode(responseData, (address[], address[], uint256[], uint256[]));

        for (uint256 i = 0; i < senders.length; i++) {
            Transaction memory transaction = Transaction({
                sender: senders[i],
                receiver: receivers[i],
                amount: amounts[i],
                timeStamp: timeStamps[i]
            });
            s_walletTransactions[msg.sender].push(transaction);
        }
        s_lastRequestId = requestId;
    }

    function sendTransaction(address receiver, uint256 amount) external {
        require(receiver != address(0), "Invalid receiver address");
        require(amount > 0, "Invalid amount");

        Transaction memory transaction = Transaction(msg.sender, receiver, amount, block.timestamp);
        uint256 transactionId = connectedWallets[msg.sender].transactionIds.length;
        connectedWallets[msg.sender].transactionIds.push(transactionId);
        transactions[transactionId] = transaction;
        emit TransactionUpdated(msg.sender, transactionId, msg.sender, receiver, amount);
    }

    function receiveTransaction(address sender, uint256 amount) external {
        require(sender != address(0), "Invalid sender address");
        require(amount > 0, "Invalid amount");

        Transaction memory transaction = Transaction(sender, msg.sender, amount, block.timestamp);
        uint256 transactionId = connectedWallets[msg.sender].transactionIds.length;
        connectedWallets[msg.sender].transactionIds.push(transactionId);
        transactions[transactionId] = transaction;
        emit TransactionUpdated(msg.sender, transactionId, sender, msg.sender, amount);
    }

    function addNFT(address wallet, uint256 tokenId) external {
        require(wallet != address(0), "Invalid wallet address");
        require(IERC721(msg.sender).ownerOf(tokenId) == wallet, "Not the owner of the NFT");

        connectedWallets[wallet].nftTokens.push(tokenId);
        emit NFTAdded(wallet, tokenId);
    }

    function removeNFT(address wallet, uint256 tokenId) external {
        require(wallet != address(0), "Invalid wallet address");
        uint256[] storage nftTokens = connectedWallets[wallet].nftTokens;
        uint256 index = getNFTIndex(nftTokens, tokenId);
        require(index < nftTokens.length, "NFT not found");

        nftTokens[index] = nftTokens[nftTokens.length - 1];
        nftTokens.pop();
        emit NFTRemoved(wallet, tokenId);
    }


    function programmaticallyAddTransaction(address sender, address receiver, uint256 amount) external {
        require(sender != address(0), "Invalid sender address");
        require(receiver != address(0), "Invalid receiver address");
        require(amount > 0, "Invalid amount");

        Transaction memory transaction = Transaction(sender, receiver, amount, block.timestamp);
        uint256 transactionId = connectedWallets[sender].transactionIds.length;
        connectedWallets[sender].transactionIds.push(transactionId);
        transactions[transactionId] = transaction;
        emit TransactionUpdated(sender, transactionId, sender, receiver, amount);
    }

    function programmaticallyAddNFT(address wallet, uint256 tokenId) external {
        require(wallet != address(0), "Invalid wallet address");
        require(IERC721(msg.sender).ownerOf(tokenId) == wallet, "Not the owner of the NFT");

        connectedWallets[wallet].nftTokens.push(tokenId);
        emit NFTAdded(wallet, tokenId);
    }

    // View and Pure Funtions

    function getNFTIndex(uint256[] storage nftTokens, uint256 tokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < nftTokens.length; i++) {
            if (nftTokens[i] == tokenId) {
                return i;
            }
        }
        return nftTokens.length; // Return a value outside the valid index range to indicate not found
    }


    // Helper function to convert uint256 to string
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

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    // Helper function to convert address to string
    function addressToString(address _address) internal pure returns (string memory) {
    bytes32 value = bytes32(bytes20(_address));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
        str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
        str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
    }

    return string(str);
}

    function getAccountInfo(address wallet) external view returns (AccountInfo memory) {
        return connectedWallets[wallet];
    }

}
