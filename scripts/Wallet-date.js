const { ethers } = require("hardhat");

async function walletData() {
  const transactionData = await ethers.getContract("TransactionData");
  const call = await transactionData.fetchWalletData()
  const callResponse = await call.wait(1)
  const txPromise = transactionData.getWalletData(); // Returns a promise

  // Wait for the transaction promise to resolve
  const tx = await txPromise;

  // Assuming `tx` is an array of transaction objects
  for (let i = 0; i < tx.length; i++) {
    const transaction = tx[i];
    console.log("Sender:", transaction.sender);
    console.log("Receiver:", transaction.receiver);
    console.log("Balance:", transaction.balance);
    console.log("Timestamp:", transaction.timeStamp);
    console.log("-------------------");
  }
  console.log(`response: ${tx}`)
  console.log(callResponse)
}

walletData()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  

