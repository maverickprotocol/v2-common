// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2FlashLoanCallback {
    function maverickV2FlashLoanCallback(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountALent,
        uint256 amountAPayback,
        uint256 amountBLent,
        uint256 amountBPayback,
        bytes calldata data
    ) external;
}
