//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./MockFractionalNFT.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract FractionalNFTTest is Test {

    string name = "Test Token Name";
    string symbol = "TTN";
    string uri = "token_uri";
    MockFractionalNFT public nft;

    function setUp() public {
        nft = new MockFractionalNFT(name, symbol, uri);
    }

    // function invariantMetadata() public {
    //     assertEq(nft.name(), name);
    //     assertEq(nft.symbol(), symbol);
    //     assertEq(nft.decimals(), 0);
    //     assertEq(nft.getUri(0), uri);
    // }

    function testMint() public {
        nft.mint(address(0xABC), 1e18);
        assertTrue(nft.totalSupply() ==  1e18);
        assertTrue(nft.balanceOf(address(0xABC)) == 1e18);
    }

    function testBurn() public {
        nft.mint(address(0xDEF), 1e18);
        nft.burn(address(0xDEF), 0.9e18);
        assertTrue(nft.totalSupply() == 1e18 - 0.9e18);
        assertTrue(nft.balanceOf(address(0xDEF)) == 0.1e18);
    }
}
