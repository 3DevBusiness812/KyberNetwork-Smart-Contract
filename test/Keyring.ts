import { artifacts, ethers, waffle } from "hardhat";
import type { Artifact } from "hardhat/types";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import type { LinkTokenMock } from "../src/types/LinkTokenMock";
import type { ChainlinkOracleMock } from "../src/types/ChainlinkOracleMock";
import type { Keyring } from "../src/types/Keyring";

import { Signers } from "./types";
import { keyringUnitTests } from "./Keyring.behavior";

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.admin = signers[0];
  });

  describe("Keyring", function () {
    beforeEach(async function () {
      const linkArtifact: Artifact = await artifacts.readArtifact("LinkTokenMock");
      this.link = <LinkTokenMock>(
        await waffle.deployContract(this.signers.admin, linkArtifact, [this.signers.admin.address])
      );

      const oracleArtifact: Artifact = await artifacts.readArtifact("ChainlinkOracleMock");
      this.oracle = <ChainlinkOracleMock>(
        await waffle.deployContract(this.signers.admin, oracleArtifact, [this.link.address])
      );
      const keyringArtifact: Artifact = await artifacts.readArtifact("Keyring");
      this.keyring = <Keyring>(
        await waffle.deployContract(this.signers.admin, keyringArtifact, [
          this.link.address,
          this.oracle.address,
          ethers.utils.formatBytes32String(""),
          ethers.utils.parseUnits("0.1", 18),
          0,
        ])
      );

      const balance = ethers.utils.parseUnits("100.0", 18);
      await this.link.connect(this.signers.admin).transfer(this.keyring.address, balance);
    });

    keyringUnitTests();
  });
});
