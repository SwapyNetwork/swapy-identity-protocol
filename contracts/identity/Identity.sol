pragma solidity ^0.4.18;

contract Identity {
    
    address owner;
    bytes public financialData;
    Type public identityType;

    // Identity types 
    enum Type {
        PERSONAL,
        COMPANY
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Identity(bytes _financialData, Type _identityType) 
        public
    {
        owner = msg.sender;
        identityType = _identityType;
        financialData = _financialData;
    }

    function forward(address to, uint256 value, bytes data) 
        payable
        onlyOwner
        public
    {
        if (msg.value != uint256(0)) {
            value = msg.value;    
        }
        require(to.call.value(value)(data));
    }

    function setFinancialData(bytes _financialData)
        onlyOwner
        public
    {
        financialData = _financialData;
    }

    
}