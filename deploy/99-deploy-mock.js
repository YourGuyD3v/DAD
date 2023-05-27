const { network } = require("hardhat")

const setLink = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
const setOrcals = "0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD"

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    chainId = network.config.chainId

    arguments = [
        setLink,
        setOrcals
    ]

    const linkToken = await deploy("LinkToken", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("------------------------------------------------------------")
    const chainlinkClientTestHelper = await deploy("ChainlinkClientTestHelper", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("--------------------------------------------------------")
    const mockOracle = await deploy("MockOracle", {
        from: deployer,
        args: ["0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD"],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("---------------------------------------------------------")
}

module.exports.tags = ["all", "mock"]