pragma solidity ^0.4.18;

import './Identity.sol';

contract MultiSigIdentity is Identity {

    uint required;
    mapping(address=>bool) owners;
    Transaction[] transactions;

    struct Transaction {
        bool active;
        address to;
        uint256 value;
        bytes data;
        address creator;
        uint signCount;
        mapping(address => bool) signers;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyNewOwner(address owner){
        require(!(isOwner(owner)));
        _;
    }

    modifier onlyOwner(){
        require(!(isOwner(msg.sender)));
        _;
    }

    modifier onlySigned(uint transactionId) {
        require(transactions[transactionId].signCount >= required);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    } 

    modifier validTransaction(address to, uint256 value, bytes data) {
        require(to != address(0));
        if (to == address(this)) {
            require(value == 0);
        }
        _;
    }

    modifier activeTransaction(uint transactionId) {
        require(transactions[transactionId].active);
        _;
    }

    function MultiSigIdentity (bytes _financialData, address[] _owners, uint _required) 
        Identity(_financialData, Type.COMPANY) 
        public 
    {
        setOwners(_owners);
        setRequired(_required);
    }

    function setOwners(address[] _owners)
        internal
    {
        for (uint i = 0; i < _owners.length; i++) {
            if (!isOwner(_owners[i])) {
                owners[_owners[i]] = true;
            }
        }
    }

    function addOwner(address newOwner)
        onlyWallet
        onlyNewOwner(newOwner)
        public 
        returns(bool)
    {
        owners[newOwner] = true;
        return true;
    }

    function removeOwner(address oldOwner) 
        onlyWallet
        public
        returns(bool)
    {
        require(isOwner(oldOwner));
        owners[oldOwner] = false;
        return true;
    }

    function changeRequired(uint _required) 
        onlyWallet 
        public
        returns(bool)
    {
        setRequired(_required);
        return true;
    }

    function setRequired(uint _required)
        internal
    {
        require(_required >= 0);
        required = _required;
    }
    
    function addTransaction(address to, uint256 value, bytes data) 
        onlyOwner
        validTransaction(to, value, data)
        public
        returns(bool)
    {
        Transaction memory transaction = Transaction(true,to,value,data,msg.sender,0,false);
        transactions.push(transaction);
        return true;
    }
    
    function signTransaction(uint transactionId) 
        onlyOwner
        activeTransaction(transactionId) 
        public
        returns(bool)
    {
        require(!checkSign(transactionId, msg.sender));
        transactions[transactionId].signCount++;
        transactions[transactionId].signers[msg.sender] = true;
        return true;
    }

    function executeTransaction(uint transactionId) 
        onlySigned(transactionId)
        notExecuted(transactionId)
        public 
        returns(bool)
    {
        Transaction memory transaction = transactions[transactionId];
        require(transaction.to.call.value(transaction.value)(transaction.data));
        transactions[transactionId].executed = true;
        return true;
    }

    function isOwner(address _owner) 
        view 
        internal
        returns(bool)
    {
        return owners[_owner];
    }

    function checkSign(uint transactionId, address signer)
        view
        internal
        returns(bool)
    {
        return transactions[transactionId].signers[signer];
    }
}