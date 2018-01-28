pragma solidity ^0.4.18;

contract Identity {
    
    address owner;
    bytes public financialData;

    event Forwarded( address destination, uint256 value, bytes data);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Identity(address _owner, bytes _financialData) 
        public
    {
        owner = _owner;
        financialData = _financialData;
    }

    function forward(address to, uint256 value, bytes data) 
        payable
        onlyOwner
        public
    {
        require(to.call.value(value)(data));
        Forwarded(to, value, data);
    }


    function setFinancialData(bytes _financialData)
        onlyOwner
        public
    {
        financialData = _financialData;
    }

    
}