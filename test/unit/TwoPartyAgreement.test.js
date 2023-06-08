const { network, ethers, deployments } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("TwoPartyAgreement unit testing", function () {
      let twoPartyAgreement, twoPartyAgreementContract, vrfCoordinatorV2Mock, player, generatedId

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
        await twoPartyAgreement.requestAgreementId()
        generatedId = await twoPartyAgreement.generatedId()
      })

      describe("constructor", () => {
        it("should initialize contract variables correctly", async () => {
          
          // Verify the initialization of contract variables
          assert.equal(await twoPartyAgreement.getCallbackGasLimit(), networkConfig[chainId]["callbackGasLimit"])
        })
      })

      describe("createAgreement", () => {
        it("reverts when invalid generatedId, and invalid year,date passed to the function", async () => {
          await expect (twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, invalidDeliveryDate, generatedId )).to.be.revertedWith(
            "TwoPartyAgreement__InvalidDeliveryDateOrGeneratedId")
            await expect (twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, "1234" )).to.be.revertedWith(
              "TwoPartyAgreement__InvalidDeliveryDateOrGeneratedId")
          })

        it("emits the event and stores the agreementId", async () => {
          await expect (twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId )).to.emit(
            twoPartyAgreement, "AgreementCreated"
          )

          const id = await twoPartyAgreement.getAgreementId()

          assert.equal(id.toString(), generatedId.toString())
          
        })
      })

      describe("fulfillRandomWords", () => {
      it("should call fulfillRandomWords with a valid requestId", async () => {
        await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId);
        const tx = await twoPartyAgreement.requestAgreementId();
        assert.exists(tx, "Transaction should exist");
      })
      
      it("should return random agreement ID", async () => {
        await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
        const tx = await twoPartyAgreement.requestAgreementId()
        const id = await twoPartyAgreement.getAgreementId()
        expect(id).to.equal(generatedId)
      })

    })

      describe("confirmDelivery", () => {
        it('should set the agreement status to Completed', async function () {
          await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
          const id = await twoPartyAgreement.getAgreementId()
          await twoPartyAgreement.confirmDelivery(id)
          const agreementStatus = await twoPartyAgreement.getAgreementStatus(id)
          assert.equal(agreementStatus, 1)
        })

        it("reverts if agreement is not in progress", async () => {
          const id = await twoPartyAgreement.getAgreementId()
          await expect( twoPartyAgreement.confirmDelivery(id)).to.be.revertedWith(
            "TwoPartyAgreement__NotTheBuyer"
          )
        })

          it("emits event on confirming the Delivery", async () => {
            await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
            const id = await twoPartyAgreement.getAgreementId()
            expect ( await twoPartyAgreement.confirmDelivery(id)).to.emit(
              twoPartyAgreement, "AgreementCompleted"
            ).withArgs(generatedId)
        })
      })

      describe("cancelAgreementByBuyer", () => {
        it("reverts if agreement status is Completed", async () => {
          const tx = await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
          const id = await twoPartyAgreement.getAgreementId()
          const confirmDelivery = await twoPartyAgreement.confirmDelivery(id)
          await expect ( twoPartyAgreement.cancelAgreementByBuyer(id)).to.be.revertedWith(
            "TwoPartyAgreement__YouCantCancelTheAgreement"
          )
          
        })
          it("should delete the agreement and emits the event", async () => {
            const tx = await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
            const id = await twoPartyAgreement.getAgreementId()
            expect (await twoPartyAgreement.cancelAgreementByBuyer(id)).to.emit(
              twoPartyAgreement, "AgreementCancelledAndDelete"
            ).withArgs(generatedId)
            const agreementStatus = await twoPartyAgreement.getAgreementStatus(id)
            assert.equal(agreementStatus, 0)
          })
      })

      describe("cancelAgreementBySeller", () => {
        it("reverts if agreement status is Completed", async () => {
          const tx = await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
          const id = await twoPartyAgreement.getAgreementId()
          const confirmDelivery = await twoPartyAgreement.confirmDelivery(id)
          const connect = await twoPartyAgreement.connect(seller)
          await expect ( connect.cancelAgreementBySeller(id)).to.be.revertedWith(
            "TwoPartyAgreement__youCantCancelTheAgreement"
          )
          
        })
          it("should delete the agreement and emits the event", async () => {
            const tx = await twoPartyAgreement.createAgreement("apple", terms, seller.address, Price, validDeliveryDate, generatedId)
            const id = await twoPartyAgreement.getAgreementId()
            const connect = await twoPartyAgreement.connect(seller)
            expect (await connect.cancelAgreementBySeller(id)).to.emit(
              twoPartyAgreement, "AgreementCancelledAndDelete"
            ).withArgs(generatedId)
            const agreementStatus = await twoPartyAgreement.getAgreementStatus(id)
            assert.equal(agreementStatus, 0)
          })
      })
  })
