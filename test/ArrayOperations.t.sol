pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ArrayOperations} from "contracts/libraries/ArrayOperations.sol";

contract ArrayOperationsTest is Test {
    using ArrayOperations for uint32[];

    function _arrayMaker(uint32[10] memory elements) internal pure returns (uint32[] memory array) {
        array = new uint32[](elements.length);
        for (uint256 i; i < elements.length; i++) {
            array[i] = elements[i];
        }
    }

    function testCheckUnique() public {
        uint32[] memory array = _arrayMaker([uint32(0), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        array.checkUnique(100);

        array = _arrayMaker([uint32(0), 1, 2, 3, 0, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUnique(100);

        array = _arrayMaker([uint32(1), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUnique(100);
    }

    function testCheckUniqueViaSearch() public pure {
        uint32[] memory array = _arrayMaker([uint32(0), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        array.checkUniqueViaSearch();
    }

    function testCheckUniqueViaSearchRevert() public {
        uint32[] memory array;
        array = _arrayMaker([uint32(0), 1, 2, 3, 0, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUniqueViaSearch();

        array = _arrayMaker([uint32(1), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUniqueViaSearch();

        array = _arrayMaker([uint32(1), 15, 2, 3, 4, 5, 7, 8, 10, 10]);
        vm.expectRevert();
        array.checkUniqueViaSearch();
    }

    function testCheckUniqueViaBitMap() public pure {
        uint32[] memory array = _arrayMaker([uint32(0), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        array.checkUniqueViaBitMap(100_000);
    }

    function testCheckUniqueViaBitMapRevert() public {
        uint32[] memory array;
        array = _arrayMaker([uint32(0), 1, 2, 3, 0, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUniqueViaBitMap(100);

        array = _arrayMaker([uint32(1), 1, 2, 3, 4, 5, 7, 8, 10, 13]);
        vm.expectRevert();
        array.checkUniqueViaBitMap(100);

        array = _arrayMaker([uint32(1), 15, 2, 3, 4, 5, 7, 8, 10, 10]);
        vm.expectRevert();
        array.checkUniqueViaBitMap(100);
    }
}
