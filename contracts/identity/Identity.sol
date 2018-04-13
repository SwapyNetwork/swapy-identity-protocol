pragma solidity ^0.4.21;

/**
 * @title Identity 
 * @dev Defines a personal identity with its owner and profile data. Allows execute transaction as a proxy
 */
contract Identity {
    
    /**
     * Storage
     */
    address public owner;
    bytes public financialData;

    /**
     * Events   
     */
    event LogForwarded(address destination, uint256 value, bytes data, uint256 timestamp);
    event LogProfileChanged(bytes financialData, uint256 timestamp);

    /**
     * Modifiers   
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @param _owner Address of Identity's owner
     * @param _financialData Profile hash
     */   
    function Identity(address _owner, bytes _financialData) 
        public
    {
        owner = _owner;
        financialData = _financialData;
    }

    /**
     * @dev Use the Identity as a proxy to execute transactions
     * @param to Destiny of transaction
     * @param value Transaction value
     * @param data Encoded data of transaction.
     * @return Success
     */  
    function forward(address to, uint256 value, bytes data) 
        payable
        onlyOwner
        external
        returns(bool)
    {
        require(to.call.value(value)(data));
        emit LogForwarded(to, value, data, now);
        return true;
    }

    /**
     * @dev Update Identity's profile
     * @param _financialData New profile data's hash
     * @return Success
     */
    function setFinancialData(bytes _financialData)
        onlyOwner
        external
        returns(bool)
    {
        financialData = _financialData;
        emit LogProfileChanged(financialData, now);
        return true;
    }

    
}
