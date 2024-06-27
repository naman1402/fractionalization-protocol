//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FractionalNFT.sol";
import "./utils/Split.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Vault is FractionalNFT, Split, ReentrancyGuard {
    address public collection; // ERC721 token address of Frac. NFT
    uint256 public tokenId; // ERC721 token id
    uint256 public listPrice; // price of fraction of the fractionalised NFT for primary sale
    address public curator; // address of who initially deposited
    uint256 public fee; // platform fee paid to the curator
    uint256 public start; // start date
    uint256 public end; // end date
    uint256 private constant MAX = 10_000;
    bool public vaultClosed;

    enum State {
        inactive,
        fractionalized,
        live,
        redeemed,
        boughtOut
    }

    State public state;

    constructor(address _curator, uint256 _fee, string memory _name, string memory _symbol, string memory _uri)
        FractionalNFT(_name, _symbol, _uri)
    {
        require(_curator != address(0));
        curator = _curator;
        fee = _fee;
        state = State.inactive;
    }

    // create a fractionalized NFT. _collection and _tokenId is the address and id of NFT that is being fractionalized
    // _supply is the count of fractions (ERC20) of the NFT.
    function fractionalize(address _to, address _collection, uint256 _tokenId, uint256 _supply) public {
        require(state == State.inactive);
        collection = _collection;
        tokenId = _tokenId;
        _mint(_to, _supply);
        state = State.fractionalized;
    }

    // in fractionalized state, the nft is locked and ERC20 tokens are minted. This function initiates the sale of these tokens and change the state to LIVE
    function configureSale(uint256 _start, uint256 _end, uint256 _price) external {
        require(state == State.fractionalized);
        require(_start >= block.timestamp);
        require(_price > 0);
        start = _start;
        end = _end;
        listPrice = _price;
        state = State.live;
    }

    // user can purchase (_amount) ERC20 token(s) as a fraction of F-NFT
    // _amount is the number of tokens(fractions)
    function purchase(uint256 _amount) external payable nonReentrant {
        require(state == State.live);
        require(block.timestamp >= start);
        if (end > 0) require(block.timestamp < end);

        // if fee exists, then calculating it. Else, no feeAmount
        if (fee > 0) {
            uint256 feeAmount = ((_amount * listPrice) * fee) / MAX;
            require(((_amount * listPrice) + feeAmount) == msg.value);
        } else {
            require((_amount * listPrice) == msg.value);
        }

        // checking if supply is more than or equal to what msg.sender wants to buy
        uint256 _supply = balanceOf(address(this));
        require(_amount <= _supply);
        // Transfer of _amount token(fractions)
        _transfer(address(this), _msgSender(), _amount);
    }

    // if msgSender has all the supply of fraction, then he can redeem it and get the NFT
    function redeem() external {
        uint256 redeemerBalance = IERC20(address(this)).balanceOf(_msgSender());
        require(redeemerBalance == IERC20(address(this)).totalSupply());
        state = State.redeemed;
        // need approval of msg.sender to burn these fractions
        _burn(_msgSender(), totalSupply());
        // transferring the nft
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), tokenId, "");
    }

    // msg.sender can pay price to all tokens and get the nft from address(this)
    function buyout() external payable {
        uint256 price = reservePrice();
        require(msg.value >= price);
        state = State.boughtOut;
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), tokenId, "");
    }

    // burning all tokens owner by _msgSender() and then transferring ether to user
    function claim() external {
        require(state == State.boughtOut);
        uint256 claimerBalance = balanceOf(_msgSender());
        require(claimerBalance > 0);

        uint256 fractionsAmount = totalSupply();
        uint256 buyoutPrice = reservePrice();
        uint256 claimAmount = (buyoutPrice * claimerBalance) / fractionsAmount;
        _burn(_msgSender(), claimerBalance);
        (bool success,) = payable(_msgSender()).call{value: claimAmount}("");
        require(success);
    }

    // this returns the total cost of all F-NFT(fractions) tokens
    function reservePrice() public view returns (uint256) {
        return listPrice * totalSupply();
    }

    function updateCurator(address _newCurator) external {
        require(_msgSender() == curator);
        curator = _newCurator;
    }

    function updateFee(uint256 _fee) external {
        require(_msgSender() == curator);
        fee = _fee;
    }

    function setPaymentSplitter(address[] calldata __payees, uint256[] calldata _shares) external {
        require(_msgSender() == curator);
        _setPaymentSplitter(__payees, _shares);
    }

    function withdraw() external {
        require(address(this).balance > 0);
        require(_msgSender() == curator);
        require(_payees.length > 0);
        _distribute();
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
