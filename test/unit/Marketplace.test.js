const { network, ethers, deployments } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
    ? Skip.describe
    : describe("Marketplace Unit test", function () {
          let marketplace

          const PRICE = ethers.utils.parseEther("0.1")

          beforeEach(async () => {
              player = await ethers.getSigners()
              await deployments.fixture(["all"])
              marketplace = await ethers.getContract("Marketplace")
          })

          describe("listItem", () => {
              it("reverts if enough eth not sent", async () => {
                  await expect(
                      marketplace.listItem(
                          "apple",
                          "terms",
                          PRICE,
                          "0x7465737400000000000000000000000000000000000000000000000000000000"
                      )
                  ).to.be.revertedWith("Marketplace__NotEnoughEthSent")
              })
          })
      })
