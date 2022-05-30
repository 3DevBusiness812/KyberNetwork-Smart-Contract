import { expect } from "chai";
import { ethers } from "hardhat";

export function keyringUnitTests(): void {
  it("should revert if user does not own any NFT", async function () {
    expect(await this.keyring.connect(this.signers.admin).isValid(this.signers.admin.address)).to.reverted("");
  });

  it("should mint a new NFT", async function () {
    expect(await this.keyring.connect(this.signers.admin).create()).to.reverted("");
  });

  it("should not mint a new NFT if user already owns one", async function () {
    await this.keyring.connect(this.signers.admin).create();
    expect(await this.keyring.connect(this.signers.admin).create()).to.reverted("");
  });
}
