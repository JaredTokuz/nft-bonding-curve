// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { writeFileSync } from "fs";
import { ethers } from "hardhat";

async function main() {
  const BCUniversal = await ethers.getContractFactory("BondingCurveUniversal");

  // Start deployment, returning a promise that resolves to a contract object
  const bcUniversal = await BCUniversal.deploy();
  await bcUniversal.deployed();
  console.log("Contract deployed to address:", bcUniversal.address);

  const network = await ethers.provider.getNetwork();

  writeFileSync(
    `./bc-config.${network.name == "unknown" ? "local" : network.name}.${
      network.chainId
    }.ts`,
    `export const contractAddress = "${bcUniversal.address}";
export const ownerAddress = "${await bcUniversal.signer.getAddress()}";`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
