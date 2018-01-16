pragma solidity ^0.4.18;

import './identity/Identity.sol';

contract IdentityProtocol {

    mapping(address => mapping(address => uint)) identities;

    event IdentityCreated(address creator, address identity);
    event ForwardedTo(address identity, address owner, address destination, uint256 value, bytes data);

    modifier onlyIdentityOwner(address _identity) {
        require(isIdentityOwner(_identity, msg.sender));
        _;
    }

    function createIdentity(bytes _identityData)
        public 
        returns(bool)
    {
        Identity identity = new Identity(_identityData);
        identities[identity][msg.sender] = 1;
        IdentityCreated(msg.sender, identity);
    }

    function forwardTo(Identity _identity, address _to, uint256 _value, bytes _data) 
        public
        onlyIdentityOwner(_identity)
    {
        _identity.forward(_to,_value,_data);
        ForwardedTo(_identity, msg.sender, _to, _value, _data);
    }

    function setIdentityData(Identity _identity, bytes _data) 
        public
        onlyIdentityOwner(_identity)
    {
        _identity.setFinancialData(_data);
    }

    function isIdentityOwner(address _identity, address _owner)
        internal
        view
        returns(bool)
    {
        return identities[_identity][_owner] == 1; 
    }

}