const { ethers, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const LINK_TOKEN_ABI = require("@chainlink/contracts/abi/v0.4/LinkToken.json")

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

    const jobId = ethers.utils.toUtf8Bytes(networkConfig[chainId]["jobId2"])
    const fee = networkConfig[chainId]["fee"]

    const args = [process.env.ETHERSCAN_API_KEY,
        oracleAddress, 
        jobId, 
        fee, 
        linkTokenAddress  
    ]
    const walletConnector = await deploy("WalletConnector", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("-----------------------------------------------------")
    log(`WalletConnector deployed to ${walletConnector.address} on ${network.name}`)

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(walletConnector.address, args)
    }
    log("---------------------------------------------------------")

        // // auto-funding
        // const fundAmount = networkConfig[chainId]["fundAmount"]
        // await linkToken.transfer(walletConnector.address, fundAmount)
    
        // log(`WalletConnector funded with ${fundAmount} JUELS`)
}

module.exports.tags = ["all", "walletconnector"]