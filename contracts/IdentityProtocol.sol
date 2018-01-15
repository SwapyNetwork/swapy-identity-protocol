pragma solidity ^0.4.18;

import './identity/Identity.sol';

contract IdentityProtocol {

    address public owner;

    mapping(address => mapping(address => uint)) identities;

    event IdentityCreated(address _creator, address _identity);
    
    modifier onlyIdentityOwner(address identity) {
        require(identities[identity][msg.sender] > 0);
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
        identities[identity][msg.sender] = now;
        IdentityCreated(msg.sender, identity);
    }


    function forwardTo(Identity identity, address to, uint256 value, bytes data) 
        public
        onlyIdentityOwner(identity)
    {
        identity.forward(to,value,data);
    }


}