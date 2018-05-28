pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "../contracts/identity/Identity.sol";
import "./helpers/ThrowProxy.sol";

contract TestIdentity {

    Identity identity = new Identity(address(this),"QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa");
    ThrowProxy throwProxy = new ThrowProxy(address(identity)); 
    Identity throwableIdentity = Identity(address(throwProxy));
    SomeContract someInstance = new SomeContract();

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
        address(throwableIdentity).call(abi.encodeWithSignature("setFinancialData(bytes)","QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa"));
        throwProxy.shouldThrow(); 
    }

    // Testing forward() function
    function testIdentityCanForwardTransactionByOwner() public {
        bool result = identity.forward(address(someInstance), 0, abi.encodeWithSignature("someFunction()"));
        Assert.equal(result, true, "The transaction must be executed");
    }

    // Testing forward() function
    function testOnlyOwnerCanUseIdentityAsProxy() public {
        address(throwableIdentity).call(abi.encodeWithSignature("forward(address,uint256,bytes)",address(someInstance), 0, abi.encodeWithSignature("someFunction()")));
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
