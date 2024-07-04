//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Vault is IERC721Receiver{

    struct Deposit{
        address owner;
        address nftAddress;
        uint256 nftId;
        uint256 timestamp;
        address tokenAddress;
        uint256 supply;
        bool Fractionalised;
    }

    struct Deposits {
        Deposit[] deposits;
    }

    // nftAddress -> nftId -> no. of Deposit in Deposits
    mapping(address => mapping(uint256 => uint256)) index;
    mapping(address => Deposits) AccessDeposits;


    function depositNFT(address nftAddress, uint256 nftId) public {
        ERC721 nft = ERC721(nftAddress);
        nft.safeTransferFrom(msg.sender, address(this), nftId);
        Deposit memory newDeposit;
        newDeposit.owner = msg.sender;
        newDeposit.nftAddress = nftAddress;
        newDeposit.nftId = nftId;
        newDeposit.timestamp = block.timestamp;
        newDeposit.Fractionalised = false;
        index[nftAddress][nftId] = AccessDeposits[msg.sender].deposits.length;
        AccessDeposits[msg.sender].deposits.push(newDeposit); 
    }

    function fractionalize(address nftAddress, uint256 nftId, uint256 supply, string memory name, string memory symbol) public {
        uint256 _index = index[nftAddress][nftId];
        require(AccessDeposits[msg.sender].deposits[_index].owner == msg.sender);
        AccessDeposits[msg.sender].deposits[_index].Fractionalised = true;


        // deployer of token is vault contract
        Token token = new Token(nftAddress, nftId, msg.sender, supply, name, symbol);
        AccessDeposits[msg.sender].deposits[_index].tokenAddress = address(token);
    }

    function withdrawNftWithSupply(address _fractionContract) public {
        
        Token token = Token(_fractionContract);

        require(token.deployer() == address(this), "Only fraction tokens created by this fractionalize contract can be accepted");
        require(token.balanceOf(msg.sender) == token.totalSupply());

        address NFTAddress = token.nft_address();
        uint256 NFTId = token.nft_id();

        //remove tokens from existence
        token.transferFrom(msg.sender, address(this), token.totalSupply());
        token.burn(token.totalSupply());

        ERC721 NFT = ERC721(NFTAddress);
        NFT.safeTransferFrom(address(this), msg.sender, NFTId);

        uint256 _index = index[NFTAddress][NFTId];
        delete AccessDeposits[msg.sender].deposits[_index];
    }

    function withdrawNftNotFractionalized(address _nft, uint256 _id) public {
        uint _index = index[_nft][_id];
        require(AccessDeposits[msg.sender].deposits[_index].Fractionalised == false && AccessDeposits[msg.sender].deposits[_index].owner == msg.sender);
        ERC721 nft = ERC721(_nft);
        nft.safeTransferFrom(address(this), msg.sender, _id);
        delete AccessDeposits[msg.sender].deposits[_index];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
