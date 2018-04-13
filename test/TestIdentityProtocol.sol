pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "./helpers/ThrowProxy.sol";

contract TestIdentityProtocol {
    
    IdentityProtocol protocol = IdentityProtocol(DeployedAddresses.IdentityProtocol());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    IdentityProtocol throwableProtocol = IdentityProtocol(address(throwProxy));
    address personalIdentity;
    address multiSigIdentity;
    address[] owners;
   
    // Testing the createPersonalIdentity() function
    function testUserCanCreatePersonalIdentity() public {
        personalIdentity = protocol.createPersonalIdentity(
            "PersonalTest",
            "QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa"
        );  
    }

    // Testing the createMultiSigIdentity() function
    function testUserCanCreateMultiSigIdentity() public {
        owners.push(address(this));
        multiSigIdentity = protocol.createMultiSigIdentity(
            "MultiSigTest",
            "QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa",
            owners,
            uint256(1)
        );  
    }

    // Testing the createMultiSigIdentity() function
    function testUserCannotCreateIdentityWithDuplicatedId() public {
        throwableProtocol.createMultiSigIdentity(
            "MultiSigTest",
            "QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa",
            owners,
            uint256(1)
        );
        throwProxy.shouldThrow();  
    }

    // Testing the createPersonalIdentity() function
    function testUserCanGetIdentity() public {
        address storedIdentity;
        storedIdentity = protocol.getIdentity("PersonalTest");
        Assert.equal(storedIdentity, personalIdentity, "The retrieved identity must be the personal identity");
    }

    // Testing the createPersonalIdentity() function
    function testUserCannotGetInvalidIdentity() public {
        throwableProtocol.getIdentity("PersonalTestInvalid");
        throwProxy.shouldThrow(); 
    }
    
}