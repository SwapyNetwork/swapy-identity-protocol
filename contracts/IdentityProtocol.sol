pragma solidity ^0.4.18;

import './identity/Identity.sol';
import './identity/MultiSigIdentity.sol';


contract IdentityProtocol {

    mapping(bytes => address) identities;
    mapping(address => mapping(bytes => bool)) owners;
    mapping(bytes => bool) indexes;

    event IdentityCreated(address creator, address identity, Type identityType, uint256 timestamp);

    enum Type {
        PERSONAL,
        MULTISIG
    }

    modifier uniqueId(bytes identityId){
        require(!indexes[identityId]);
        _;
    }

    function createPersonalIdentity(bytes identityId, bytes _identityData)
        uniqueId(identityId)
        external 
        returns(bool)
    {
        Identity identity = new Identity(msg.sender, _identityData);
        addIdentity(identityId, identity, Type.PERSONAL);
        return true;
    }

    function createMultiSigIdentity(bytes identityId, bytes _identityData, address[] _owners, uint256 _required)
        uniqueId(identityId)
        external
        returns(bool)
    {
        MultiSigIdentity identity = new MultiSigIdentity(_identityData, _owners, _required);
        addIdentity(identityId, identity, Type.MULTISIG);
        return true;
    }

    function addIdentity(bytes identityId, address identity, Type identityType)
        private
    {
        identities[identityId] = identity;
        indexes[identityId] = true;
        owners[msg.sender][identityId] = true;
        IdentityCreated(msg.sender, identity, identityType, now);
    }

    function getIdentity(bytes identityId) 
        public
        view
        returns(address identity)
    {
        require(indexes[identityId]);
        return identities[identityId];
    }

}