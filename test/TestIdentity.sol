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

    bytes msgData;
    
    function () public {
        msgData = msg.data;
    }

    // Testing setFinancialData() function
    function testOwnerCanChangeProfile() public {
        bool result = identity.setFinancialData("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879");
        Assert.equal(result, true, "The profile must be changed");
    }

    // Testing setFinancialData() function
    function testOnlyOwnerCanChangeProfile() public {
        //notAllowed.forwardSetFinancialData(address(throwProxy),"QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa");
        throwableIdentity.setFinancialData("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa");
        throwProxy.shouldThrow(); 
    }

    function testIdentityCanForwardTransactionByOwner() public {
        SomeContract someInstance = SomeContract(address(this));
        someInstance.someFunction();
        bool result = identity.forward(address(someInstance), 0, msgData);
        Assert.equal(result, true, "The transaction must be executed");
    }

    function testOnlyOwnerCanUseIdentityAsProxy() public {
        SomeContract someInstance = SomeContract(address(this));
        someInstance.someFunction();
        throwableIdentity.forward(address(someInstance), 0, msgData);
        throwProxy.shouldThrow();
    }   
}

contract SomeContract {

    function someFunction() 
        public
        pure
        returns(bool)
    {
        return true;
    }
  
}
