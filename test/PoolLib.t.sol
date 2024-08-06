pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {IMaverickV2Pool} from "contracts/interfaces/IMaverickV2Pool.sol";
import {PoolLib} from "contracts/libraries/PoolLib.sol";
import {Math} from "contracts/libraries/Math.sol";
import {MAX_TICK} from "contracts/libraries/Constants.sol";

contract PoolLibTest is Test {
    IMaverickV2Pool.BinState internal bin;

    function _arrayMaker(int32[5] memory elements) internal pure returns (int32[] memory array) {
        array = new int32[](elements.length);
        for (uint256 i; i < elements.length; i++) {
            array[i] = elements[i];
        }
    }

    function testUniqueOrderedTicksCheck() public {
        int32[] memory array = _arrayMaker([int32(0), 1, 2, 3, 4]);
        PoolLib.uniqueOrderedTicksCheck(array, array.length);

        array = _arrayMaker([int32(-4), -3, -2, -1, 3]);
        PoolLib.uniqueOrderedTicksCheck(array, array.length);

        // wrong length
        vm.expectRevert();
        PoolLib.uniqueOrderedTicksCheck(array, array.length + 1);
        vm.expectRevert();
        PoolLib.uniqueOrderedTicksCheck(array, array.length - 1);

        // not sorted
        array = _arrayMaker([int32(0), 1, 2, 4, 3]);
        vm.expectRevert();
        PoolLib.uniqueOrderedTicksCheck(array, array.length);

        // repeat
        array = _arrayMaker([int32(1), 1, 2, 3, 4]);
        vm.expectRevert();
        PoolLib.uniqueOrderedTicksCheck(array, array.length);
    }

    function testReserveValue(uint128 tickReserve, uint128 tickBalance, uint128 tickTotalSupply) public pure {
        vm.assume(tickTotalSupply >= tickBalance);
        PoolLib.reserveValue(tickReserve, tickBalance, tickTotalSupply);
    }

    function testBinReserves(
        uint128 tickBalance,
        uint128 tickReserveA,
        uint128 tickReserveB,
        uint128 tickTotalSupply
    ) public pure {
        vm.assume(tickTotalSupply >= tickBalance);
        PoolLib.binReserves(tickBalance, tickReserveA, tickReserveB, tickTotalSupply);
    }

    function testBinReserves(uint128 tickBalance, IMaverickV2Pool.TickState memory tick) public {
        vm.assume(tick.totalSupply >= tickBalance);
        bin.tickBalance = tickBalance;
        PoolLib.binReserves(bin, tick);
    }

    function testDeltaTickBalanceFromDeltaLpBalance(
        uint128 binTickBalance,
        uint128 binTotalSupply,
        IMaverickV2Pool.TickState memory tickState,
        uint128 deltaLpBalance,
        PoolLib.AddLiquidityInfo memory addLiquidityInfo
    ) public pure {
        vm.assume(binTotalSupply != 0);
        vm.assume(deltaLpBalance != 0);
        vm.assume(tickState.totalSupply >= binTickBalance);
        vm.assume(uint256(deltaLpBalance) + uint256(binTotalSupply) < type(uint128).max);

        addLiquidityInfo.tickSpacing = addLiquidityInfo.tickSpacing % 10_000;
        vm.assume(addLiquidityInfo.tickSpacing != 0);
        uint32 tick = Math.abs32(addLiquidityInfo.tick);
        bool priceGreaterThanOne = tick == uint32(addLiquidityInfo.tick);

        tick = tick % uint32(MAX_TICK / addLiquidityInfo.tickSpacing);
        if ((tick + 2) * addLiquidityInfo.tickSpacing > MAX_TICK) tick -= 2;
        addLiquidityInfo.tick = priceGreaterThanOne ? int32(tick) : -int32(tick);

        PoolLib.deltaTickBalanceFromDeltaLpBalance(
            binTickBalance,
            binTotalSupply,
            tickState,
            deltaLpBalance,
            addLiquidityInfo
        );
        assertTrue(addLiquidityInfo.deltaA > 0 || addLiquidityInfo.deltaB > 0);
    }
}
