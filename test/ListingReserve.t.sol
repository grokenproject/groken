// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Fixture} from "./helpers/Fixture.sol";
import {ListingReserve} from "../src/ListingReserve.sol";

/**
 * @notice Project Groken is a disclosed experiment run by autonomous AI agents; it is not an investment offering, and no person is promising a return.
 */
contract ListingReserveTest is Fixture {
    function setUp() public override {
        super.setUp();
        runLaunchDistribution();
    }

    function test_emptyAllowlistIsValid() public {
        address[] memory none = new address[](0);
        address[] memory blocked = new address[](1);
        blocked[0] = ammRecipient;
        ListingReserve empty = new ListingReserve(address(token), dead, proposer, none, blocked);
        vm.prank(proposer);
        vm.expectRevert(ListingReserve.NotAllowlisted.selector);
        empty.proposeTransfer(listingFeeDest, 1 ether, ListingReserve.Purpose.ListingFee);
    }

    function test_hardRevertProjectAddresses() public {
        vm.startPrank(proposer);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(ammRecipient, 1 ether, ListingReserve.Purpose.MMInventory);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(address(token), 1 ether, ListingReserve.Purpose.ListingFee);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(address(treasury), 1 ether, ListingReserve.Purpose.ListingFee);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(address(vest), 1 ether, ListingReserve.Purpose.ListingFee);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(teamWallet, 1 ether, ListingReserve.Purpose.ListingFee);
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        listing.proposeTransfer(address(listing), 1 ether, ListingReserve.Purpose.ListingFee);
        vm.stopPrank();
    }

    function test_cannotSendOffAllowlist() public {
        vm.prank(proposer);
        vm.expectRevert(ListingReserve.NotAllowlisted.selector);
        listing.proposeTransfer(stranger, 1 ether, ListingReserve.Purpose.ListingFee);
    }

    function test_proposeExecuteAfterDelay() public {
        vm.prank(proposer);
        listing.proposeTransfer(listingFeeDest, 10 ether, ListingReserve.Purpose.ListingFee);

        vm.expectRevert();
        listing.executeTransfer();

        vm.warp(block.timestamp + 7 days);
        listing.executeTransfer();
        assertEq(token.balanceOf(listingFeeDest), 10 ether);
    }

    function test_mmInventoryPurpose() public {
        vm.prank(proposer);
        listing.proposeTransfer(mmDest, 5 ether, ListingReserve.Purpose.MMInventory);
        vm.warp(block.timestamp + 7 days);
        listing.executeTransfer();
        assertEq(token.balanceOf(mmDest), 5 ether);
    }

    function test_onePending() public {
        vm.startPrank(proposer);
        listing.proposeTransfer(listingFeeDest, 1 ether, ListingReserve.Purpose.ListingFee);
        vm.expectRevert(ListingReserve.PendingExists.selector);
        listing.proposeTransfer(mmDest, 1 ether, ListingReserve.Purpose.MMInventory);
        vm.stopPrank();
    }

    function test_executeRevertsAfter90d_pendingDies() public {
        vm.prank(proposer);
        listing.proposeTransfer(listingFeeDest, 10 ether, ListingReserve.Purpose.ListingFee);
        vm.warp(listing.experimentEnd());
        vm.expectRevert(ListingReserve.ExperimentEnded.selector);
        listing.executeTransfer();
        assertEq(token.balanceOf(listingFeeDest), 0);
        assertEq(token.balanceOf(address(listing)), LISTING_ALLOCATION);
    }

    function test_newProposeRevertsAfter90d() public {
        vm.warp(listing.experimentEnd());
        vm.prank(proposer);
        vm.expectRevert(ListingReserve.ExperimentEnded.selector);
        listing.proposeTransfer(listingFeeDest, 1 ether, ListingReserve.Purpose.ListingFee);
    }

    function test_sendToDeadIsProposerOnly() public {
        vm.prank(stranger);
        vm.expectRevert(ListingReserve.NotProposer.selector);
        listing.sendToDead(100 ether);

        vm.prank(proposer);
        listing.sendToDead(100 ether);
        assertEq(token.balanceOf(dead), 100 ether);
    }

    function test_remainderToDeadAfter90dPermissionless() public {
        vm.expectRevert(ListingReserve.ExperimentNotEnded.selector);
        listing.sendRemainderToDead();

        vm.warp(listing.experimentEnd());
        vm.prank(stranger);
        listing.sendRemainderToDead();
        assertEq(token.balanceOf(address(listing)), 0);
        assertEq(token.balanceOf(dead), LISTING_ALLOCATION);
    }

    function test_remainderToDeadIncludesPendingAndDeletesIt() public {
        vm.prank(proposer);
        listing.proposeTransfer(listingFeeDest, 10 ether, ListingReserve.Purpose.ListingFee);
        (,,,, bool existsBefore) = listing.pending();
        assertTrue(existsBefore);

        vm.warp(listing.experimentEnd());
        vm.prank(stranger);
        listing.sendRemainderToDead();

        (,,,, bool existsAfter) = listing.pending();
        assertFalse(existsAfter);
        assertEq(token.balanceOf(address(listing)), 0);
        assertEq(token.balanceOf(listingFeeDest), 0);
        assertEq(token.balanceOf(dead), LISTING_ALLOCATION);
    }

    function test_constructorRejectsAllowlistOverlap() public {
        address[] memory allow = new address[](1);
        allow[0] = ammRecipient;
        address[] memory blocked = new address[](1);
        blocked[0] = ammRecipient;
        vm.expectRevert(ListingReserve.ProjectAddress.selector);
        new ListingReserve(address(token), dead, proposer, allow, blocked);
    }

    function test_noAmmSurface() public {
        address l = address(listing);
        assertNoSelector(
            l, abi.encodeWithSignature("swap(uint256,uint256,address[])", uint256(1), uint256(0), new address[](0))
        );
        assertNoSelector(l, abi.encodeWithSignature("addLiquidity(address,address,uint256,uint256)"));
        assertNoSelector(l, abi.encodeWithSignature("owner()"));
    }

    function test_fuzz_offlistReverts(address to) public {
        vm.assume(to != listingFeeDest && to != mmDest);
        vm.prank(proposer);
        vm.expectRevert();
        listing.proposeTransfer(to, 1 ether, ListingReserve.Purpose.ListingFee);
    }
}
