import * as fs from "fs";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";

import { chainIds } from "../constants";

import { Keyring } from "../src/types/Keyring";
import { Keyring__factory } from "../src/types/factories/Keyring__factory";

task("deploy", "Deploys the core contracts", async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
  const keyringFactory: Keyring__factory = <Keyring__factory>await hre.ethers.getContractFactory("Keyring");
  const keyring: Keyring = <Keyring>await keyringFactory.deploy(
    "0x01BE23585060835E02B77ef475b0Cc51aA1e0709", // LINK address
    "0xE70C82f0BDC27170767693b9AD4C0B7E4193A7eA", // Oracle
    hre.ethers.utils.formatBytes32String(""), // job ID
    hre.ethers.utils.parseUnits("0.1", 18), // fee in LINK
    0, // validity time
  );
  await keyring.deployed();
  console.log("Keyring deployed to: ", keyring.address);

  const addresses = {
    name: "Deployed Contracts",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
    chainId: chainIds[hre.network.name],
    addresses: {
      Keyring: keyring.address,
    },
  };
  const str = JSON.stringify(addresses, null, 4);
  fs.writeFileSync("deployments/addresses.json", str, "utf8");
});
