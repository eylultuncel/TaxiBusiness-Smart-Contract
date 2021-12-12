// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;


contract TaxiBusiness {
    
    address manager;

    uint balance;

    struct Participant{
        address adr;
        uint balance;
    }

    struct CarDealer{
        address adr;       
        uint id;
        uint proposedPrice;
        uint timeOfValidation;
        bool isApproved;
    }

    struct TaxiDriver{
        address adr;
        uint salary;
        uint balance;
        bool isApproved;
        uint approvedVoteCount;
        uint lastSalaryTime;
    }

    CarDealer carDealer;

    TaxiDriver taxiDriver;

     // addresses -> participant mapping
    mapping (address => Participant) participants;
    
    // list of addresses of participants to use in vote counting
    address[] participantsAddresses;

    // total amount for maintenance and tax (fixed 10 Ether)
    uint maintenanceFee;
    
    // last maintenance time (for checking 6 months period)
    uint lastMaintenance;
    
    // last divident pay time
    uint lastPayTime;
    
    // amount that participants needs to pay for entering, fixed 100 Ether
    uint participationFee;
    
    // the ID of the car which is approved 
    uint carID;




    

    // modifier to check if caller is manager
    modifier isManager() {
        require(msg.sender == manager, "Caller is not manager");
        _;
    }
    
    // modifier to check if caller is car dealer
    modifier isCarDealer() {
        require(msg.sender == carDealer.adr, "Caller is not car dealer");
        _;
    }
    
    // modifier to check if caller is participant
    modifier isParticipant() {
        require(participants[msg.sender].adr != address(0), "Caller is not participant");
        _;
    }
    
    // modifier to check if caller is driver
    modifier isDriver() {
        require(msg.sender == taxiDriver.adr, "Caller is not driver");
        _;
    }



    constructor(){
        manager = msg.sender;
        balance = 0;
        maintenanceFee = 10 ether;
        lastMaintenance = block.timestamp;
        lastPayTime = block.timestamp;
        participationFee = 80 ether;
    }


    /**
     * max 9 participants can join
     * caller of this function must pay 100 or more ether
     * excess ether will be returned
     */
    function joinAsParticipant() public payable {
        require(participantsAddresses.length < 9, "No place left for participants");
        require(participants[msg.sender].adr == address(0), "You already joined as participant");
        require(msg.value >= participationFee, "You don't have enough ether to join");
        participants[msg.sender] = Participant(msg.sender, 0 ether);
        participantsAddresses.push(msg.sender);
        balance += participationFee;
        uint refund = msg.value - participationFee;
        if(refund > 0) msg.sender.transfer(refund);
    }


    /**
     * customers call this function to pay charge
     */
    function payTaxiCharge() public payable {
        balance += msg.value;
    }
    
  
    /**
     * fallback function
     */
    fallback () external payable {
    }

    receive () external payable {

    }


}

