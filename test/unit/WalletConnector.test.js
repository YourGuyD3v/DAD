const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config.js");
const { numToBytes32 } = require("../../helper-functions")
const { expect, assert } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("WalletConnector unit testing", function () {
      let walletConnector, accounts, deployer, linkToken, mockOracle

      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer
        accounts = await ethers.getSigners()
        await deployments.fixture(["all"])
        walletConnector = await ethers.getContract("WalletConnector", deployer)
        linkToken = await ethers.getContract("LinkToken", deployer)
        mockOracle = await ethers.getContract("MockOracle", deployer)
        const fundAmount = networkConfig[chainId]["fundAmount"] || "1000000000000000000"
        await linkToken.transfer(walletConnector.address, fundAmount)
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
        })
      })

      describe("requestTransactionsData", () => {
        it("Should successfully make an API request", async () => {
          const tranactionTx = await walletConnector.requestTransactionsData()
          const transactionReceipt = await tranactionTx.wait(1)
          const requestId = transactionReceipt.events[0].topics[1]
          const nonce = transactionReceipt.events[1].topics[1]
          const transactionCount = transactionReceipt.events[2].topics[1]
          const transactionHash = transactionReceipt.events[3].topics[1]
          const blockHash = transactionReceipt.events[0].topics[2]
          const blockHeight = transactionReceipt.events[1].topics[2]
          const time = transactionReceipt.events[2].topics[2]
          // const to = transactionReceipt.events[9].topics[0]
          expect(requestId).to.not.be.null
          expect(nonce).to.not.be.null
          expect(transactionCount).to.not.be.null
          expect(transactionHash).to.not.be.null
          expect(blockHash).to.not.be.null
          expect(blockHeight).to.not.be.null
          expect(time).to.not.be.null
          // expect(to).to.not.be.null

          console.log(nonce.toString())
        })
      })

      it('should request and fulfill transaction data', async () => {
        // Connect the wallet
        await walletConnector.connectWallet()
    
        // Request transaction data
        const requestTransactionsDataTx = await walletConnector.requestTransactionsData()
        await requestTransactionsDataTx.wait()
    
        // Retrieve the transaction details
        const transactionDetails = await walletConnector.getTransactionDetailsByAddress()
    
        // Assert the transaction details
        expect(transactionDetails.nonce).to.exist
        expect(transactionDetails.transactionCount).to.exist
        expect(transactionDetails.transactionHash).to.exist
        expect(transactionDetails.blockHash).to.exist
        expect(transactionDetails.blockHeight).to.exist
        expect(transactionDetails.time).to.exist
        expect(transactionDetails.transactionIndex).to.exist
        expect(transactionDetails.from).to.exist
        expect(transactionDetails.to).to.exist
        expect(transactionDetails.value).to.exist
        expect(transactionDetails.gas).to.exist
        expect(transactionDetails.gasPrice).to.exist
        expect(transactionDetails.transactionInputData).to.exist

      })
      
      
      
    })

