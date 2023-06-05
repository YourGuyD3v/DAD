const { ethers } = require("hardhat");

const Price = ethers.utils.parseEther("0.1")
const validDeliveryDate = Math.floor(Date.now() / 1000) + 3600;

async function createAgreement() {
    const twoPartyAgreement = await ethers.getContract("TwoPartyAgreement")
    const tx = await twoPartyAgreement.createAgreement("i'm your daddy!", "0x9F6713Aac16Ca947E37c5d5512090E0195c30EF9", Price, validDeliveryDate )
    await tx.wait(1)
    const agreementId = await twoPartyAgreement.getAgreementId()
    const terms = await twoPartyAgreement.getTerms(agreementId)
    console.log(`Terms: ${terms}`)
    console.log(`Agreement ID: ${agreementId}`)
    const tx2 = await twoPartyAgreement.createAgreement("call me daddy!", "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", Price, validDeliveryDate )
    await tx2.wait(1)
    const getAgreementId = await twoPartyAgreement.getAgreementId()
    const termtx = await twoPartyAgreement.getTerms(getAgreementId)
    const sellerAddress = await twoPartyAgreement.getSellerById(getAgreementId)
    console.log(`Terms: ${termtx}`)
    console.log(`Agreement ID: ${getAgreementId}`)
    console.log(`seller address: ${sellerAddress}`)
    const tx3 = await twoPartyAgreement.createAgreement("call me papa!", "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", Price, validDeliveryDate )
    await tx3.wait(1)
    const agreementIdx = await twoPartyAgreement.getAgreementId()
    const termtxx = await twoPartyAgreement.getTerms(agreementIdx)
    const sellerAddressx = await twoPartyAgreement.getSellerById(agreementIdx)
    console.log(`Terms: ${termtxx}`)
    console.log(`Agreement ID: ${getAgreementId}`)
    console.log(`seller address: ${sellerAddressx}`)

}


    createAgreement()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  
