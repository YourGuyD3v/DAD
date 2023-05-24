const { ethers } = require("hardhat")

async function fetchTradeData() {
    const trade = await ethers.getContract("Trades")
    const call = await trade.requestMultipleParameters()
    const callResponse = await call.wait(1)
    const tx1 = await trade.getEthData()
    const tx0 = await trade.getBtcData()
    console.log(`BTC Symbol: ${tx0}`)
    console.log(`ETH Symbol: ${tx1}`)
    console.log(callResponse)
}

fetchTradeData()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error)
    process.exit(1)
})