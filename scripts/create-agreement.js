const { ethers } = require("hardhat");

const Price = ethers.utils.parseEther("0.1")
const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600;

async function createAgreement() {
    const twoPartyAgreement = await ethers.getContract("TwoPartyAgreement")
    const tx = await twoPartyAgreement.createAgreement("i'm your daddy!", "0x9F6713Aac16Ca947E37c5d5512090E0195c30EF9", Price, validDeliveryDate, "hello" )
    await tx.wait(1)
    const agreementI = await twoPartyAgreement.getAgreementId()
    const termtxx = await twoPartyAgreement.getTerms(agreementI)
    const sellerAddressx = await twoPartyAgreement.getSellerById(agreementI)
    const price = twoPartyAgreement.getPrice(agreementI)
    console.log(`Terms: ${termtxx}`)
    console.log(`Agreement ID: ${agreementI}`)
    console.log(`seller address: ${sellerAddressx}`)
    console.log(`price: ${price}`)
}


    createAgreement()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  
