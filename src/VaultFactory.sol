//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {CREATE3} from "../lib/solmate/src/utils/CREATE3.sol";
import "./Vault.sol";

contract VaultFactory is Pausable, Ownable(msg.sender) {
    uint256 public count; // number of vaults
    mapping(uint256 => address) public vaults; // vault id to vault address

    constructor() {}

    function createVault(
        address _collection,
        uint256 _tokenId,
        uint256 _supply,
        uint256 _fee,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _start,
        uint256 _end,
        uint256 _price
    ) public whenNotPaused returns (address) {
        // hash of various parameters
        bytes32 salt =
            keccak256(abi.encodePacked(_collection, _tokenId, _supply, msg.sender, _fee, _name, _symbol, _uri));
            // Using CREATE3 makes it harder for attackers to predict the deployment address and exploit the vault before its creation
        Vault vault = Vault(
            CREATE3.deploy(
                salt, abi.encodePacked(type(Vault).creationCode, abi.encode(msg.sender, _fee, _name, _symbol, _uri)), 0
            )
        );

        assert(address(vault) == CREATE3.getDeployed(salt));
        // transferring NFT from deployer to vault
        IERC721(_collection).transferFrom(msg.sender, address(vault), _tokenId);
        // using vault to fractionalize the nft and create fractions(tokens) and starting the sale
        Vault(vault).fractionalize(msg.sender, _collection, _tokenId, _supply);
        Vault(vault).configureSale(_start, _end, _price);
        address vaultAddress = address(vault);

        count ++;
        vaults[count] = vaultAddress;
        return vaultAddress;
    }

    //ONLY the factory owner (msg.sender) can call this function
    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}
