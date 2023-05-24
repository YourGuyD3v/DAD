const { ethers } = require("hardhat")

async function fetchWalletdata() {
    const transactionData = await ethers.getContract("TransactionData")
    const tx = await transactionData.fetchWalletData()
    const txResponse = await tx.wait(1)
    console.log(tx)
    const getWalletData = transactionData.getWalletTransactions()
    console.log(`Data: ${getWalletData}`)
    const requestId = await transactionData.getLastRequestId()
    console.log(`Request ID: ${requestId}`)
}

fetchWalletdata()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error)
    process.exit(1)
})