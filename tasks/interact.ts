import { task } from "hardhat/config";

/*
import KeyringABI from "../abi/Keyring.json";
import deployments from "../deployments/addresses.json";

import { Keyring } from "../src/types/Keyring";
import { Keyring__factory } from "../src/types/factories/Keyring__factory";

task("interact", "Interact with a deployed contract", async (_taskArgs, hre) => {
  const provider = hre.ethers.getDefaultProvider("rinkeby");
  const mnemonic: string = process.env.MNEMONIC || "";
  const wallet =  hre.ethers.Wallet.fromMnemonic(mnemonic);
  const signer = wallet.connect(provider);

  const keyringFactory: Keyring__factory = <Keyring__factory>await hre.ethers.getContractFactory("Keyring");
  const keyring: Keyring = <Keyring>await keyringFactory.attach(deployments.addresses.Keyring);
  const keyringContract = keyring.connect(signer)

  console.log( await keyringContract.revoke("0x35d389B751943Cbf3fE3620a668566E97D5f0144") );
  console.log( await keyringContract.refresh(await wallet.getAddress()) );
});
*/
