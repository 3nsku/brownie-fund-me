// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

//interfaces combine down to ABI

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // you can use the constructor to initialize the contarct. before anyone can do anything else to it!
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // "paybale" is keyword used to describe a function that can make payments.
    function fund() public payable {
        //let say we want to have a minumun value for each transaction
        uint256 minimumUSD = 50 * 10**18; //the minimum in usd is 50$ nut converted in wei raise it to the 18th
        //with require, if a certain condition is not met, we'll stop executing and we are going to revert the transaction.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "you need to spend more ETH!"
        );

        //msg.sender and msg.value are keywords in every transaction
        //here we are adding the amount funded to anything that was funded before. (if any)
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getEntraceFee() public view returns (uint256) {
        uint256 mimimumUSD = 50 * 10**18; // 50000000000000000000
        uint256 price = getPrice(); // 4250000000000000000000
        uint256 precision = 1 * 10**18; // 1000000000000000000
        return (mimimumUSD * precision) / price; // this is like doing a proption to get the % -> 50 * 100 / 4250
    }

    // 0,01764

    //modifier: is used to change the hebavior of a function in a declarative way.
    // you can include this in a function and it will run the function only if require is true

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // the rest of the function is ran after "_;"
    }

    function withdraw() public payable onlyOwner {
        //transfer is a function we can call to send 1 eth from one address to an other!
        //"this" -> refers to the contract you are currently on
        //address(this), means we want the address of the contrac we are currently in!
        //with the ".balance" you can see the balance in ether of the contract.
        //the "msg.sender" is whoever called the function
        payable(msg.sender).transfer(address(this).balance);

        //reset everyones balance to zero.
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        //reset funders array to a new blanck array
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //Tuple is an objext of potencially different types whose number is a constant at comple-time!
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //leave empty all the variable returned that you will not be using!
        //becase answer is an int, you need to typecast it a.k.a. convert to uint256
        return uint256(answer * 10000000000); //return the price in 18 decimal places
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        //the eth price is expressed in wei which is has 18 more zeros
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}
