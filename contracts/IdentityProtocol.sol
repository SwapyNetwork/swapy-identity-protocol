pragma solidity ^0.4.18;

import './identity/Identity.sol';
import './identity/MultiSigIdentity.sol';

contract IdentityProtocol {

    mapping(address => mapping(address => uint)) identities;

    event IdentityCreated(address creator, address identity, Type identityType);

    enum Type {
        PERSONAL,
        MULTISIG
    }

    function createPersonalIdentity(bytes _identityData)
        public 
        returns(bool)
    {
        Identity identity = new Identity(msg.sender, _identityData);
        identities[identity][msg.sender] = 1;
        IdentityCreated(msg.sender, identity, Type.PERSONAL);
        return true;
    }

    function createMultiSigIdentity(bytes _identityData, address[] _owners, int _required)
        public
        returns(bool)
    {
        MultiSigIdentity identity = new MultiSigIdentity(_identityData, _owners, _required);
        identities[identity][msg.sender] = 1;
        IdentityCreated(msg.sender, identity, Type.MULTISIG);
        return true;
    }

}