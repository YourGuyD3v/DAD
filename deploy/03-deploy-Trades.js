const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    let linkToken, mockOracle, linkTokenAddress, oracleAddress

    if (chainId == 31337) {
        linkToken = await ethers.getContract("LinkToken")
        linkTokenAddress = linkToken.address

        mockOracle = await ethers.getContract("MockOracle")
        oracleAddress = mockOracle.address
    } else {
        oracleAddress = networkConfig[chainId]["oracle"]
        linkTokenAddress = networkConfig[chainId]["linkToken"]
        // linkToken = new ethers.Contract(linkTokenAddress, LINK_TOKEN_ABI, deployer)
    }

    const jobId = ethers.utils.toUtf8Bytes(networkConfig[chainId]["jobId"])
    const fee = networkConfig[chainId]["fee"]

    const args = [process.env.TRADE_API_URL,
        oracleAddress, 
        jobId, 
        fee, 
        linkTokenAddress  
    ]
    const trades = await deploy("Trades", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("----------------------------------")
    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(trades.address, args)
    }
    log("---------------------------------------------------------")
}

module.exports.tags = ["all", "trades"]