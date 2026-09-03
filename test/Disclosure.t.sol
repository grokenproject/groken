// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract DisclosureTest is Test {
    string internal constant DISCLOSURE =
        "Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.";

    function test_readmeFirstLineIsFullDisclosure() public view {
        string memory readme = vm.readFile("README.md");
        bytes memory b = bytes(readme);
        bytes memory expected = bytes(DISCLOSURE);
        assertTrue(b.length >= expected.length, "README too short");
        for (uint256 i = 0; i < expected.length; i++) {
            assertEq(uint8(b[i]), uint8(expected[i]), "README line one mismatch");
        }
        if (b.length > expected.length) {
            assertTrue(b[expected.length] == 0x0a, "README line one must end with newline");
        }
    }

    function test_contractSourcesCarryFullNotice() public view {
        _assertFileHasNotice("src/GrokenToken.sol");
        _assertFileHasNotice("src/ImmutableLPLock.sol");
        _assertFileHasNotice("src/ExperimentTreasury.sol");
        _assertFileHasNotice("src/TeamVestLock.sol");
        _assertFileHasNotice("src/ListingReserve.sol");
    }

    function _assertFileHasNotice(string memory path) internal view {
        string memory src = vm.readFile(path);
        assertTrue(_contains(src, DISCLOSURE), path);
    }

    function _contains(string memory hay, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(hay);
        bytes memory n = bytes(needle);
        if (n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool ok = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    ok = false;
                    break;
                }
            }
            if (ok) return true;
        }
        return false;
    }
}
