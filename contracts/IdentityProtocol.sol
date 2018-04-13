pragma solidity ^0.4.21;

import "./identity/Identity.sol";
import "./identity/MultiSigIdentity.sol";

/**
 * @title Swapy Identity Protocol 
 * @dev Allows the creation of personal and multi signature identities
 */
contract IdentityProtocol {

    /**
     * Storage
     */
    mapping(bytes => address) identities;
    mapping(address => mapping(bytes => bool)) owners;
    mapping(bytes => bool) indexes;
    enum Type {
        PERSONAL,
        MULTISIG
    }
    
    /**
     * Events   
     */
    event LogIdentityCreated(address creator, address identity, Type identityType, uint256 timestamp);

    /**
     * Modifiers   
     */
    modifier uniqueId(bytes identityId){
        require(!indexes[identityId]);
        _;
    }

    /**
     * @dev Create a personal identity with its ID and profile hash
     * @param identityId Identity's unique ID
     * @param _identityData Profile data hash
     * @return Identity address
     */    
    function createPersonalIdentity(bytes identityId, bytes _identityData)
        uniqueId(identityId)
        external 
        returns(address)
    {
        Identity identity = new Identity(msg.sender, _identityData);
        addIdentity(identityId, identity, Type.PERSONAL);
        return identity;
    }

    /**
     * @dev Create a multi signature identity with its ID, profile hash, owners and number of signatures required
     * @param identityId Identity's unique ID
     * @param _identityData Profile data hash
     * @param _owners Owner addresses
     * @param _required Number of signatures required
     * @return Address
     */    
    function createMultiSigIdentity(bytes identityId, bytes _identityData, address[] _owners, uint256 _required)
        uniqueId(identityId)
        external
        returns(address)
    {
        MultiSigIdentity identity = new MultiSigIdentity(_identityData, _owners, _required);
        addIdentity(identityId, identity, Type.MULTISIG);
        return identity;
    }

    /**
     * @dev Set a new identity on the control mappings and fire an event
     * @param identityId Identity's unique ID
     * @param identity Address of identity created
     * @param identityType Type of identity. Personal or multi signature
     */  
    function addIdentity(bytes identityId, address identity, Type identityType)
        private
    {
        identities[identityId] = identity;
        indexes[identityId] = true;
        owners[msg.sender][identityId] = true;
        emit LogIdentityCreated(msg.sender, identity, identityType, now);
    }

    /**
     * @dev Retrieve an identity by its ID
     * @param identityId Identity's unique ID
     * @return Identity's address
     */
    function getIdentity(bytes identityId) 
        public
        view
        returns(address identity)
    {
        require(indexes[identityId]);
        return identities[identityId];
    }

}