pragma solidity ^0.5.14;

contract SmartTicket{
    address public sellerAddress;
    address public buyerAddress;
    bool public flag;
    bool public ticketflag;
   
    struct Buyer {
        address buyer;
        uint amountpaid;
        uint amountrefund;
    }
   
    struct Ticket {
        uint section;
        uint row;
        uint seat;
        uint time;
        uint price;
        bool paid;
        bool exists;
        string tickethash;
    }
   
    Buyer buyer;
    Ticket ticket;
   
    // event AddBuyer(address buyer);
    // event AddTicket(uint section, uint row, uint seat, uint time, uint price);
    // event RemoveTicket(uint section, uint row, uint seat, uint time, uint price);
    // event PayForTicket(uint amountpaid, uint amountrefund);
    // event Refund(uint amountpaid, uint amountrefund);
    // event Claim(uint amount);
   
    constructor(address seller, uint _section, uint _row, uint _seat, uint _time, uint _price) public {
        sellerAddress = seller;
        flag = true;
        addBuyer();
        addTicket(_section, _row, _seat, _time, _price);
    }
   
    function addBuyer() public {
        // require(msg.sender == buyerAddress, "Unauthorized user.");
        buyerAddress = msg.sender;
        buyer = Buyer(buyerAddress, 0, 0);
        // emit AddBuyer(buyer.buyer);
    }
   
    function addTicket(uint _section, uint _row, uint _seat, uint _time, uint _price) public {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        ticket = Ticket(_section, _row, _seat, _time, _price * 1 wei, false, true, "lmao");
        ticketflag = true;
        // emit AddTicket(_section, _row, _seat, _time, _price);
    }
   
    function removeTicket() public {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        require(now < ticket.time - 2 hours, "Too late");
        require(ticket.exists, "You don't have a ticket");
        buyer.amountrefund += buyer.amountpaid;
        buyer.amountpaid = 0;
        // emit RemoveTicket(ticket.section, ticket.row, ticket.seat, ticket.time, ticket.price);
        ticket = Ticket(0, 0, 0, 0, 0, false, false, "");
        ticketflag = false;
    }
   
    function payForTicket() public payable {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        require(ticket.exists, "You don't have a ticket");
        uint newamountpaid = buyer.amountpaid + msg.value;
        if (newamountpaid >= ticket.price){
            buyer.amountrefund += newamountpaid - ticket.price;
            newamountpaid = ticket.price;
            ticket.paid = true;
        }
        buyer.amountpaid = newamountpaid;
        // emit PayForTicket(buyer.amountpaid, buyer.amountrefund);
    }
   
    function redeemTicket() public view returns(string memory){
        require(msg.sender == buyerAddress, "Unauthorized user.");
        require(ticket.paid, "You havent paid for the ticket");
        require(now >= ticket.time - 5 minutes, "Please wait");
        require(ticket.exists, "You don't have a ticket");
        return ticket.tickethash;
    }
   
    function refund() public {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        uint amountpaid = buyer.amountpaid;
        uint amountrefund = buyer.amountrefund;
        Ticket memory currentticket = ticket;
        if (now > ticket.time - 2 hours){
            buyer.amountrefund = 0;
            if (!msg.sender.send(amountrefund))
                buyer.amountrefund = amountrefund;
            // else
            //     emit Refund(0, amountrefund);
        } else {
            buyer.amountpaid = 0;
            buyer.amountrefund = 0;
            removeTicket();
            if (!msg.sender.send(amountpaid + amountrefund)){
                buyer.amountpaid = amountpaid;
                buyer.amountrefund = amountrefund;
                addTicket(currentticket.section, currentticket.row, currentticket.seat, currentticket.time, currentticket.price);
            }
            // else
                // emit Refund(amountpaid, amountrefund);
        }
    }
   
    function getAmountPaid() public view returns(uint) {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        return buyer.amountpaid;
    }
   
    function getAmountRefund() public view returns(uint) {
        require(msg.sender == buyerAddress, "Unauthorized user.");
        return buyer.amountrefund;
    }
    
    function getContractDetails() public view returns (uint, uint, uint, uint, uint, uint, uint, bool, bool){
        return (buyer.amountpaid, buyer.amountrefund, ticket.section, ticket.row, ticket.seat, ticket.time, ticket.price, ticket.paid, ticket.exists);
    }
   
    function claim() public {
        require(msg.sender == sellerAddress, "Unauthorized user.");
        require(now > ticket.time - 2 hours);
        uint amountpaid = buyer.amountpaid;
        buyer.amountpaid = 0;
        if (!msg.sender.send(amountpaid)){
            buyer.amountpaid = amountpaid;
        }
        // else
        //     emit Claim(amountpaid);
    }
}

contract Contract {
    mapping(address => SmartTicket) contracts;
    mapping(address => bool) contractexists;
    address public seller;

    constructor() public {
        seller = msg.sender;
    }
    
    function createNewContract(uint _section, uint _row, uint _seat, uint _time, uint _price) public {
        if (!contractexists[msg.sender]){
            contractexists[msg.sender] = true;
            contracts[msg.sender] = new SmartTicket(seller, _section, _row, _seat, _time, _price);
        } else if (!contracts[msg.sender].ticketflag()){
            contracts[msg.sender].addTicket(_section, _row, _seat, _time, _price);
        }
    }

    function getAddress() public view returns (address) {
        return address(contracts[msg.sender]);
    }
}