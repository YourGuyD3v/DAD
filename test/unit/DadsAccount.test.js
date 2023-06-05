const { network, ethers, deployments } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("DadsAccount unit testing", function () {
      let twoPartyAgreement, dadsAccount, twoPartyAgreementContract, vrfCoordinatorV2Mock, player

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
      })

      describe("constructor", () => {
        it("should initialize contract variables correctly", async () => {
          
          // Verify the initialization of contract variables
          assert.equal(await twoPartyAgreement.getCallbackGasLimit(), networkConfig[chainId]["callbackGasLimit"])
        })
      })

      describe("enterFund", () => {
        it("reverts if unique ID is inavlid, agreement ID is invalid and amount is less then zero", async () => {
          const agreementId = await twoPartyAgreement.getAgreementId()
          const tx = await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
          uniqueId = "abcdef"
          const uniqueIdCreated = await twoPartyAgreement.setUniqueIdForRole(seller.address, agreementId, uniqueId)
          expect (await dadsAccount.enterFund(0, uniqueId, agreementId)).to.be.revertedWith(
            "DadsAccount__InvalidAmountOrPasOrAgreementId"
          )
        })
      })
        it("accepts the funds from buyer", async () => {
          const agreementId = await twoPartyAgreement.getAgreementId()
          const tx = await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
          uniqueId = "abcdef"
          const uniqueIdCreated = await twoPartyAgreement.setUniqueIdForRole(seller.address, agreementId, uniqueId)
          const funded = await dadsAccount.enterFund(Price, uniqueId, agreementId)
          assert(funded)
      })

  })
