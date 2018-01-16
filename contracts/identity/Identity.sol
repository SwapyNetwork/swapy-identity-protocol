pragma solidity ^0.4.18;

contract Identity {
    
    address owner;
    bytes public financialData;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Identity(bytes _financialData) {
        owner = msg.sender;
        financialData = _financialData;
    }

    function forward(address to, uint256 value, bytes data) 
        onlyOwner
    {
        require(to.call.value(value)(data));
    }

    function setFinancialData(bytes _financialData)
        onlyOwner
    {   
        financialData = _financialData;
    }

    
}