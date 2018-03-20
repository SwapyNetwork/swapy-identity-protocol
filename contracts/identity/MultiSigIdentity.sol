pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract MultiSigIdentity {
    using SafeMath for uint256;
    
    bytes public financialData;
    uint256 public required;
    mapping(address=>bool) owners;
    uint256 public activeOwners;
    Transaction[] public transactions;


    struct Transaction {
        bool active;
        address to;
        uint value;
        bytes data;
        address creator;
        uint256 signCount;
        mapping(address => bool) signers;
        bool executed;
    }

    event TransactionCreated(address indexed creator, uint transactionId, address destination, uint256 value, bytes data, uint256 timestamp);
    event TransactionSigned(address indexed signer, uint indexed transactionId, uint256 timestamp);
    event TransactionExecuted(address indexed executor, uint indexed transactionId, uint256 timestamp);
    event RequiredChanged(uint256 required, uint256 timestamp);
    event OwnerAdded(address owner, uint256 timestamp);
    event OwnerRemoved(address owner, uint256 timestamp);
    event ProfileChanged(bytes financialData, uint256 timestamp);

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyNewOwner(address owner){
        require(!isOwner(owner));
        _;
    }

    modifier onlyOwner(){
        require(isOwner(msg.sender));
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

    function MultiSigIdentity (bytes _financialData, address[] _owners, uint256 _required)
        public 
    {
        financialData = _financialData;
        activeOwners = 0;
        setOwners(_owners);
        setRequired(_required);
    }

    function setOwners(address[] _owners)
        internal
    {
        for (uint i = 0; i < _owners.length; i++) {
            if (!isOwner(_owners[i])) {
                owners[_owners[i]] = true;
                activeOwners = activeOwners.add(1);
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
        activeOwners = activeOwners.add(1);
        OwnerAdded(newOwner, now);
        return true;
    }

    function removeOwner(address oldOwner) 
        onlyWallet
        public
        returns(bool)
    {
        require(isOwner(oldOwner));
        owners[oldOwner] = false;
        activeOwners = activeOwners.sub(1);
        OwnerRemoved(oldOwner, now);
        return true;
    }

    function changeRequired(uint256 _required) 
        onlyWallet 
        public
        returns(bool)
    {
        setRequired(_required);
        RequiredChanged(_required, now);
        return true;
    }

    function setFinancialData(bytes _financialData)
        onlyWallet
        public
        returns(bool)
    {
        financialData = _financialData;
        ProfileChanged(financialData, now);
        return true;
    }
    
    function setRequired(uint256 _required)
        internal
    {
        require(_required >= 0 && _required <= activeOwners);
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
        TransactionCreated(msg.sender,transactions.length - 1,to,value,data, now);
        return true;
    }
    
    function signTransaction(uint transactionId) 
        onlyOwner
        activeTransaction(transactionId) 
        public
        returns(bool)
    {
        require(!checkSign(transactionId, msg.sender));
        transactions[transactionId].signers[msg.sender] = true;
        transactions[transactionId].signCount = transactions[transactionId].signCount.add(1);
        TransactionSigned(msg.sender, transactionId, now);
        return true;
    }

    function executeTransaction(uint transactionId) 
        onlySigned(transactionId)
        notExecuted(transactionId)
        public 
        returns(bool)
    {
        Transaction storage transaction = transactions[transactionId];
        transactions[transactionId].executed = true;
        require(transaction.to.call.value(transaction.value)(transaction.data));
        TransactionExecuted(msg.sender, transactionId, now);
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