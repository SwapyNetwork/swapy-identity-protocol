pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Multi Signature Identity 
 * @dev Defines a multi signature identity with its owners, profile data, required number of signatures and transaction as well. 
 * Allows execute transaction as a proxy.
 */
contract MultiSigIdentity {
    /**
     * Add safety checks for uint operations
     */
    using SafeMath for uint256;
    
    /**
     * Storage
     */
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

    /**
     * Events   
     */
    event LogTransactionCreated(address indexed creator, uint transactionId, address destination, uint256 value, bytes data, uint256 timestamp);
    event LogTransactionSigned(address indexed signer, uint indexed transactionId, uint256 timestamp);
    event LogTransactionExecuted(address indexed executor, uint indexed transactionId, uint256 timestamp);
    event LogRequiredChanged(uint256 required, uint256 timestamp);
    event LogOwnerAdded(address owner, uint256 timestamp);
    event LogOwnerRemoved(address owner, uint256 timestamp);
    event LogProfileChanged(bytes financialData, uint256 timestamp);

    /**
     * Modifiers   
     */
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
    
    /**
     * @param _financialData Profile hash
     * @param _owners Owner addresses
     * @param _required Required number of signatures to allow a transaction 
     */ 
    function MultiSigIdentity (bytes _financialData, address[] _owners, uint256 _required)
        public 
    {
        financialData = _financialData;
        activeOwners = 0;
        setOwners(_owners);
        setRequired(_required);
    }

    /**
     * @dev Set multi signature owners
     * @param _owners Owner addresses
     */ 
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

    /**
     * @dev Add a new owner. ** Only accepted by a multi signature transaction
     * @param newOwner Address of the new owner
     * @return Success
     */ 
    function addOwner(address newOwner)
        onlyWallet
        onlyNewOwner(newOwner)
        public 
        returns(bool)
    {
        owners[newOwner] = true;
        activeOwners = activeOwners.add(1);
        emit LogOwnerAdded(newOwner, now);
        return true;
    }

    /**
     * @dev Remove an owner. ** Only accepted by a multi signature transaction
     * @param oldOwner Address of the new owner
     * @return Success
     */
    function removeOwner(address oldOwner) 
        onlyWallet
        public
        returns(bool)
    {
        require(isOwner(oldOwner));
        owners[oldOwner] = false;
        activeOwners = activeOwners.sub(1);
        emit LogOwnerRemoved(oldOwner, now);
        return true;
    }

    /**
     * @dev Change required number of signatures to execute a transaction. ** Only accepted by a multi signature transaction
     * @param _required New requirement
     * @return Success
     */
    function changeRequired(uint256 _required) 
        onlyWallet 
        public
        returns(bool)
    {
        setRequired(_required);
        emit LogRequiredChanged(_required, now);
        return true;
    }
    
    /**
     * @dev Change the profile data hash. ** Only accepted by a multi signature transaction
     * @param _financialData New profile's hash
     * @return Success
     */
    function setFinancialData(bytes _financialData)
        onlyWallet
        public
        returns(bool)
    {
        financialData = _financialData;
        emit LogProfileChanged(financialData, now);
        return true;
    }
    
    /**
     * @dev Set a new required number of signatures to execute a transaction. 
     * @param _required New requirement
     */    
    function setRequired(uint256 _required)
        internal
    {
        require(_required <= activeOwners && _required >= 0);
        required = _required;
    }

    /**
     * @dev Create a multi signature transaction
     * @param to Destiny of transaction
     * @param value Transaction value
     * @param data Encoded data of transaction.
     * @return Success
     */
    function addTransaction(address to, uint256 value, bytes data) 
        onlyOwner
        validTransaction(to, value, data)
        external
        returns(uint256)
    {
        Transaction memory transaction = Transaction(true,to,value,data,msg.sender,0,false);
        transactions.push(transaction);
        emit LogTransactionCreated(msg.sender,transactions.length - 1,to,value,data, now);
        return transactions.length - 1;
    }
    
    /**
     * @dev Sign a transaction
     * @param transactionId Id of multi signature transaction 
     * @return Success
     */
    function signTransaction(uint transactionId) 
        onlyOwner
        activeTransaction(transactionId) 
        external
        returns(bool)
    {
        require(!checkSign(transactionId, msg.sender));
        transactions[transactionId].signers[msg.sender] = true;
        transactions[transactionId].signCount = transactions[transactionId].signCount.add(1);
        emit LogTransactionSigned(msg.sender, transactionId, now);
        return true;
    }

    /**
     * @dev Execute a multi signature transaction if it's allowed 
     * @param transactionId Id of multi signature transaction 
     * @return Success
     */
    function executeTransaction(uint transactionId) 
        onlySigned(transactionId)
        notExecuted(transactionId)
        public 
        returns(bool)
    {
        Transaction storage transaction = transactions[transactionId];
        transactions[transactionId].executed = true;
        require(transaction.to.call.value(transaction.value)(transaction.data));
        emit LogTransactionExecuted(msg.sender, transactionId, now);
        return true;
    }

    /**
     * @dev Checks if the address is an owner
     * @param _owner Address to be checked 
     * @return is Owner
     */
    function isOwner(address _owner) 
        view 
        internal
        returns(bool)
    {
        return owners[_owner];
    }

    /**
     * @dev Checks if address given have signed the transaction
     * @param transactionId Id of multi signature transaction 
     * @param signer Address to be checked 
     * @return have signed
     */
    function checkSign(uint transactionId, address signer)
        view
        internal
        returns(bool)
    {
        return transactions[transactionId].signers[signer];
    }
}