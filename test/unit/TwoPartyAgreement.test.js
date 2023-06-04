const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config");
const { assert, expect, AssertionError } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("TwoPartyAgreement unit testing", function () {
      ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)
      let twoPartyAgreement, twoPartyAgreementContract, vrfCoordinatorV2Mock, player, interval

      const Price = ethers.utils.parseEther("0.1")
      const invalidDeliveryDate = Math.floor(Date.now() / 1000) - 3600;
      const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600;
      const terms = ethers.utils.formatBytes32String("term")

      beforeEach(async () => {
        [buyer, seller] = await ethers.getSigners()
        await deployments.fixture(["all"])
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        twoPartyAgreementContract = await ethers.getContract("TwoPartyAgreement")
        twoPartyAgreement = twoPartyAgreementContract.connect(seller)
        interval = await twoPartyAgreement.getInterval()
      })
      console.log(interval)


      describe("constructor", () => {
        it("initializes the TwoPartyAgreement correctly", async () => {
          assert.equal(interval.toString(), networkConfig[chainId]["automationUpdateInterval"])
        })
      })

      describe("createAgreement", () => {
        it("reverts when invalid address, and invalid year,date passed to the function", async () => {
          await expect (twoPartyAgreement.createAgreement(terms, seller.address, Price, invalidDeliveryDate )).to.be.revertedWith(
            "TwoPartyAgreement__InvalidDeliveryDate")
          })
        it("emits the event and stores the agreementId", async () => {
          await expect (twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate )).to.emit(
            twoPartyAgreement, "AgreementCreated"
          )

          const agreementId = await twoPartyAgreement.getAgreementId()

          assert.notEqual(agreementId, 0, 'AgreementId should not be zero')
          
        })
      })

      describe("checkUpkeep", () => {
        it("should return true if upkeep is needed", async () => {
          await network.provider.send("evm_increaseTime", [interval.toNumber() + 12])
          await network.provider.request({ method: "evm_mine", params: [] })
          const {upkeepNeeded} = await twoPartyAgreement.callStatic.checkUpkeep("0x")

          expect(upkeepNeeded).to.be.true
        })
      })
  })
