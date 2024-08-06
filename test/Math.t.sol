pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {Math as OzMath} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Math} from "contracts/libraries/Math.sol";
import {ONE_SQUARED, ONE} from "contracts/libraries/Constants.sol";

contract MathTest is Test {
    function testMin() public pure {
        assertEq(Math.min(uint256(10), uint256(1)), uint256(1));
        assertEq(Math.min(uint256(10), uint256(1100)), uint256(10));
        assertEq(Math.min(uint256(0), uint256(1100)), uint256(0));

        assertEq(Math.min(int256(10), int256(1)), 1);
        assertEq(Math.min(int256(10), int256(1100)), int256(10));
        assertEq(Math.min(int256(0), int256(1100)), int256(0));

        assertEq(Math.min128(uint128(10), uint128(1)), uint128(1));
        assertEq(Math.min128(uint128(10), uint128(1100)), uint128(10));
        assertEq(Math.min128(uint128(0), uint128(1100)), uint128(0));

        assertEq(Math.min(-int256(10), int256(1)), -int256(10));
        assertEq(Math.min(-int256(10), int256(1100)), -int256(10));
        assertEq(Math.min(-int256(0), int256(1100)), int256(0));

        assertEq(Math.min(-int256(10), -int256(1)), -int256(10));
        assertEq(Math.min(-int256(10), -int256(1100)), -int256(1100));
        assertEq(Math.min(-int256(0), -int256(1100)), -int256(1100));
    }

    function testMax() public pure {
        assertEq(Math.max(uint256(10), uint256(1)), uint256(10));
        assertEq(Math.max(uint256(10), uint256(1100)), uint256(1100));
        assertEq(Math.max(uint256(0), uint256(1100)), uint256(1100));

        assertEq(Math.max(int256(10), int256(1)), 10);
        assertEq(Math.max(int256(10), int256(1100)), int256(1100));
        assertEq(Math.max(int256(0), int256(1100)), int256(1100));

        assertEq(Math.max128(uint128(10), uint128(1)), uint128(10));
        assertEq(Math.max128(uint128(10), uint128(1100)), uint128(1100));
        assertEq(Math.max128(uint128(0), uint128(1100)), uint128(1100));

        assertEq(Math.max(-int256(10), int256(1)), int256(1));
        assertEq(Math.max(-int256(10), int256(1100)), int256(1100));
        assertEq(Math.max(-int256(0), int256(1100)), int256(1100));

        assertEq(Math.max(-int256(10), -int256(1)), -int256(1));
        assertEq(Math.max(-int256(10), -int256(1100)), -int256(10));
        assertEq(Math.max(-int256(0), -int256(1100)), int256(0));
    }

    function testInv() public pure {
        assertEq(Math.invFloor(3e18), 333333333333333333);
        assertEq(Math.invFloor(1e18), 1e18);
        assertEq(Math.invFloor(10e18), 1e17);

        assertEq(Math.invCeil(3e18), 333333333333333334);
        assertEq(Math.invFloor(1e18), 1e18);
        assertEq(Math.invFloor(10e18), 1e17);
    }

    function testClip() public pure {
        assertEq(Math.clip(10, 5), 5);
        assertEq(Math.clip(5, 5), 0);
        assertEq(Math.clip(1, 5), 0);

        assertEq(Math.clip128(10, 5), 5);
        assertEq(Math.clip128(5, 5), 0);
        assertEq(Math.clip128(1, 5), 0);
    }

    function testMulDiv() public pure {
        assertEq(OzMath.mulDiv(10, 10, 2), 50);
        assertEq(Math.mulDivCeil(10, 10, 2), 50);
        assertEq(OzMath.mulDiv(10, 10, 3), 33);
        assertEq(Math.mulDivCeil(10, 10, 3), 34);

        assertEq(Math.mulFloor(1e18 + 1, 333) + 1, Math.mulCeil(1e18 + 1, 333), "mulCeil is bigger than mul by 1");
        assertEq(Math.mulFloor(1e18, 1e18), Math.mulCeil(1e18, 1e18), "mulCeil is equal for divisible products");

        assertEq(
            Math.divFloor(1e18 + 1, 333e18) + 1,
            Math.divCeil(1e18 + 1, 333e18),
            "divCeil is bigger than div by 1"
        );
        assertEq(Math.divFloor(1e18, 1e18), Math.divCeil(1e18, 1e18), "divCeil is equal for divisible quotients");
    }

    function testMulDivFuzz(uint128 x, uint128 y, uint128 z) public pure {
        vm.assume(z != 0);
        assertEq(OzMath.mulDiv(x, y, z), Math.mulDivDown(x, y, z));
        assertEq(OzMath.mulDiv(x, y, z, OzMath.Rounding.Ceil), Math.mulDivUp(x, y, z));
    }

    function testMulDivFuzz2(uint128 x, uint128 y, uint128 z) public pure {
        assertEq(Math.mulDivFloor(x, y, z), Math.mulDivDown(x, y, z));
        assertEq(Math.mulDivUp(x, y, z), Math.mulDivCeil(x, y, z));
    }

    function testMulDivFuzz(uint256 x, uint256 y, uint256 z) public pure {
        vm.assume(z != 0);
        unchecked {
            uint256 prod0 = x * y;
            uint256 prod1;
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (z <= prod1) {
                return;
            }
        }
        assertEq(OzMath.mulDiv(x, y, z), Math.mulDivFloor(x, y, z));
        if (OzMath.mulDiv(x, y, z) == type(uint256).max) return;
        assertEq(OzMath.mulDiv(x, y, z, OzMath.Rounding.Ceil), Math.mulDivCeil(x, y, z));
    }

    function testDivFuzz(uint128 x, uint128 y) public pure {
        assertEq(Math.divFloor(x, y), Math.divDown(x, y));
        assertEq(Math.divUp(x, y), Math.divUp(x, y));
    }

    function testInvFuzz(uint256 x) public pure {
        vm.assume(x != 0);
        uint256 result = Math.invFloor(x);
        unchecked {
            if (mulmod(ONE, ONE, x) != 0) result = result + 1;
        }
        assertEq(result, Math.invCeil(x));
        assertEq(Math.invFloor(x), ONE_SQUARED / x);
    }

    function testScale() public pure {
        uint256 scale12 = Math.scale(12);
        uint256 scale18 = Math.scale(18);

        assertEq(Math.tokenScaleToAmmScale(1e3, scale12), 1e9);
        assertEq(Math.tokenScaleToAmmScale(1e12, scale12), 1e18);

        assertEq(Math.tokenScaleToAmmScale(1e3, scale18), 1e3);
        assertEq(Math.tokenScaleToAmmScale(1e12, scale18), 1e12);
        assertEq(Math.tokenScaleToAmmScale(1e24, scale18), 1e24);

        assertEq(Math.ammScaleToTokenScale(1e3, scale12, false), 0);
        assertEq(Math.ammScaleToTokenScale(1e12, scale12, false), 1e6);
        assertEq(Math.ammScaleToTokenScale(1e12, scale18, false), 1e12);

        assertEq(Math.ammScaleToTokenScale(1e3, scale12, true), 1);
        assertEq(Math.ammScaleToTokenScale(1e12, scale12, true), 1e6);

        assertEq(Math.ammScaleToTokenScale(1e3 + 1, scale12, true), 1);
        assertEq(Math.ammScaleToTokenScale(1e12 + 1, scale12, true), 1e6 + 1);
    }

    function testAbs32() public pure {
        assertEq(Math.abs32(-10), 10);
        assertEq(Math.abs32(10), 10);
        assertEq(Math.abs32(type(int32).min), uint256(-int256(type(int32).min)));
    }

    function testAbs() public pure {
        assertEq(Math.abs(-10), 10);
        assertEq(Math.abs(10), 10);
        assertEq(Math.abs(type(int256).min), 1 << 255);
        assertEq(Math.abs(type(int256).max), (1 << 255) - 1);
    }

    function testFloor() public {
        assertEq(Math.floorD8Unchecked(-10.01e8), -11);
        vm.expectRevert();
        assertEq(Math.floorD8Unchecked(-2147483648.01e8), -2147483649);
    }

    function testMaxFuzz(uint256 x, uint256 y) public pure {
        assertEq(Math.max(x, y), x > y ? x : y);
    }

    function testMaxFuzzSigned(int256 x, int256 y) public pure {
        assertEq(Math.max(x, y), x > y ? x : y);
    }

    function testMinFuzz(uint256 x, uint256 y) public pure {
        assertEq(Math.min(x, y), x < y ? x : y);
    }

    function testMinFuzzSigned(int256 x, int256 y) public pure {
        assertEq(Math.min(x, y), x < y ? x : y);
    }

    function testSqrt(uint248 x) public pure {
        uint256 y = Math.sqrt(x);

        assertGe((y + 1) * (y + 1), x);
        assertLe(y * y, x);
    }

    function testSqrtCompare(uint256 x) public pure {
        assertEq(Math.sqrt(x), OzMath.sqrt(x));
    }
}
