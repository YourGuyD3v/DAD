const { ethers } = require("hardhat")

async function fetchTransactionData() {
  const trades = await ethers.getContract("Trades")

  const requestTradeDataPromise = new Promise((resolve, reject) => {
    trades.requestVolumeData()
      .then((requestTradeDataTx) => {
        resolve(requestTradeDataTx)
      })
      .catch((error) => {
        reject(error)
      })
  })

  const requestTradeDataTx = await requestTradeDataPromise
  await requestTradeDataTx.wait(1)
  console.log(requestTradeDataTx)

  const name = await trades.getCryptoName()
  const quotes = await trades.getCryptoQoutes()
  console.log(`Name: ${name}`)
  console.log(`Quotes: ${quotes}`)

}

fetchTransactionData()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
