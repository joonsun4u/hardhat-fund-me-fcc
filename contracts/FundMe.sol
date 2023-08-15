//Get funds from users
//Withdraw funds
//Set a minimum funding value in USD
//test

//SPDX-License-Identifier: MIT
//Pragma
pragma solidity ^0.8.8;

//Limit tinkering/triaging to 20minutes
//Take at least 15 minutes yourself -> or be 100% sure you exhausted all options:
// 1. Tinker and try to pinpoint exactly what's going on
// 2. Google exact error
// 2.5 Go to our Github repo discussion and/or updates.
// 3. Ask question on a forum like Stack Overflow or Stack Exchange ETH

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//837,297 gas for transaction cost.
//817,755 gas for transaction cost after using "constant" for MINIMUM_USD

//Error Codes
error FundMe__NotOwner();

//Interfaces, libraries, contracts

/**@title A sample Funding Contract
 * @author Joon-Sun Kim
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 0.0000000000001 * 10 ** 18; // 1* 1 * 10 ** 18
    //2451 gas for non-constant
    //351 gas for constant * 67000000000 = $0.0376272

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    //444 gas - immutable
    //2580 gas - non-immutable

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract

        //msg.value.getConversionRate();
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        //18 decimals

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;

        //what is reverting? Undo any action before, and send remaining gas back.
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset array
        s_funders = new address[](0);

        //actually withdraw funds

        //3 different ways of send eth

        //transfer
        //msg.sender is a type address
        //payable(msg.sender) is a type payable address
        // payable(msg.sender).transfer(address(this).balance);

        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send Failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!!");

        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //underscore means execute the rest of the codes underneath of the function with onlyOwner modifier.
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //View / Pure

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
