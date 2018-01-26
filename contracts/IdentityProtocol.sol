pragma solidity ^0.4.18;

import './identity/Identity.sol';

contract IdentityProtocol {

    mapping(address => mapping(address => uint)) identities;

    event IdentityCreated(address creator, address identity, Identity.Type identityType);
    event ForwardedTo(address identity, address owner, address destination, uint256 value, bytes data);

    modifier onlyIdentityOwner(address _identity) {
        require(isIdentityOwner(_identity, msg.sender));
        _;
    }

    function createIdentity(bytes _identityData, bool isPersonal)
        public 
        returns(bool)
    {
        Identity.Type _type = isPersonal ? Identity.Type.PERSONAL : Identity.Type.COMPANY;  
        Identity identity = new Identity(_identityData, _type);
        identities[identity][msg.sender] = 1;
        IdentityCreated(msg.sender, identity, _type);
        return true;
    }

    function forwardTo(Identity _identity, address _to, uint256 _value, bytes _data)
        payable
        public
        onlyIdentityOwner(_identity)
    {
        if (msg.value != uint256(0)) {
            require(_identity.identityType() == Identity.Type.PERSONAL);
            _identity.forward.value(msg.value)(_to,_value,_data);
        } else {
            _identity.forward(_to,_value,_data);
        }
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