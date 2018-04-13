pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "../contracts/identity/Identity.sol";
import "./helpers/ThrowProxy.sol";

contract TestIdentity {
    
    Identity identity = new Identity(address(this),"QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa");
    ThrowProxy throwProxy = new ThrowProxy(address(identity)); 
    Identity throwableIdentity = Identity(address(throwProxy));
    bytes identityData;
    // Testing the setFinancialData() function
    function testUserCanChangeProfile() public {
        bool result = identity.setFinancialData("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879");
        Assert.equal(result, true, "The profile must be changed");
    }
      
}