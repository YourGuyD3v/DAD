const { network, ethers, getNamedAccounts, deployments } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config.js");
const { assert, expect } = require("chai");

!developmentChains.includes(network.name)
  ? Skip.describe
  : describe("WalletConnector unit testing", function () {
      let walletConnector, accounts, deployer;

      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer;
        accounts = await ethers.getSigners();
        player = accounts[1];
        await deployments.fixture(["all"]);
        walletConnector = await ethers.getContract("WalletConnector");
      });

      describe("connectWallet", () => {
        it("should connect the wallet and return the correct account info", async () => {
          await walletConnector.connectWallet();
          const accountInfo = await walletConnector.getAccountInfo(deployer);
          assert.equal(accountInfo.connectorAddress, deployer);
        });
      }); 
      });
