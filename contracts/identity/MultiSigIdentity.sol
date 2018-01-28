pragma solidity ^0.4.18;

import './Identity.sol';

contract MultiSigIdentity is Identity {

    uint required;
    mapping(address=>bool) owners;
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

    modifier onlyNewOwner(address owner){
        require(!(isOwner(owner)));
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
    
    function addTransaction(address to, uint256 value, bytes data) {}
    function signTransaction(uint transactionId) onlySigned(transactionId) {}
    function executeTransaction(uint transactionId) onlySigned(transactionId) {}

    function isOwner(address _owner) 
        view 
        internal
        returns(bool)
    {
        return owners[_owner];
    }
}