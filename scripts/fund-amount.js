const { ethers } = require("hardhat");

const amount = ethers.utils.parseEther("0.1")

async function fundAmmount() {
    const dadsAccount = await ethers.getContract("DadsAccount")
    const tx = await dadsAccount.enterFund(amount, "0")
    await tx.wait()
    const getAmount = await dadsAccount.getAmount("0")
    console.log(`Amount: ${getAmount}`)
}


  fundAmmount()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

  
