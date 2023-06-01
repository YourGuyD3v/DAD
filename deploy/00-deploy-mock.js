const { network } = require("hardhat")

BASE_FEE = "250000000000000000" // 0.25;
GAS_PRICE_LINK = 1e9 // link per gas;

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    chainId = network.config.chainId

    arguments = [
        BASE_FEE,
        GAS_PRICE_LINK
    ]

    const linkToken = await deploy("LinkToken", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("------------------------------------------------------------")
    const vrfCoordinatorV2Mock = await deploy("VRFCoordinatorV2Mock", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("--------------------------------------------------------")
    const mockOracle = await deploy("MockOracle", {
        from: deployer,
        args: [linkToken.address],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("---------------------------------------------------------")
}

module.exports.tags = ["all", "mocks"]