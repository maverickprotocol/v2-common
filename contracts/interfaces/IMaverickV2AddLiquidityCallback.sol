// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2AddLiquidityCallback {
    function maverickV2AddLiquidityCallback(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountA,
        uint256 amountB,
        bytes calldata data
    ) external;
}
