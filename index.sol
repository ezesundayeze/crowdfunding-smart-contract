//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public admin;
    uint256 public noOfContributors;
    uint256 public minimumContribution;
    uint256 public deadline;
    uint256 public goal;
    uint256 public raisedAmount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address =>bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    constructor(
        uint256 _goal,
        uint256 _minimumContribution,
        uint256 _deadLine
    ) {
        goal = _goal;
        minimumContribution = _minimumContribution;
        deadline = block.timestamp + _deadLine;
        admin = msg.sender;
    }

    modifier contributionEligibility() {
        if (contributors[msg.sender] != 0) {
            revert("Already contributed");
        }
        _;
    }


    modifier onlyAdmin(){
        require(msg.sender==admin, "Not permitted");
        _;
    }
    // Create events
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent (address _recipient, uint _value);

    function contribute() public payable contributionEligibility {
        require(block.timestamp < deadline, "Deadline has passed");
        require(
            msg.value >= minimumContribution,
            "Amount is greater than minimum transaction"
        );

        // updat the number of contributors
        noOfContributors++;

        //update contributors list
        contributors[msg.sender] += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline);
        require(contributors[msg.sender] > 0);
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    function createRequest (string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);


    }

    function voteForRequest(uint _requestNo) public { 
        require(contributors[msg.sender]> 0, "You must be a contributor");
        Request  storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have voted already");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }


    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount >=goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "Request completed");
        require(thisRequest.noOfVoters> noOfContributors/2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }

    
}
