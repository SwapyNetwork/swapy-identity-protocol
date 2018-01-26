pragma solidity ^0.4.18;

import './Identity.sol';

contract MultiSigIdentity is Identity {

    uint required;
    address[] owners;
    bool autoExecute;
    
    Transaction[] transactions;
    uint256 transactionsCount;

    struct Transaction {
        address to;
        bytes data;
        uint256 value;
        address creator;
        uint signCount;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlySigned(uint transactionId) {
        require(transactions[transactionId].signCount >= required);
        _;
    }

    function MultiSigIdentity (bytes _financialData, address[] _owners, uint _required) 
        Identity(_financialData, Type.COMPANY) 
        public 
    {
        owners = _owners;
        required = _required;
    }

    function addOwner(address newOwner) onlyWallet {}
    function removeOwner(address oldOwner) onlyWallet {}
    function setRequired(uint _required) onlyWallet {}
    
    function addTransaction(address to, uint256 value, bytes data) {}
    function signTransaction(uint transactionId) onlySigned(transactionId) {}
    function executeTransaction(uint transactionId) onlySigned(transactionId) {}

}