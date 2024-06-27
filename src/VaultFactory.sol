//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {CREATE3} from "lib/solmate/src/utils/CREATE3.sol";
import "./Vault.sol";

contract VaultFactory is Pausable, Ownable{


    uint public count;
    mapping(uint => address) public vaults;
    constructor() {}

    function createVault(address _collection, uint _tokenId, uint _supply, uint _fee, string memory _name, string memory _symbol, string memory _uri, uint _start, uint _end, uint _price) public whenNotPaused returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_collection, _tokenId, _supply, msg.sender, _fee, _name, _symbol, _uri));
        Vault vault = Vault(CREATE3.deploy(salt, abi.encodePacked(type(Vault).creationCode, abi.encode(msg.sender, _fee, _name, _symbol, _uri)), 0));
    }
}