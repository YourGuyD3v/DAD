const { ethers } = require("hardhat")

async function fetchTransactionData() {
    const walletConnector = await ethers.getContract("WalletConnector")
    const connectTx = await walletConnector.connectWallet()
    await connectTx.wait(1)
    const connectorAddress = await walletConnector.getWalletAddress()
    const accountInfo = await walletConnector.getAccountInfo(connectorAddress)
    console.log(connectorAddress)
    console.log(accountInfo.toString())
    const requestTransactionDataTx = await walletConnector.requestTransactionsData()
    await requestTransactionDataTx.wait(1)
    const transactionDataTx = await walletConnector.getTransactionDetailsByAddress()
    await transactionDataTx.wait(1)
    console.log(requestTransactionDataTx)
    console.log(`Transaction data: [${transactionDataTx}]`)
}

fetchTransactionData()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error)
    process.exit(1)
})