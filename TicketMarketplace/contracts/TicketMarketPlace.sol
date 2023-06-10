//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TicketMarketPlace {

    using SafeMath for uint8;

    mapping(uint8 => mapping(address => uint8)) public ticketBalances;
    mapping(uint8 => uint8) public ticketPrices;
    mapping(uint8 => uint8) public ticketStock;

    address private owner;

    event TicketPurchased(address buyer, uint8 ticketEventId);
    event TicketsPurchased(address buyer, uint8 ticketEventId, uint8 quantity);
    event TicketsSent(address sender, address[] recipients, uint8 ticketEventId, uint8 quantity);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function setPriceAndStock(uint8 ticketEventId, uint8 ticketPrice, uint8 initialStock) public onlyOwner {
        // @audit-issue Tickets can be updated/setted more than once. Should check ticket doesn't exist 
        require(ticketEventId > 0, "Id must be greater than 0");
        require(ticketPrice > 0, "Price must be greater than 0");
        require(initialStock > 0, "Stock must be greater than 0");
        ticketPrices[ticketEventId] = ticketPrice;
        ticketStock[ticketEventId] = initialStock;
    }

    function buyTicket(uint8 ticketEventId) public payable {
        //@audit-info useless require. We could check the same just with ticketStock
        require(ticketPrices[ticketEventId] > 0, "Ticket does not exist"); 
        require(ticketStock[ticketEventId] > 0, "Ticket is sold out");
        require(msg.value >= ticketPrices[ticketEventId], "Insufficient funds");

        ticketStock[ticketEventId] = uint8(ticketStock[ticketEventId].sub(1));
        ticketBalances[ticketEventId][msg.sender] = uint8(ticketBalances[ticketEventId][msg.sender].add(1));
        emit TicketPurchased(msg.sender, ticketEventId);

        if (msg.value > ticketPrices[ticketEventId]) {
            //@audit-issue loss precision 
            uint8 change = uint8(uint8(msg.value).sub(ticketPrices[ticketEventId]));
            // @audit transfer is not recomended. Use call
            payable(msg.sender).transfer(change);
        }
    }

    function buyMultipleTickets(uint8 ticketEventId, uint8 quantity) public payable {
        //@audit-info useless require. We could check the same just with ticketStock
        require(ticketPrices[ticketEventId] > 0, "Ticket does not exist");
        require(ticketStock[ticketEventId] >= quantity, "Insufficient ticket stock");
        require(msg.value >= ticketPrices[ticketEventId].mul(quantity), "Insufficient funds");

        ticketStock[ticketEventId] = uint8(ticketStock[ticketEventId].sub(quantity));
        ticketBalances[ticketEventId][msg.sender] = uint8(ticketBalances[ticketEventId][msg.sender].add(quantity));
        emit TicketsPurchased(msg.sender, ticketEventId, quantity);

        //@audit-issue loss precision 
        uint8 totalPrice = uint8(ticketPrices[ticketEventId].mul(quantity));
        if (msg.value > totalPrice) {
            //@audit-issue loss precision 
            uint8 change = uint8(uint8(msg.value).sub(totalPrice));
            // @audit transfer is not recomended
            payable(msg.sender).transfer(change);
        }
    }

     function sendTicketsToFriends(address[] memory friends, uint8 ticketEventId, uint8 quantity) public returns (bool){
        
        //@audit-issue loss precision 
        uint8 totalAmount = uint8(friends.length * quantity);
        require(quantity > 0, "Value can't be 0");
        require(ticketBalances[ticketEventId][msg.sender] >= totalAmount, "Insufficient ticket balance");

        ticketBalances[ticketEventId][msg.sender] = uint8(ticketBalances[ticketEventId][msg.sender].sub(totalAmount));

        for (uint8 i = 0; i < friends.length; i++) {
            //@audit non-zero friend address is not checked
            address friend = friends[i];
            ticketBalances[ticketEventId][friend] = uint8(ticketBalances[ticketEventId][friend].add(quantity));
        }

        emit TicketsSent(msg.sender, friends, ticketEventId, quantity);
        return true;
    }

    function getBalance(uint8 ticketEventId) public view returns (uint8){
        return uint8(ticketBalances[ticketEventId][msg.sender]);
    }

    //@audit is not possible to withdraw the contract funds
    //@audit-info Functions visibility could be modified to external to save gas 
}
