const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.export = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    chainId = network.config.chainId

    args = []
    const walletConnector = await deploy("WAlletConnector", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations
    })

    log("-----------------------------------------------------")

    if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(walletConnector.address, args)
    }
    log("---------------------------------------------------------")
}

module.exports.tags = ["all", "walletconnector"]