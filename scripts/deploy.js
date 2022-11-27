const hre = require("hardhat");

const {
  getEstimatedTxGasCost,
  getActualTxGasCost,
  chainNameById,
  chainIdByName,
  saveDeploymentData,
  getContractAbi,
} = require("./helpers/utils");

async function main() {
  const { ethers, getNamedAccounts } = hre;
  const { owner } = await getNamedAccounts();
  const network = await hre.network;
  const deployData = {};

  const chainId = chainIdByName(network.name);

  const demoBaseUri = "QmQc5pWZCzMGBu4Kiz66UCZgjqpXEdfgJ671BjHAeCWq3u";
  const demoMaxSupply = "50";

  console.log("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  console.log(" Contract Deployment");
  console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

  console.log(`  Using Network: ${chainNameById(chainId)} (${network.name}:${chainId})`);
  console.log("  Using Owner:  ", owner);
  console.log(" ");

  console.log("\nDeploying...");
  console.log("~~~~~~~~~~~~~~~~~");
  const constructorArgs = [      
  "Faces demo collection",
  "RYAN",
  demoBaseUri,
  demoMaxSupply,
  26000000
  ];
  const DemoNFT = await ethers.getContractFactory("FreeContract");
  const DemoNFTInstance = await DemoNFT.deploy(...constructorArgs);
  const demoNFT = await DemoNFTInstance.deployed();
  deployData['FreeContract'] = {
    abi: getContractAbi('FreeContract'),
    address: demoNFT.address,
    deployTransaction: demoNFT.deployTransaction,
    constructorArgs,
  }
  saveDeploymentData(chainId, deployData);
  console.log("  - DemoNFT: ", demoNFT.address);
  console.log("     - Gas Cost:   ", getEstimatedTxGasCost({ deployTransaction: demoNFT.deployTransaction }));
  console.log("     - Get numbers minted:   ", await demoNFT.GetNumMinted());
  console.log("\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  console.log("\n  Contract Deployment Complete.");
  console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
