pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Math as OzMath} from "@openzeppelin/contracts/utils/math/Math.sol";

import {TickMath} from "contracts/libraries/TickMath.sol";
import {Math} from "contracts/libraries/Math.sol";

import {MAX_TICK, ONE} from "contracts/libraries/Constants.sol";

contract TickMathTest is Test {
    using Math for uint256;
    using Math for uint128;
    struct TestCase {
        int32 tick;
        uint256 tickSpacing;
        uint256 result;
    }

    // @dev verify that sqrt tick price is correct with hardcoded test cases
    function testSqrtPrice() public pure {
        uint256 n = 6;
        TestCase[] memory testCases = new TestCase[](n);
        testCases[0] = TestCase({tick: -2235, tickSpacing: 1, result: 894272792908135808});
        testCases[1] = TestCase({tick: 0, tickSpacing: 1, result: 1000000000000000000});
        testCases[2] = TestCase({tick: 1341, tickSpacing: 1, result: 1069345359537797120});
        testCases[3] = TestCase({tick: 123, tickSpacing: 2, result: 1012375333531026560});
        testCases[4] = TestCase({tick: 13, tickSpacing: 12314, result: 2992007427897804980224});
        testCases[5] = TestCase({tick: -5, tickSpacing: 54269, result: 1282663628176});
        for (uint256 i; i < n; i++) {
            uint256 sqrtP = TickMath.tickSqrtPrice(testCases[i].tickSpacing, testCases[i].tick);
            assertApproxEqRel(sqrtP, testCases[i].result, 0.000001e18, "sqrt price is correct");
        }
    }

    function testGetTickLFixed() public pure {
        uint128 a = 1;
        uint128 b = 0;
        // uint32 tick = uint32(MAX_TICK);
        uint32 tick = 0;
        uint256 tickSpacing = 10_000;
        bool priceGreaterThanOne = true;
        uint256 sqrtLower = TickMath.tickSqrtPrice(tickSpacing, priceGreaterThanOne ? int32(tick) : -int32(tick));
        uint256 sqrtUpper = OzMath.mulDiv(sqrtLower, 2.7001e18, 1e18);

        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        assertEq(L, 0);
    }

    function testGetSqrtPriceAndL(
        uint128 reserveA,
        uint128 reserveB,
        uint32 tick,
        uint256 tickSpacing,
        bool priceGreaterThanOne
    ) public pure {
        tickSpacing = tickSpacing % 10_000;
        vm.assume(tickSpacing != 0);
        vm.assume(!(reserveA == 0 && reserveB == 0));
        console2.log("tickSpacing", tickSpacing);

        tick = tick % uint32(MAX_TICK / tickSpacing);
        console2.log("tick", tick);

        uint256 sqrtLower = TickMath.tickSqrtPrice(tickSpacing, priceGreaterThanOne ? int32(tick) : -int32(tick));
        uint256 sqrtUpper = TickMath.tickSqrtPrice(
            tickSpacing,
            priceGreaterThanOne ? int32(tick) + 1 : -int32(tick) + 1
        );
        console2.log("sqrtlower", sqrtLower);
        console2.log("sqrtupper", sqrtUpper);
        uint256 liquidity = TickMath.getTickL(reserveA, reserveB, sqrtLower, sqrtUpper);

        uint256 sqrtPriceReference = Math.sqrt(
            ONE * (reserveA + liquidity.mulFloor(sqrtLower)).divFloor(reserveB + liquidity.divFloor(sqrtUpper))
        );
        sqrtPriceReference = Math.min(Math.max(sqrtPriceReference, sqrtLower), sqrtUpper);
        uint256 sqrtPrice = TickMath.getSqrtPrice(reserveA, reserveB, sqrtLower, sqrtUpper, liquidity);
        (uint256 sqrtPrice_, uint256 liquidity_) = TickMath.getTickSqrtPriceAndL(
            reserveA,
            reserveB,
            sqrtLower,
            sqrtUpper
        );
        assertEq(sqrtPrice, sqrtPrice_);
        assertEq(liquidity_, liquidity);
        assertGe(sqrtPrice, sqrtLower);
        assertLe(sqrtPrice, sqrtUpper);
    }

    // @dev verify that getTickL is correct by cross referencing L with the bin
    // invariant equation
    function testGetTickL(
        uint128 a,
        uint128 b,
        uint32 tick,
        uint256 tickSpacing,
        bool priceGreaterThanOne
    ) public pure {
        tickSpacing = tickSpacing % 10_000;
        vm.assume(tickSpacing != 0);
        console2.log("tickSpacing", tickSpacing);

        tick = tick % uint32(MAX_TICK / tickSpacing);
        console2.log("tick", tick);

        uint256 sqrtLower = TickMath.tickSqrtPrice(tickSpacing, priceGreaterThanOne ? int32(tick) : -int32(tick));
        uint256 sqrtUpper = OzMath.mulDiv(sqrtLower, 1.0001e18, 1e18);

        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        console2.log("a", a);
        console2.log("b", b);
        console2.log("tick", tick);
        console2.log("sqrtLower", sqrtLower);
        console2.log("sqrtUpper", sqrtUpper);
        console2.log("L", L);

        // check invariant holds
        // L^2 = (B + L/sqrtPu) * (A + L * sqrtPl)
        // L^2 = b_ * a_
        if (L > 1e18 && a_ != 0) {
            // for big values, we use the quotient
            console2.log("left quotient", OzMath.mulDiv(b_, ONE, L));
            console2.log("right quotient", OzMath.mulDiv(L, ONE, a_));

            assertApproxEqAbs(
                OzMath.mulDiv(b_, ONE, L),
                OzMath.mulDiv(L, ONE, a_),
                0.0001e18,
                "quotient liquidity invariant holds"
            );
        }
        if (L < 1e47) {
            uint256 rhs = OzMath.mulDiv(b_, a_, ONE);
            uint256 lhs = OzMath.mulDiv(L, L, ONE);
            console2.log("rhs", rhs);
            console2.log("lhs", lhs);
            assertEqToHalfPrecision(rhs, lhs, "sides");
        }
    }

    function testTickLLimit() public pure {
        uint256 sqrtLower = 1e25;
        uint256 sqrtUpper = sqrtLower.mulCeil(1.0001e18);
        uint128 a = type(uint128).max;
        uint128 b = type(uint128).max;
        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        assertEq(OzMath.mulDiv(b_, ONE, L), OzMath.mulDiv(L, ONE, a_));
    }

    function testTickLLimitLower() public pure {
        uint256 sqrtLower = 1e11;
        uint256 sqrtUpper = sqrtLower.mulCeil(1.0001e18);
        uint128 a = type(uint128).max;
        uint128 b = type(uint128).max;
        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        assertEq(OzMath.mulDiv(b_, ONE, L), OzMath.mulDiv(L, ONE, a_));
    }

    function testTickLLimit2() public pure {
        uint256 sqrtLower = 1e18;
        uint256 sqrtUpper = sqrtLower.mulCeil(1.0001e18);
        uint128 a = 1e18;
        uint128 b = 1e18;
        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        assertEq(OzMath.mulDiv(b_, ONE, L), OzMath.mulDiv(L, ONE, a_));
        uint256 rhs = OzMath.mulDiv(b_, a_, ONE);
        uint256 lhs = OzMath.mulDiv(L, L, ONE);
        assertEqToHalfPrecision(rhs, lhs, "sides");
    }

    function testTickLLimit3() public pure {
        uint256 sqrtLower = 1e18;
        uint256 sqrtUpper = sqrtLower.mulCeil(1.0001e18);
        uint128 a = 0;
        uint128 b = 1e18;
        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        assertEq(OzMath.mulDiv(b_, ONE, L), OzMath.mulDiv(L, ONE, a_));
        uint256 rhs = OzMath.mulDiv(b_, a_, ONE);
        uint256 lhs = OzMath.mulDiv(L, L, ONE);
        assertEqToHalfPrecision(rhs, lhs, "sides");
    }

    function testTickLLimit4() public pure {
        uint256 sqrtLower = 1e18;
        uint256 sqrtUpper = sqrtLower.mulCeil(1.0001e18);
        uint128 a = 1e18;
        uint128 b = 0;
        uint256 L = TickMath.getTickL(a, b, sqrtLower, sqrtUpper);
        uint256 b_ = b + OzMath.mulDiv(L, ONE, sqrtUpper);
        uint256 a_ = a + OzMath.mulDiv(L, sqrtLower, ONE);
        assertEq(OzMath.mulDiv(b_, ONE, L), OzMath.mulDiv(L, ONE, a_));
        uint256 rhs = OzMath.mulDiv(b_, a_, ONE);
        uint256 lhs = OzMath.mulDiv(L, L, ONE);
        assertEqToHalfPrecision(rhs, lhs, "sides");
    }

    function testTickSqrtPrices(uint32 tick, uint256 tickSpacing, bool priceGreaterThanOne) public pure {
        tickSpacing = tickSpacing % 10_000;
        vm.assume(tickSpacing != 0);

        tick = tick % uint32(MAX_TICK / tickSpacing);
        if ((tick + 2) * tickSpacing > MAX_TICK) tick -= 2;
        int32 _tick = priceGreaterThanOne ? int32(tick) : -int32(tick);

        (, uint256 p0_) = TickMath.tickSqrtPrices(tickSpacing, _tick - 1);
        (uint256 p0, uint256 p1) = TickMath.tickSqrtPrices(tickSpacing, _tick);
        (uint256 p1_, ) = TickMath.tickSqrtPrices(tickSpacing, _tick + 1);
        assertEq(p0, p0_);
        assertEq(p1, p1_);
        assertGt(p1, p0);
    }

    function testTickSqrtPricesLimit() public {
        vm.expectRevert();
        TickMath.tickSqrtPrices(1, int32(int256(MAX_TICK)));
        vm.expectRevert();
        TickMath.tickSqrtPrices(1, -int32(int256(MAX_TICK)));
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    function assertEqToHalfPrecision(uint256 a, uint256 b, string memory err) internal pure {
        uint256 decimalPlaces = max(log10(a), log10(b)) / 2 + 1;
        assertApproxEqAbs(a / 10 ** decimalPlaces, b / 10 ** decimalPlaces, 1, err);
    }
}
