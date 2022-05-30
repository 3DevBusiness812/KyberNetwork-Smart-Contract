// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Base is ERC721Enumerable, ERC721URIStorage, Ownable {
    error ERC721__Non_Transferrable_NFT();
    error ERC721__Max_Limit_NFT(address to);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721) {
        if (balanceOf(msg.sender) != 0) revert ERC721__Max_Limit_NFT(to);

        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        if (from != address(0) && to != address(0)) revert ERC721__Non_Transferrable_NFT();

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
