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
        linkToken = new ethers.Contract(linkTokenAddress, LINK_TOKEN_ABI, deployer)
    }

    const jobId = ethers.utils.toUtf8Bytes(networkConfig[chainId]["jobId"])
    const fee = networkConfig[chainId]["fee"]

    const args = [process.env.OPENSEA_APIURL,
        oracleAddress, 
        jobId, 
        fee, 
        linkTokenAddress  
    ]
    
    const trackNftData = await deploy("TrackNFTData", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("-----------------------------------------------------")

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(trackNftData.address, args)
    }
    log("---------------------------------------------------------")

    // auto-funding
    const fundAmount = networkConfig[chainId]["fundAmount"]
    await linkToken.transfer(trackNftData.address, fundAmount)
        
    log(`WalletConnector funded with ${fundAmount} JUELS`)
}

module.exports.tags = ["all", "trackNftData"]