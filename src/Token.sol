//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Token is ERC20, ERC20Burnable {
    using Address for address;

    address public nft_address;
    uint256 public nft_id;
    address public nft_owner;

    address public deployer;
    address[] token_owners;
    mapping(address => bool) isHolding;

    error Token__NotDeployer();

    constructor(address _address, uint256 _id, address _owner, uint256 _supply, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        nft_address = _address;
        nft_id = _id;
        nft_owner = _owner;
        deployer = msg.sender;
        _mint(_owner, _supply);
    }

    function transfer(address to, uint256 amount) override public returns(bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    } 

    function updateOwner(address _owner) public {
        if (msg.sender!=deployer){
            revert Token__NotDeployer();
        }
        nft_owner = _owner;
    }

    function returnOwners() public view returns (address[] memory) {
        return token_owners;
    }
}