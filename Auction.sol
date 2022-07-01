// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract aution{
    //VARIBALES//
    struct item{
        uint256 id;
        address owner;
        string name;
        uint256 startPrice;
        uint256 highestBid;
        bool isOpen;
    }
    struct member{
        uint numSold;
        uint activeListings;
        bool isPremium;
        uint numViolations;
        uint numReports;
        bool goodStanding;
    }
    struct report{
        uint reportID;
        uint listingID;
        address reporter;
        score rating;
        string message;
    }
    enum score{BAD, FINE, EXCELLENT}
    mapping(address => member) memberRegistry;
    uint256 private counter = 0;
    uint256 private counterR = 0;
    mapping(uint256 => item) listingRegistry;
    address[] public highestBidder;
    address private admin;
    report[] public reportDirectory;
    //CONSTRUCTOR//
    constructor(){
        admin = msg.sender;
    }
    //MODIFIERS//
    //Admin commands
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    //Only allows members with good standing
    modifier onlyGoodStanding(){
        require(memberRegistry[msg.sender].goodStanding == true);
        _;
    }
    //METHODS//
    //Registers member
    function doMemberRegister() public{
        memberRegistry[msg.sender] = member (0, 0, false, 0, 0, true);
    }
    //Checks and upgrades account if member has 3 or more confirmed sold listings
    function becomePremium() public onlyGoodStanding{
        require(memberRegistry[msg.sender].numSold >= 3, "Must have 3 or more items sold and delivered");
        memberRegistry[msg.sender].isPremium = true;
    }
    //Adds member listing based on inputted item name and starting bid price
    function addListing(string memory itemName, uint256 startPrice) public onlyGoodStanding{
        if (memberRegistry[msg.sender].activeListings >= 1){
            require(memberRegistry[msg.sender].isPremium, "You can only have 1 active listings as a non-premium member");
        }
        item memory listing = item (counter, msg.sender, itemName, startPrice, startPrice, true);
        listingRegistry[counter] = listing;
        counter++;
        highestBidder.push();
        memberRegistry[msg.sender].activeListings++;
    }
    //Allows member to bid a price greater than or equal to 1 more than the current highest bid
    function doBid(uint256 listingID, uint256 bidPrice) public onlyGoodStanding{
        require(msg.sender != listingRegistry[listingID].owner, "You cannot bid on your own listing");
        require(listingRegistry[listingID].isOpen == true, "This listing is not open");
        require(bidPrice >= listingRegistry[listingID].highestBid + 1, "You must bid a minimum of 1 more than the highest bid");
        listingRegistry[listingID].highestBid = bidPrice;
        highestBidder[listingID] == msg.sender;
    }
    //Allows the owner of the listing or admin to close the auction
    function closeAuction(uint256 listingID) public {
        require(msg.sender == listingRegistry[listingID].owner || msg.sender == admin, "Only the owner of the listing or admins can close the auciton");
        listingRegistry[listingID].isOpen = false;
    }
    //Allows the owner of the listing or admin to reopen the auction if there was an issue 
    function reopenAuction(uint256 listingID) public {
        require(msg.sender == listingRegistry[listingID].owner || msg.sender == admin, "Only the owner of the listing or admins can reopen the auciton");
        listingRegistry[listingID].isOpen = false;
        listingRegistry[listingID].highestBid = listingRegistry[listingID].startPrice;
    }
    //Allows the buyer of a listing to confirm delivery of item
    function confirmDelivery(uint256 listingID) public{
        require(listingRegistry[listingID].isOpen == false, "This auction has not been closed");
        require(msg.sender == highestBidder[listingID] || msg.sender == admin, "Only the buyer or admins can confirm delivery");
        memberRegistry[listingRegistry[listingID].owner].activeListings--;
        memberRegistry[listingRegistry[listingID].owner].numSold++;
    }
    //Retrieves listing based on ID
    function getListing(uint256 listingID) public view returns(string memory name){
        return listingRegistry[listingID].name;
    }
    //Retrieves highest current bidder of the listing
    function getWinner(uint256 listingID) public view returns(address winner){
        return highestBidder[listingID];
    }
    //Allows member to report a listing if it violates the guidelines
    function reportListing(uint256 listingID, score review, string memory message) public{
        report memory newReport = report (counterR, listingID, msg.sender, review, message);
        counterR++;
        reportDirectory.push(newReport);
        memberRegistry[listingRegistry[listingID].owner].numReports++;
    }
    //Admin commands//
    //Allows admin to add a violation to member's account
    function addViolation(address violator) public onlyAdmin{
        memberRegistry[violator].numViolations++;
    }
    //Allows admin to change a member's standing
    function changeStanding(address violator) public onlyAdmin{
        require(memberRegistry[violator].numViolations > 2);
        if (memberRegistry[violator].goodStanding == true){
            memberRegistry[violator].goodStanding = false;
        }
        else{
            memberRegistry[violator].goodStanding = true;
        }
        
    }
}