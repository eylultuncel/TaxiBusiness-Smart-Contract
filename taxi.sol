// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;


contract TaxiBusiness {
    
    // owner of the contract is manager
    address manager;

    // balance of the contract
    uint balance;

     // total amount for maintenance and tax fee (10 Ether)
    uint maintenanceFee;
    
    // last maintenance time (for 6 months period)
    uint lastMaintenance;
    
    // last divident pay time
    uint lastPayTime;
    
    // amount that participants needs to pay for entering (100 Ether)
    uint participationFee;

    // participant struct is for maximum of 9 participants
    struct Participant{
        address payable adr;
        uint balance;
    }

    // identity who buy/sell cars
    struct CarDealer{
        address payable adr;     
        uint balance;  
    }
    CarDealer carDealer;

    // id of owned car in the contract
    uint32 ownedCar;

    // struct for car which is proposed to buy/sell
    struct ProposedCar{
        uint32 carId;
        uint price;
        uint timeOfValidation;
        bool isApproved;
        uint approvedVotesCount;
    }
    // a car which is proposed by car dealer
    ProposedCar proposedCar;
    // a car which contract ownes and decides to sell it
    ProposedCar repurchaseCar;

    // taxi driver and its information
    struct TaxiDriver{
        address payable adr;
        uint salary;
        bool isApproved;
        uint approvedVotesCount;
        uint lastSalaryTime;
    }
    TaxiDriver taxiDriver;

    // list of addresses of participants adresses 
    address[] participantsAddresses;

    // addresses -> participant mapping
    mapping (address => Participant) participants;

    // addresses -> votes for car proposal mapping
    mapping (address => bool) carVotes;
    // addresses -> votes for driver proposal mapping
    mapping (address => bool) driverVotes;
    // addresses -> votes for repucrhase car proposal mapping
    mapping (address => bool) repurchaseVotes;



    // modifier to check if caller is manager
    modifier isManager() {
        require(msg.sender == manager, "Caller is not manager!");
        _;
    }
    
    // modifier to check if caller is car dealer
    modifier isCarDealer() {
        require(msg.sender == carDealer.adr, "Caller is not car dealer!");
        _;
    }
    
    // modifier to check if caller is participant
    modifier isParticipant() {
        require(participants[msg.sender].adr != address(0), "Caller is not participant!");
        _;
    }
    
    // modifier to check if caller is taxi driver
    modifier isDriver() {
        require(msg.sender == taxiDriver.adr, "Caller is not taxi driver!");
        _;
    }


    // constructor for contract which sets initial values
    constructor(address payable carDealerAddress){
        manager = msg.sender;
        balance = 0;
        maintenanceFee = 10 ether;
        participationFee = 100 ether;
        carDealer = CarDealer(carDealerAddress, 0);
    }


    // participants join the tax, business by this function
    // each participant needs to pay partificapationFee to join
    function joinAsParticipant() public payable {
        require(participantsAddresses.length < 9, "Maximum participant limit reached!");
        require(participants[msg.sender].adr == address(0), "You already joined!");
        require(msg.value >= participationFee, "You don't have enough ether to join!");
        
        participants[msg.sender] = Participant(msg.sender, 0 ether);
        participantsAddresses.push(msg.sender);
        balance += participationFee;
        uint refund = msg.value - participationFee;
        if(refund > 0) msg.sender.transfer(refund);

    }

    // only car dealer could call this function 
    // with given price and validation time, the car proposed to the system
    // and waits for majority of the participants to approve this proposal
    function carProposeToBusinesss (uint price, uint validTime) public isCarDealer {
        require(ownedCar == 0, "There is already a car in business!");
        
        proposedCar = ProposedCar(1, price, block.timestamp + (validTime * 1 days), false, 0);
         for(uint i = 0; i < participantsAddresses.length; i++){
            carVotes[participantsAddresses[i]] = false;
        }
    }


    // if majority of the particpants approved the proposal
    // purchaseCar() function is called, and the operations for buying this car is done
    function purchaseCar() public payable{
        require(balance>=proposedCar.price, "Contract doesn't have enough ether!");
        require(block.timestamp <= proposedCar.timeOfValidation, "Valid time for proposal has passed!");
        require(proposedCar.isApproved == false,"This car is already approved and bought!");
        require(proposedCar.approvedVotesCount > (participantsAddresses.length/2) ,"Not enough approval!");
        
        (carDealer.adr).transfer(proposedCar.price * 1 ether);
        balance -= proposedCar.price;
        ownedCar = proposedCar.carId;
        proposedCar.isApproved = true;
    }


    // only participants can call this function for approving the car proposal
    // if majority of the participants approved, it automatically call purchase car function
    function approvePurchaseCar() public isParticipant{
        require(proposedCar.carId == 1, "There aren't any proposed car in business!");
        require(!carVotes[msg.sender], "This participant already voted!");
        require(ownedCar == 0, "There is already a car in business!");
        
        proposedCar.approvedVotesCount += 1;
        carVotes[msg.sender] = true;
        if(proposedCar.approvedVotesCount > (participantsAddresses.length/2)){
            purchaseCar();
        }
    }


    // car dealer could propose a price to the owned car of the system
    // and wait for the  majority of the paricipants to approve
    // car dealer could pay for the car with this function  
    function repurchaseCarPropose(uint price, uint validTime) public payable isCarDealer{
        require(ownedCar != 0, "There is no owned car right now!");
        require(msg.value >= price, "You don't have enough ether to repurchase!");

        repurchaseCar = ProposedCar(1, price, block.timestamp + (validTime * 1 days), false, 0);
         for(uint i = 0; i < participantsAddresses.length; i++){
            repurchaseVotes[participantsAddresses[i]] = false;
        }
        balance += msg.value;
        uint refund = msg.value - (price * 1 ether);
        if(refund > 0) msg.sender.transfer(refund);
    }


    // owned car is sold through this function
    function repurchaseCarOp() public payable{
        require(balance>=repurchaseCar.price, "Contract doesn't have enough ether!");
        require(block.timestamp <= repurchaseCar.timeOfValidation, "Valid time for proposal has passed!");
        require(repurchaseCar.isApproved == false,"This car already sold!");
        require(repurchaseCar.approvedVotesCount > (participantsAddresses.length/2) ,"Not enough approval!");
        
        ownedCar = 0 ;
    }

    // participants can call this function to approve sell proposal of the owned car
    function approveSellProposal() public payable isParticipant{
        require(repurchaseCar.carId == 1, "There is no repurchased car proposal in business!");
        require(!repurchaseVotes[msg.sender], "This participant already voted!");
        
        repurchaseCar.approvedVotesCount += 1;
        repurchaseVotes[msg.sender] = true;

        if(repurchaseCar.approvedVotesCount > (participantsAddresses.length/2)){
            repurchaseCarOp();
        }
    }


    // anyone could call this function to propose itself for a taxi driver job
    // if majority of the participants approved, then the sender set as a taxi driver automatically
    function proposeDriver(uint expectedSalary) public payable{
        require(ownedCar == 1, "There is no owned car!");
        require(!taxiDriver.isApproved, "There is a taxi driver already!");
        
        taxiDriver = TaxiDriver(msg.sender, expectedSalary, false, 0,  block.timestamp - (30 days));
        for(uint i = 0; i < participantsAddresses.length; i++){
            driverVotes[participantsAddresses[i]] = false;
        }
    }

    // if majority of the participants approved the proposed driver, this function called
    // operations for setting the person as taxi driver is done in this function
    function setDriver() public payable{
        require(taxiDriver.isApproved == false, "This driver already approved!");
        require(taxiDriver.approvedVotesCount > (participantsAddresses.length/2), "Not enough votes!");
        
        taxiDriver.isApproved = true;
        taxiDriver.approvedVotesCount = 0;
        for(uint i = 0; i < participantsAddresses.length; i++){
            driverVotes[participantsAddresses[i]] = false;
        }
    }

    // participants can call this function to approve proposed taxi driver 
    function approveDriver() public payable isParticipant{
        require(taxiDriver.salary != 0, "There is no proposed driver yet!");
        require(taxiDriver.isApproved == false, "Already approve the driver!");
        require(!driverVotes[msg.sender], "This participant already voted!");
        
        taxiDriver.approvedVotesCount += 1;
        driverVotes[msg.sender] = true;
        if (taxiDriver.approvedVotesCount > (participantsAddresses.length/2)){
            setDriver();
        }
    }

    // this function is for firing taxi driver
    function fireDriver() public payable{
        require(taxiDriver.isApproved == true, "There aren't any approved driver!");
        
        if ( (block.timestamp - taxiDriver.lastSalaryTime) < 30 days){
            (taxiDriver.adr).transfer(taxiDriver.salary * 1 ether);
            balance -= taxiDriver.salary;
        }
        delete taxiDriver;
    }

    // participants could start a voting for firing the taxi driver
    // if majority of the participants approves, then the driver get fired
    function proposeFireDriver() public payable isParticipant{
        require(taxiDriver.isApproved == true, "There aren't any approved driver!");
        
        taxiDriver.approvedVotesCount += 1;
        driverVotes[msg.sender] = true;
        if (taxiDriver.approvedVotesCount > (participantsAddresses.length/2)){
            fireDriver();
        }
    }

    // taxi driver could leave its job by his/her intention
    function leaveJob() public payable isDriver{
        require(taxiDriver.isApproved ,"Caller is not an approved driver!");
        fireDriver();
    }

    // customers can pay their charges by with this function
    function getCharge() public payable {
        require(taxiDriver.isApproved ,"There aren't any approved driver!");
        balance += msg.value;
    }

    // taxi driver can call this function to get its salary every month
    function getSalary() public payable isDriver{
        require(taxiDriver.isApproved , "Caller is not an approved driver!");
        require((block.timestamp - taxiDriver.lastSalaryTime) >= 30 days, "Salary is already paid this month!");
        
        (taxiDriver.adr).transfer(taxiDriver.salary * 1 ether);
        balance -= taxiDriver.salary;
        taxiDriver.lastSalaryTime = block.timestamp;
    }

    // this function is for paying fixed car expenses to the car dealer in every 6 months
    function carExpenses() public payable isParticipant{
        require((block.timestamp - lastMaintenance) >= 180 days, "Car expenses are already paid!");
        require(balance >= maintenanceFee, "Not enough ether in contract!");
        
        (carDealer.adr).transfer(maintenanceFee );
        balance -= maintenanceFee;
        lastMaintenance = block.timestamp;
    }

    // this function is for dividing the total profit between all participants in every 6 months
    function payDivident() public payable isParticipant{
        require((block.timestamp-lastPayTime)>= 180 days, "Already divided to participants!");
        require(balance > participationFee * participantsAddresses.length, "There is no profit right now!");
        
        uint dividend = (balance - (participationFee * participantsAddresses.length) - maintenanceFee - (6*taxiDriver.salary)) / participantsAddresses.length;
        for(uint i = 0; i < participantsAddresses.length; i++){
            participants[participantsAddresses[i]].balance += dividend;
        }
        balance = balance - (dividend * participantsAddresses.length);
        lastPayTime = block.timestamp; 
    }

    // each participant could get their share by this function
    // if the balance didn't divided already, then call payDivident() function firstly
    function getDivident() public payable isParticipant{
        require(participants[msg.sender].balance > 0, "There is no ether in your balance");
        
        (msg.sender).transfer(participants[msg.sender].balance );
        participants[msg.sender].balance = 0;
    }
  
    // fallback function
    fallback () external payable {
    }
    receive () external payable {
    }

}


