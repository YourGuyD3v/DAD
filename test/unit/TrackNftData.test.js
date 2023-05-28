const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { numToBytes32 } = require("../../helper-functions")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { expect } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("TrackNFTData unit testing", function () {
      ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)
      let trackNftData, deployer

      async function deployTrackNftDataFixture() {
        const [deployer] = await ethers.getSigners()

        const chainId = network.config.chainId

        const linkTokenFactory = await ethers.getContractFactory("LinkToken")
        const linkToken = await linkTokenFactory.connect(deployer).deploy()

        const mockOracleFactory = await ethers.getContractFactory("MockOracle")
        const mockOracle = await mockOracleFactory.connect(deployer).deploy(linkToken.address)

        const jobId = ethers.utils.toUtf8Bytes(networkConfig[chainId]["jobId"])
        const fee = networkConfig[chainId]["fee"]

        const trackNftDataFactory = await ethers.getContractFactory("TrackNFTData")
        trackNftData = await trackNftDataFactory
            .connect(deployer)
            .deploy(linkToken.address)

        const fundAmount = networkConfig[chainId]["fundAmount"] || "1000000000000000000"
        await linkToken.connect(deployer).transfer(trackNftData.address, fundAmount)

        return { trackNftData, mockOracle }
    }

    describe("requestNftData", () => {
      it("Should successfully make an API request", async () => {
        const { trackNftData } = await loadFixture(deployTrackNftDataFixture)
        const nftDataTx = await trackNftData.requestNftData()
        const nftDataReceipt = await nftDataTx.wait(1)
        const requestId = transactionReceipt.events[0].topics[1]
        expect(requestId).to.not.be.null
        console.log(nftDataReceipt.toString())
      })
    })
  })
