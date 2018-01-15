pragma solidity ^0.4.18;

contract Identity {
    
    bytes public financialData;

    function Identity(bytes _financialData) {
        financialData = _financialData;
    }

    function forward(address to, uint256 value, bytes data) {
        require(to.call.value(value)(data));
    }

    
}