const { network, ethers, deployments } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("TwoPartyAgreement unit testing", function () {
      let twoPartyAgreement, twoPartyAgreementContract, vrfCoordinatorV2Mock, player

      const Price = ethers.utils.parseEther("0.1")
      const invalidDeliveryDate = Math.floor(Date.now() / 1000) - 3600
      const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600
      const terms = ethers.utils.formatBytes32String("term")

      beforeEach(async () => {
        [buyer, seller, player] = await ethers.getSigners()
        await deployments.fixture(["all"])
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        twoPartyAgreementContract = await ethers.getContract("TwoPartyAgreement")
        twoPartyAgreement = twoPartyAgreementContract.connect(seller)
      })

      describe("constructor", () => {
        it("should initialize contract variables correctly", async () => {
          
          // Verify the initialization of contract variables
          assert.equal(await twoPartyAgreement.getCallbackGasLimit(), networkConfig[chainId]["callbackGasLimit"])
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

          assert(agreementId, 0)
          
        })
      })

      describe("checkUpkeep", () => {
        it("should return true if upkeep is needed", async () => {
          const tx = await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate )
          const {upkeepNeeded} = await twoPartyAgreement.checkUpkeep("0x")
          assert(upkeepNeeded)
        })
        
      })

        describe("performUpkeep", () => {
          it("should revert if checkupkeep is false", async function () {
            await expect(twoPartyAgreement.performUpkeep("0x")).to.be.revertedWith(
              "TwoPartyAgreement__UpkeepNotNeeded"
            )
        })  
      })

      describe("fulfillRandomWords", () => {
      it("should call fulfillRandomWords with a valid requestId", async () => {
        await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate);
        const tx = await twoPartyAgreement.performUpkeep("0x");
        assert.exists(tx, "Transaction should exist");
      })

      it("should return random agreement ID", async () => {
        await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
        const randomWords = [0]
        const tx = await twoPartyAgreement.performUpkeep("0x")
        const agreementId = await twoPartyAgreement.getAgreementId()
        expect(agreementId).to.equal(randomWords[0] % 10**18)
      })
    })

    describe("setUniqueIdForRole", () => {
      it("it creates the unique ID", async() => {
        await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
        const agreementId = await twoPartyAgreement.getAgreementId()
        uniqueId = "abcdef"
        const tx = await twoPartyAgreement.setUniqueIdForRole(seller.address, agreementId, uniqueId)
        assert(tx)
      })

      it("reverts if agreement ID is not valid and address of seller is valid", async () =>{
        await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
        const agreementId = await twoPartyAgreement.getAgreementId()
        uniqueId = "abcdef"
        await expect( twoPartyAgreement.setUniqueIdForRole(seller.address, 2, uniqueId)).to.be.revertedWith(
          "TwoPartyAgreement__InvalidAgreementIdOrHeroAddress"
        )
        await expect( twoPartyAgreement.setUniqueIdForRole("0x9F6713Aac16Ca947E37c5d5512090E0195c30EF9", agreementId, uniqueId)).to.be.revertedWith(
          "TwoPartyAgreement__InvalidAgreementIdOrHeroAddress"
        )

        it("reverts if agreement is not in progress", async () => {
          const agreementId = await twoPartyAgreement.getAgreementId()
          uniqueId = "abcdef"
          await expect( twoPartyAgreement.setUniqueIdForRole(seller.address, agreementId, uniqueId)).to.be.revertedWith(
            "TwoPartyAgreement__AgreementIsNotCreatedYet"
          )
        })
      })
    })

      describe("confirmDelivery", () => {
        it('should set the agreement status to Completed', async function () {
          const agreementId = await twoPartyAgreement.getAgreementId()
          await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
          await twoPartyAgreement.confirmDelivery(agreementId)
          const agreementStatus = await twoPartyAgreement.getAgreementStatus(agreementId)
          assert.equal(agreementStatus, 1)
        })

        it("reverts if agreement is not in progress", async () => {
          const agreementId = await twoPartyAgreement.getAgreementId()
          await expect( twoPartyAgreement.confirmDelivery(agreementId)).to.be.revertedWith(
            "TwoPartyAgreement__NotTheBuyer"
          )
        })

          it("emits event on confirming the Delivery", async () => {
            const agreementId = await twoPartyAgreement.getAgreementId()
            await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
            expect ( await twoPartyAgreement.confirmDelivery(agreementId)).to.emit(
              twoPartyAgreement, "AgreementCompleted"
            ).withArgs(agreementId)
        })
      })

      describe("cancelAgreement", () => {
        it("reverts if agreement status is not Completed", async () => {
          const agreementId = await twoPartyAgreement.getAgreementId()
          const tx = await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
          const confirmDelivery = await twoPartyAgreement.confirmDelivery(agreementId)
          await expect ( twoPartyAgreement.cancelAgreement(agreementId)).to.be.revertedWith(
            "TwoPartyAgreement__YouCantCancelTheAgreement"
          )
          
        })
          it("should delete the agreement and emits the event", async () => {
            const agreementId = await twoPartyAgreement.getAgreementId()
            const tx = await twoPartyAgreement.createAgreement(terms, seller.address, Price, validDeliveryDate)
            expect (await twoPartyAgreement.cancelAgreement(agreementId)).to.emit(
              twoPartyAgreement, "AgreementCancelledAndDelete"
            ).withArgs(agreementId)
            const agreementStatus = await twoPartyAgreement.getAgreementStatus(agreementId)
            assert.equal(agreementStatus, 0)
          })
      })
  })
