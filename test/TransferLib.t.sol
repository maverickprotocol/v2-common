pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {TransferLib} from "contracts/libraries/TransferLib.sol";

contract ERC20Mint is ERC20 {
    constructor() ERC20("", "") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract TrasnsferLibTest is Test {
    address internal immutable user = address(5);

    // from https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/test/utils/DSTestPlus.sol
    modifier brutalizeMemory(bytes memory brutalizeWith) {
        /// @solidity memory-safe-assembly
        assembly {
            // Fill the 64 bytes of scratch space with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    64, // Copy enough to only fill the scratch space.
                    0, // Store the return value in the scratch space.
                    64 // Scratch space is only 64 bytes in size, we don't want to write further.
                )
            )

            let size := add(mload(brutalizeWith), 32) // Add 32 to include the 32 byte length slot.

            // Fill the free memory pointer's destination with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    size, // We want to pass the length of the bytes.
                    mload(0x40), // Store the return value at the free memory pointer.
                    size // Since the precompile just returns its input, we reuse size.
                )
            )
        }

        _;
    }

    function testTransfer(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(to != address(0));
        vm.assume(amount != 0);

        ERC20Mint _token = new ERC20Mint();
        _token.mint(address(this), amount);

        verifyTransfer(ERC20(address(_token)), to, amount);
    }

    function testTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(to != address(0));
        vm.assume(from != address(0));
        vm.assume(amount != 0);

        ERC20Mint _token = new ERC20Mint();
        _token.mint(from, amount);

        vm.prank(from);
        _token.approve(address(this), amount);
        verifyTransferFrom(ERC20(address(_token)), from, to, amount);
    }

    function verifyTransfer(ERC20 token, address to, uint256 amount) public {
        uint256 preBal = token.balanceOf(to);
        TransferLib.transfer(token, to, amount);
        uint256 postBal = token.balanceOf(to);

        if (to == address(this)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifyTransferFrom(ERC20 token, address from, address to, uint256 amount) public {
        uint256 preBal = token.balanceOf(to);
        TransferLib.transferFrom(token, from, to, amount);
        uint256 postBal = token.balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }
}
