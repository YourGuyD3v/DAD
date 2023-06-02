const { ethers, network } = require("hardhat")
const fs = require("fs")

const frontendContractFile = "../softrock-front-end/constants/networkMapping.json"
const frontendAbiLocation = "../hackathon-project/softrock-front-end/constants"
module.exports = async function () {
    if(process.env.UPDATED_FRONT_END) {
        console.log("Updating frontend...")
        await updateContractAddresses()
        await updateContractAbi()
    }
}
    async function updateContractAbi() {
        const walletConnector = await ethers.getContract("WalletConnector")
        fs.writeFileSync(`${frontendAbiLocation}WalletConnector.json`,
        walletConnector.interface.format(ethers.utils.FormatTypes.json))

        const basicNft = await ethers.getContract("BasicNft")
        // fs.writeFileSync(`${frontendAbiLocation}BasicNft.json`,
        // basicNft.interface.format(ethers.utils.FormatTypes.json))
    }

    async function updateContractAddresses() {
        const walletConnector = await ethers.getContract("WalletConnector")
        const chainId = network.config.chainId.toString()
        const contractAddresses = JSON.parse(fs.readFileSync(frontendContractFile, "utf8"))
        if (chainId in contractAddresses) {
            if (!contractAddresses[chainId]["WalletConnector"].includes(walletConnector.address)) {
                contractAddresses[chainId]["walletConnector"].push(walletConnector.address)
            }
            } else {
                contractAddresses[chainId] = {"WalletConnector": [walletConnector.address]}
        }
        fs.writeFileSync(frontendContractFile, JSON.stringify(contractAddresses))
    }

    // module.exports.tags = ["all", "frontend"]