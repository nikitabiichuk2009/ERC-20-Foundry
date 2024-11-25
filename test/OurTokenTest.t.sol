// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {NikitaBiichuk} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract OurTokenTest is Test {
    NikitaBiichuk public token;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    uint256 constant INITIAL_BALANCE = 1000 ether;

    function setUp() external {
        deployer = new DeployOurToken();
        token = deployer.run();

        address owner = token.owner();

        vm.startPrank(owner);

        token.mint(owner, 1000000000 ether);

        token.transfer(bob, INITIAL_BALANCE);
        token.transfer(alice, INITIAL_BALANCE);

        vm.stopPrank();
    }

    function testNameIsCorrect() public view {
        assertEq(token.name(), "NikitaBiichuk");
    }

    function testOwnerIsDeployer() public view {
        assertEq(token.owner(), address(this));
    }

    function testDecimalsAreCorrect() public view {
        assertEq(token.decimals(), 18);
    }

    function testBobAndAliceBalance() public view {
        assertEq(token.balanceOf(bob), 1000 ether);
        assertEq(token.balanceOf(alice), 1000 ether);
    }

    function testAllowanceWorks() public {
        uint256 initialAllowance = 1000 ether;
        vm.prank(alice);
        token.approve(bob, initialAllowance);

        assertEq(token.allowance(alice, bob), initialAllowance);

        vm.prank(bob);
        uint256 transferAmount = 500 ether;
        token.transferFrom(alice, bob, transferAmount);

        assertEq(token.balanceOf(bob), INITIAL_BALANCE + transferAmount);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - transferAmount);
    }

    function testBurnWorks() public {
        vm.prank(bob);
        token.burn(700 ether);

        assertEq(token.balanceOf(bob), INITIAL_BALANCE - 700 ether);
    }

    function testBurnFromWorks() public {
        uint256 initialAllowance = 1000 ether;
        vm.prank(alice);
        token.approve(bob, initialAllowance);

        vm.prank(bob);
        token.burnFrom(alice, 700 ether);

        assertEq(token.balanceOf(alice), INITIAL_BALANCE - 700 ether);
    }

    function testBurnFromFailsIfNotApproved() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, 700 ether));
        token.burnFrom(alice, 700 ether);
    }

    function testTransferFailsWithoutBalance() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, bob, INITIAL_BALANCE, INITIAL_BALANCE + 1 ether
            )
        );
        token.transfer(alice, INITIAL_BALANCE + 1 ether);
    }

    function testApproveUpdatesAllowance() public {
        vm.prank(alice);
        token.approve(bob, 500 ether);
        assertEq(token.allowance(alice, bob), 500 ether);

        vm.prank(alice);
        token.approve(bob, 800 ether);
        assertEq(token.allowance(alice, bob), 800 ether);

        vm.prank(alice);
        token.approve(bob, 0);
        assertEq(token.allowance(alice, bob), 0);
    }

    function testTransferFromFailsWithoutBalance() public {
        vm.prank(alice);
        token.approve(bob, INITIAL_BALANCE * 2);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, alice, INITIAL_BALANCE, INITIAL_BALANCE + 1 ether
            )
        );
        token.transferFrom(alice, bob, INITIAL_BALANCE + 1 ether);
    }

    function testBurnFailsWithoutBalance() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, bob, INITIAL_BALANCE, INITIAL_BALANCE + 1 ether
            )
        );
        token.burn(INITIAL_BALANCE + 1 ether);
    }

    function testTotalSupplyUpdatesCorrectly() public {
        uint256 initialSupply = token.totalSupply();

        vm.prank(token.owner());
        token.mint(alice, 1000 ether);
        assertEq(token.totalSupply(), initialSupply + 1000 ether);

        vm.prank(alice);
        token.burn(500 ether);
        assertEq(token.totalSupply(), initialSupply + 500 ether);
    }

    function testMintFailsIfNotOwner() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        token.mint(bob, 1000 ether);
    }

    function testTransferToZeroAddress() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 100 ether);
    }

    function testPauseWorks() public {
        vm.prank(token.owner());
        token.pause();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        token.transfer(alice, 100 ether);
    }

    function testUnpauseWorks() public {
        vm.startPrank(token.owner());
        token.pause();
        token.unpause();
        vm.stopPrank();

        vm.prank(bob);
        token.transfer(alice, 100 ether);

        assertEq(token.balanceOf(alice), INITIAL_BALANCE + 100 ether);
        assertEq(token.balanceOf(bob), INITIAL_BALANCE - 100 ether);
    }

    function testPauseFailsIfNotOwner() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        token.pause();
    }

    function testUnpauseFailsIfNotOwner() public {
        vm.prank(token.owner());
        token.pause();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        token.unpause();
    }

    function testUnpauseFailsIfNotPaused() public {
        vm.prank(token.owner());
        vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
        token.unpause();
    }

    function testTransferOwnershipWorks() public {
        vm.prank(token.owner());
        token.transferOwnership(bob);
        assertEq(token.owner(), bob);
    }

    function testTransferOwnershipFailsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.transferOwnership(bob);
    }

    function testTransferOwnershipFailsForZeroAddress() public {
        vm.prank(token.owner());
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        token.transferOwnership(address(0));
    }

    function testNewOwnerCanUseOwnerFunctions() public {
        vm.prank(token.owner());
        token.transferOwnership(bob);

        vm.prank(bob);
        token.mint(alice, 1000 ether);

        assertEq(token.balanceOf(alice), INITIAL_BALANCE + 1000 ether);
    }

    function testPermitWorks() public {
        uint256 privateKey = 0xA11CE;
        address owner = vm.addr(privateKey);

        token.transfer(owner, 1000 ether);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            bob,
                            1000 ether,
                            token.nonces(owner),
                            block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, bob, 1000 ether, block.timestamp, v, r, s);
        assertEq(token.allowance(owner, bob), 1000 ether);
        assertEq(token.nonces(owner), 1);
    }

    function testPermitFailsAfterDeadline() public {
        uint256 privateKey = 0xA11CE;
        address owner = vm.addr(privateKey);

        token.transfer(owner, 1000 ether);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            bob,
                            1000 ether,
                            token.nonces(owner),
                            block.timestamp
                        )
                    )
                )
            )
        );

        vm.warp(block.timestamp + 1);
        vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612ExpiredSignature.selector, block.timestamp - 1));
        token.permit(owner, bob, 1000 ether, block.timestamp - 1, v, r, s);
    }

    function testPermitFailsWithInvalidSignature() public {
        uint256 privateKey = 0xA11CE;
        address owner = vm.addr(privateKey);
        address wrongOwner = makeAddr("wrongOwner");

        token.transfer(owner, 1000 ether);

        uint256 deadline = block.timestamp;

        bytes32 PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, wrongOwner, bob, 1000 ether, token.nonces(wrongOwner), deadline));

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash); // Sign it with privateKey that corresponds to owner

        vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, owner, wrongOwner));

        token.permit(wrongOwner, bob, 1000 ether, deadline, v, r, s);
    }
}
