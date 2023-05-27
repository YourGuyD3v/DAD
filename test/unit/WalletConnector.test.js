const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config.js");
const { numToBytes32 } = require("../../helper-functions")
const { expect } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("WalletConnector unit testing", function () {
      ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)
      let walletConnector, accounts, deployer

      async function deployAPIConsumerFixture() {
        const [deployer] = await ethers.getSigners()

        const chainId = network.config.chainId

        const linkTokenFactory = await ethers.getContractFactory("LinkToken")
        const linkToken = await linkTokenFactory.connect(deployer).deploy()

        const mockOracleFactory = await ethers.getContractFactory("MockOracle")
        const mockOracle = await mockOracleFactory.connect(deployer).deploy(linkToken.address)

        const jobId = ethers.utils.toUtf8Bytes(networkConfig[chainId]["jobId"])
        const fee = networkConfig[chainId]["fee"]

        const walletConnectorFactory = await ethers.getContractFactory("WalletConnector")
        walletConnector = await apiConsumerFactory
            .connect(deployer)
            .deploy(mockOracle.address, jobId, fee, linkToken.address)

        const fundAmount = networkConfig[chainId]["fundAmount"] || "1000000000000000000"
        await linkToken.connect(deployer).transfer(apiConsumer.address, fundAmount)

        return { walletConnector, mockOracle }
    }

      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer
        accounts = await ethers.getSigners()
        await deployments.fixture(["all"])
        walletConnector = await ethers.getContract("WalletConnector", deployer)
      })

      // describe("constructor", () => {
      //   it("should set the correct apiurl", async () => {
      //     const apiurl = await walletConnector.i_transactionApiUrl();
      //     console.log(apiurl)
      //   })
      // })

      describe("connectWallet", () => {
        it("should connect the wallet. emits the events and return the correct account info", async () => {
          await walletConnector.connectWallet()
          const accountInfo = await walletConnector.getAccountInfo(deployer)
          expect(accountInfo.connectorAddress == deployer)
          expect(accountInfo.currentBalance.toString()).to.be.string
          expect(await walletConnector.connectWallet()).to.emit("WalletConnected")
          console.log(deployer)
        })
      })

      describe("fetchTransactionsData", () => {
        it("should fetch the tranaction data", async () => {
          const tranactionData = await walletConnector.fetchTransactionsData()
          console.log(tranactionData.toString())
        })
      })
    })
