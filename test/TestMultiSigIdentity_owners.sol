pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "../contracts/identity/MultiSigIdentity.sol";
import "./helpers/ThrowProxy.sol";

contract TestMultiSigIdentity_owners {

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;
    AnotherOwner anotherOwner = new AnotherOwner();

    address[] owners;
    
    MultiSigIdentity multiSigIdentity; 
    ThrowProxy throwProxy; 
    MultiSigIdentity throwableMultiSigIdentity;
    
    bytes msgData;
    
    constructor() public {
        owners.push(address(this));
        owners.push(address(anotherOwner));
        multiSigIdentity = new MultiSigIdentity("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa", owners, uint256(1));
        throwProxy = new ThrowProxy(address(multiSigIdentity)); 
        throwableMultiSigIdentity = MultiSigIdentity(address(throwProxy));
    }

    function () public {
        msgData = msg.data;
    }
    
    function testOwnersCanChangeIdentityProfile() public {
        msgData = abi.encodeWithSignature("setFinancialData(bytes)","QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879");
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The profile data must be changed");
    }

    function testOwnersCanRemoveAnOwner() public {
        msgData = abi.encodeWithSignature("removeOwner(address)",address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The owner must be removed");
        uint256 activeOwners = multiSigIdentity.activeOwners();
        Assert.equal(activeOwners, uint256(1), "The number of owners must be equal 1");
    }

    function testOwnersCannotRemoveAnInvalidOwner() public {
        msgData = abi.encodeWithSignature("removeOwner(address)",address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("executeTransaction(uint256)",transactionId)); 
        throwProxy.shouldThrow();
    }


    function testOwnersCanAddAnOwner() public {
        msgData = abi.encodeWithSignature("addOwner(address)", address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The owner must be added");
        uint256 activeOwners = multiSigIdentity.activeOwners();
        Assert.equal(activeOwners, uint256(2), "The number of owners must be equal 1");
    }

    function testOwnersCannotAddAnCurrentOwner() public {
        msgData = abi.encodeWithSignature("addOwner(address)", address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("executeTransaction(uint256)",transactionId)); 
        throwProxy.shouldThrow();
    }

    function testOwnersCanChangeSignaturesRequirement() public {
        msgData = abi.encodeWithSignature("changeRequired(uint256)", uint256(2));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The required number of signatures must be changed");
        uint256 required = multiSigIdentity.required();
        Assert.equal(required, uint256(2), "The number of required signatures must be equal 2");
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

contract AnotherOwner {

    function interactWith(address _multiSigIdentity, bytes transaction) public {
        require(_multiSigIdentity.call(transaction));
    }

}