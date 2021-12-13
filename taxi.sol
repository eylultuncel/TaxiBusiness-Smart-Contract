// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;


contract TaxiBusiness {
    
    address manager;

    uint balance;

    struct Participant{
        address payable adr;
        uint balance;
    }

    struct CarDealer{
        address payable adr;     
        uint balance;  
    }

    CarDealer carDealer;

    struct ProposedCar{
        uint32 carId;
        uint price;
        uint timeOfValidation;
        bool isApproved;
        uint approvedVotesCount;
    }

    ProposedCar proposedCar;

    // repurchase car olayı yok!

    struct TaxiDriver{
        address payable adr;
        uint salary;
        bool isApproved;
        uint approvedVotesCount;
        uint lastSalaryTime;
    }

    TaxiDriver taxiDriver;

    uint32 ownedCar;


    // addresses -> participant mapping
    mapping (address => Participant) participants;
    mapping (address => bool) carVotes;
    mapping (address => bool) driverVotes;
    mapping (address => bool) repurchaseVotes;


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



    constructor(address payable newCarDealer){
        manager = msg.sender;
        balance = 0;
        maintenanceFee = 10 ether;
        participationFee = 80 ether;
        carDealer = CarDealer(newCarDealer, 0);
    }


    function joinAsParticipant() public payable {
        require(participantsAddresses.length < 9, "Maximum participant count reached");
        require(participants[msg.sender].adr == address(0), "You already joined as participant");
        require(msg.value >= participationFee, "You don't have enough ether to join");
        participants[msg.sender] = Participant(msg.sender, 0 ether);
        participantsAddresses.push(msg.sender);
        balance += participationFee;
        uint refund = msg.value - participationFee;
        if(refund > 0) msg.sender.transfer(refund);

    }


    function carProposeToBusinesss (uint price, uint validTime) public isCarDealer {
        require(ownedCar == 0, "There is already a car in business");
        proposedCar = ProposedCar(1, price, block.timestamp + (validTime * 1 days), false, 0);
        
         for(uint i = 0; i < participantsAddresses.length; i++){
            carVotes[participantsAddresses[i]] = false;
        }
    }


    function approvePurchaseCar() public isParticipant{
        require(!carVotes[msg.sender], "This participant already voted!");
        require(ownedCar == 0, "There is already a car in business");
        proposedCar.approvedVotesCount += 1;
        carVotes[msg.sender] = true;

        if(proposedCar.approvedVotesCount >= (participantsAddresses.length/2)){
            purchaseCar();
        }
    }

    function purchaseCar() public payable{
        require(balance>=proposedCar.price, "Contract doesn't have enough ether!");
        require(block.timestamp <= proposedCar.timeOfValidation, "Valid time for proposal has passed!");
        require(proposedCar.isApproved == false,"this car already approved");
        require(proposedCar.approvedVotesCount >= (participantsAddresses.length/2) ,"Not enough approval!");
        balance -= proposedCar.price;
        if(!carDealer.adr.send(proposedCar.price)){
            balance += proposedCar.price;
            revert();
        }
        ownedCar = proposedCar.carId;
        proposedCar.isApproved = true;
    }

    function proposeDriver(uint expectedSalary) public payable{
        require(ownedCar == 1, "no owned car");
        require(!taxiDriver.isApproved, "There is a taxi driver already!");
        taxiDriver = TaxiDriver(msg.sender, expectedSalary, false, 0, block.timestamp);
        for(uint i = 0; i < participantsAddresses.length; i++){
            driverVotes[participantsAddresses[i]] = false;
        }
    }

    function setDriver() public payable{
        require(taxiDriver.isApproved == false, "this driver already approved");
        require(taxiDriver.approvedVotesCount >= (participantsAddresses.length/2), "not enough votes");
        taxiDriver.isApproved = true;
        taxiDriver.approvedVotesCount = 0;
        for(uint i = 0; i < participantsAddresses.length; i++){
            driverVotes[participantsAddresses[i]] = false;
        }
    }

    function approveDriver() public isParticipant{
        require(!driverVotes[msg.sender], "This participant already voted!");
        taxiDriver.approvedVotesCount += 1;
        driverVotes[msg.sender] = true;

        if (taxiDriver.approvedVotesCount >= (participantsAddresses.length/2)){
            setDriver();
        }
    }


    function fireDriver() public payable{
        require(taxiDriver.isApproved == true, "No approved driver!");
        balance -= taxiDriver.salary;
        if(!taxiDriver.adr.send(taxiDriver.salary)){
            balance += taxiDriver.salary;
            revert();
        }
        delete taxiDriver;
    }

    function proposeFireDriver() public payable{
        require(taxiDriver.isApproved == true, "there aren't any approved driver");
        taxiDriver.approvedVotesCount += 1;
        driverVotes[msg.sender] = true;

        if (taxiDriver.approvedVotesCount >= (participantsAddresses.length/2)){
            fireDriver();
        }
    }

    function leaveJob() public isDriver{
        fireDriver();
    }


    function getCharge() public payable {
        balance += msg.value;
    }

    function getSalary() public isDriver{
        require((block.timestamp - taxiDriver.lastSalaryTime) >= 30 days, "no payments again in same month");
        balance -= taxiDriver.salary;
        if( !taxiDriver.adr.send(taxiDriver.salary)){
            balance += taxiDriver.salary;
            revert();
        }
        taxiDriver.lastSalaryTime = block.timestamp;
    }

    function carExpenses() public isParticipant{
        require((block.timestamp - lastMaintenance) >= 180 days, "already paid in those 6 months");
        balance -= maintenanceFee;
        if( !carDealer.adr.send(maintenanceFee)){
            balance += maintenanceFee;
            revert();
        }
        lastMaintenance = block.timestamp;
    }


    function payDivident() public isParticipant{
        require((block.timestamp-lastPayTime)>= 180 days, "paid already");
        require(balance > participationFee * participantsAddresses.length, "There is no profit right now");
        uint dividend = (balance - (participationFee * participantsAddresses.length) - maintenanceFee - (6*taxiDriver.salary)) / participantsAddresses.length;
        for(uint i = 0; i < participantsAddresses.length; i++){
            participants[participantsAddresses[i]].balance += dividend;
        }
        balance = 0;
        lastPayTime = block.timestamp; 
    }

    function getDivident() public isParticipant{
        require(participants[msg.sender].balance > 0, "There is no ether in your balance");
        if(!msg.sender.send(participants[msg.sender].balance)){
            revert();
        }
        participants[msg.sender].balance = 0;
    }
    
  
    /**
     * fallback function
     */
    fallback () external payable {
    }

    receive () external payable {

    }


}

