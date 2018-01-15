pragma solidity ^0.4.18;

import './identity/Identity.sol';

contract IdentityProtocol {

    address public owner;

    mapping(address => address) identities;

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
        identities[msg.sender] = identity;
    }


    function forwardTo(address to, uint256 value, bytes data) {
        Identity identity = Identity(identities[msg.sender]);
        identity.forward(to,value,data);
    }
}