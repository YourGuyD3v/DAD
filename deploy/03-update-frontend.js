const {
    frontEndContractsFile,
    frontEndAbiLocation,
} = require("../helper-hardhat-config")
require("dotenv").config()
const fs = require("fs")
const { network } = require("hardhat")

module.exports = async () => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        await updateAbi()
        await updateContractAddresses()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    const twoPartyAgreement = await ethers.getContract("TwoPartyAgreement")
    fs.writeFileSync(
        `${frontEndAbiLocation}TwoPartyAgreement.json`,
        twoPartyAgreement.interface.format(ethers.utils.FormatTypes.json)
    )
    // fs.writeFileSync(
    //     `${frontEndAbiLocation2}NftMarketplace.json`,
    //     nftMarketplace.interface.format(ethers.utils.FormatTypes.json)
    // )

    const dadsAccount = await ethers.getContract("DadsAccount")
    fs.writeFileSync(
        `${frontEndAbiLocation}DadsAccount.json`,
        dadsAccount.interface.format(ethers.utils.FormatTypes.json)
    )
    // fs.writeFileSync(
    //     `${frontEndAbiLocation2}BasicNft.json`,
    //     basicNft.interface.format(ethers.utils.FormatTypes.json)
    // )
}

async function updateContractAddresses() {
    const chainId = network.config.chainId.toString()
    const twoPartyAgreement = await ethers.getContract("TwoPartyAgreement")
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
    if (chainId in contractAddresses) {
        if (!contractAddresses[chainId]["TwoPartyAgreement"].includes(twoPartyAgreement.address)) {
            contractAddresses[chainId]["TwoPartyAgreement"].push(twoPartyAgreement.address)
        }
    } else {
        contractAddresses[chainId] = { TwoPartyAgreement: [twoPartyAgreement.address] }
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
    // fs.writeFileSync(frontEndContractsFile2, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]