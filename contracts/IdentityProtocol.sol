pragma solidity ^0.4.18;

import './identity/Identity.sol';

contract IdentityProtocol {

    address public owner;

    mapping(address => mapping(address => uint)) identities;

    event IdentityCreated(address _creator, address _identity);
    event ForwardedTo(address _identity, address _owner, address _destination, uint256 _value, bytes data);

    modifier onlyIdentityOwner(address identity) {
        require(isIdentityOwner(identity, msg.sender));
        _;
    }
    
    function IdentityProtocol() 
        public
    {
        owner = msg.sender;
    }

    function createIdentity(bytes identityData)
        public 
        returns(bool)
    {
        Identity identity = new Identity(identityData);
        identities[identity][msg.sender] = 1;
        IdentityCreated(msg.sender, identity);
    }

    function forwardTo(Identity identity, address to, uint256 value, bytes data) 
        public
        onlyIdentityOwner(identity)
    {
        identity.forward(to,value,data);
        ForwardedTo(identity, msg.sender, to, value, data);
    }

    function setIdentityData(Identity identity, bytes data) 
        public
        onlyIdentityOwner(identity)
    {
        identity.setFinancialData(data);
    }

    function isIdentityOwner(address identity, address _owner)
        internal
        view
        returns(bool)
    {
        return identities[identity][owner] == 1; 
    }

}