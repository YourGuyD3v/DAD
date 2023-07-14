const { network } = require("hardhat");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");
const {verify} = require("../utils/verify")

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts();
    chainId = network.config.chainId

    arguments = [
        networkConfig[chainId]["listingPrice"]
    ]

    const marketplace = await deploy("Marketplace", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY)
    {
        log("Verifying...")
        await verify(marketplace.address, this.arguments);
    }
}

module.exports.tags = ["all", "marketplace"]