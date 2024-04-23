// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_VALUE = 1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    function testMinimumDollarFive() public view {
        console.log("Hello World");
        console.log("Aishwaria is great.");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructures() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        console.log(USER);
        console.log(amountFunded);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundertoArrayOfFunders() public funded {
        address funder = fundMe.getIndex(0);
        assertEq(USER, funder);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromSingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;
        //Account
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundBalance
        );
        assertEq(endingFundBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;
        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(1);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        console.log(gasStart - gasEnd);
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;
        assert(address(fundMe).balance == 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundBalance
        );
        assertEq(endingFundBalance, 0);
    }
}
