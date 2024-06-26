//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FractionalNFT is ERC20, IERC1155, ERC165 {
    using Address for address;

    // storage
    uint256 internal supply;
    mapping(address => uint256) internal balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    string private uri;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC20(_name, _symbol) {
        uri = _uri;
    }

    function getUri(uint256) public view returns (string memory) {
        return uri;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    function balanceOf(address user) public view override returns (uint256) {
        return balance[user];
    }

    // @override ERC1155 balanceOf(address, uint256)
    function balanceOf(address user, uint256 id) public view override returns (uint256) {
        return id == 0 ? balance[user] : 0;
    }

    /// @dev In ERC1155, all states are held in single contract, it is possible to operate over multiple tokens in a single transaction.abi
    // balanceOfBatch makes querying multiple balances and transferring multiple tokens simplers
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length);
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowance[msg.sender][spender] = amount;
        return true;
    }

    function setApprovalForAll(address spender, bool approved) external override {
        if (approved) {
            _allowance[msg.sender][spender] = type(uint256).max;
        } else {
            _allowance[msg.sender][spender] = 0;
        }
    }

    function isApprovedForAll(address account, address spender) external view override returns (bool) {
        return _allowance[account][spender] == type(uint256).max;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0));
        balance[msg.sender] -= amount;
        unchecked {
            balance[to] += amount;
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0));
        if (from != msg.sender && _allowance[from][msg.sender] != type(uint256).max) {
            _allowance[from][msg.sender] -= amount;
        }
        balance[from] -= amount;
        unchecked {
            balance[to] += amount;
        }

        return true;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data)
        external
        override
    {
        require(id == 0);
        transferFrom(from, to, value);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == 1);
        require(ids[0] == 0);

        require(values.length == ids.length);

        transferFrom(from, to, values[0]);
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, values, data);
    }

    function _setUri(string memory newUri) internal {
        uri = newUri;
    }

    function isContract(address _addr) private returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer on non ERC1155Reciever implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response)
            {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

}
