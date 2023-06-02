const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config");
const { assert, expect } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("TwoPartyAgreement unit testing", function () {
      ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)
      let twoPartyAgreement, twoPartyAgreementContract, vrfCoordinatorV2Mock, deployer, player

      const Price = ethers.utils.parseEther("0.1")
      const invalidDeliveryDate = Math.floor(Date.now() / 1000) - 3600;
      const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600;
      const terms = ethers.utils.formatBytes32String("term")

      beforeEach(async () => {
        accounts = await ethers.getSigners()
        player = accounts[1]
        await deployments.fixture(["all"])
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        twoPartyAgreementContract = await ethers.getContract("TwoPartyAgreement")
        twoPartyAgreement = twoPartyAgreementContract.connect(player)
      })


      describe("constructor", () => {
        it("initializes the TwoPartyAgreement correctly", async () => {
          const interval = await twoPartyAgreement.getInterval()
          expect(interval.toString() == networkConfig[chainId]["automationUpdateInterval"])
        })
      })

      describe("createAgreement", () => {
        it("reverts when invalid address, and invalid year,date passed to the function", async () => {
          await expect (twoPartyAgreement.createAgreement(terms, player.address, Price, invalidDeliveryDate )).to.be.revertedWith(
            "TwoPartyAgreement__InvalidDeliveryDate")

        it("emits the event and stores the agreementId", async () => {
          await expect (twoPartyAgreement.createAgreement(terms, player.address, Price, invalidDeliveryDate )).to.emit(
            "AgreementCreated"
          )

          const agreementId = await twoPartyAgreement.getAgreementId()

          assert.notEqual(agreementId, 0, 'AgreementId should not be zero')
          console.log(agreementId.toString())
            })
        })
      })
  })
