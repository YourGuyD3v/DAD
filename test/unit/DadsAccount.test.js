const { network, ethers, deployments, getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("DadsAccount unit testing", function () {
      let twoPartyAgreement, dadsAccount, twoPartyAgreementContract, vrfCoordinatorV2Mock, seller, buyer, id

      const Price = ethers.utils.parseEther("0.1")
      const invalidDeliveryDate = Math.floor(Date.now() / 1000) - 3600
      const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600
      const terms = ethers.utils.formatBytes32String("term")

      beforeEach(async () => {
        [buyer, seller, player] = await ethers.getSigners()
        await deployments.fixture(["all"])
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        twoPartyAgreementContract = await ethers.getContract("TwoPartyAgreement")
        dadsAccount = await ethers.getContract("DadsAccount")
        twoPartyAgreement = twoPartyAgreementContract.connect(seller)
        await twoPartyAgreement.requestAgreementId()
        generatedId = await twoPartyAgreement.generatedId()
        await twoPartyAgreement.createAgreement("apple" ,terms, seller.address, Price, validDeliveryDate, generatedId)
      })

      describe("constructor", () => {
        it("should initialize contract variables correctly", async () => {
          
          // Verify the initialization of contract variables
          assert.equal(await twoPartyAgreement.getCallbackGasLimit(), networkConfig[chainId]["callbackGasLimit"])
        })
      }) 

      describe("enterFund", () => {
        it("reverts if unique ID is inavlid, amount is not equal to price enter at the time of agreement", async () => {
          await expect (dadsAccount.enterFunds(0, generatedId)).to.be.revertedWith(
            "DadsAccount__InvalidAmount"
          )
        })
        it("accepts the funds from buyer", async () => {
          const funded = await dadsAccount.enterFunds(Price, generatedId)
          const balance = await dadsAccount.getAmount(generatedId)
          assert.equal(balance.toString(), Price.toString())
        })
    })

    describe("fundRelease", () => {
      it("release the funds", async () => {
        const funded = await dadsAccount.enterFunds(Price, generatedId)
        const balance = await dadsAccount.getAmount(generatedId)
        const tx = await dadsAccount.connect(player)
        const withdraw = await tx.fundWithdraw(generatedId)
        const currectBalance = await tx.getAmount(generatedId)
        assert.equal(balance.toString(), "0")

      })

      it("Only seller can realse the fund", async () => {
        const funded = await dadsAccount.enterFunds(Price, generatedId)
        const balance = await dadsAccount.getAmount(generatedId)
        const tx = await dadsAccount.connect(player)
        const withdraw = await tx.fundWithdraw(generatedId)
        const currectBalance = await tx.getAmount(generatedId)
        assert.notEqual(currectBalance.toString(), "0")
      })
    })

    describe("moneyReturned", () => {
      it("return money on the cancelation of agreement", async () => {
        const funded = await dadsAccount.enterFunds(Price, generatedId)
        const balance = await dadsAccount.getAmount(generatedId)
        const cancled = await twoPartyAgreement.cancelAgreement(generatedId)
        const moneyReturned = await dadsAccount.fundReturned()
        const currectBalance = await dadsAccount.getAmount(generatedId)
        assert.equal(currectBalance.toString(), "0")
      })
    })

  })
