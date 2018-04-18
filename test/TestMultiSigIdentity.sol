pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "../contracts/identity/MultiSigIdentity.sol";
import "./helpers/ThrowProxy.sol";

contract TestMultiSigIdentity {

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;
    AnotherOwner anotherOwner = new AnotherOwner();
    address[] owners;
    
    MultiSigIdentity multiSigIdentity; 
    ThrowProxy throwProxy; 
    MultiSigIdentity throwableMultiSigIdentity;
    
    bytes msgData;
    
    function TestMultiSigIdentity() public {
        owners.push(address(this));
        owners.push(address(anotherOwner));
        multiSigIdentity = new MultiSigIdentity("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2Pwa", owners, uint256(1));
        throwProxy = new ThrowProxy(address(multiSigIdentity)); 
        throwableMultiSigIdentity = MultiSigIdentity(address(throwProxy));
    }

    function () public {
        msgData = msg.data;
    }
    
    // Testing denied calls without a multi sig transaction
    // add owner
    function testShouldExistMultiSigTransactionToAddOwner() public {
        throwableMultiSigIdentity.addOwner(address(anotherOwner));
        throwProxy.shouldThrow();
    }
    // change required number of signatures
    function testShouldExistMultiSigTransactionToChangeRequirement() public {
        throwableMultiSigIdentity.changeRequired(uint256(1));
        throwProxy.shouldThrow();
    }
    // remove owner
    function testShouldExistMultiSigTransactionToRemoveOwner() public {
        throwableMultiSigIdentity.removeOwner(address(this));
        throwProxy.shouldThrow();
    }

    function testShouldExistMultiSigTransactionToChangeProfile() public {
        throwableMultiSigIdentity.setFinancialData("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879");
        throwProxy.shouldThrow();    
    }

    // Testing addTransaction() function
    function testShouldDenyTransactionsByNonOwners() public {
        SomeContract someInstance = SomeContract(address(this));
        someInstance.someFunction();
        throwableMultiSigIdentity.addTransaction(address(someInstance), 0, msgData);
        throwProxy.shouldThrow();
    } 

    // @todo create a throw proxy with delegatecall instead of call()
    // function testShouldDenyTransactionsWithValueToItself() public {
    //     SomeContract someInstance = SomeContract(address(this));
    //     someInstance.someFunction();
    //     throwableMultiSigIdentity.addTransaction(address(someInstance), 0, msgData);
    //     throwProxy.shouldThrow();
    // }
    

    function testOwnerCanCreateTransaction() public {
        SomeContract someInstance = SomeContract(address(this));
        someInstance.someFunction();
        uint256 transactionId = multiSigIdentity.addTransaction(address(someInstance), 0, msgData);
        Assert.equal(transactionId, 0, "The transaction should have ID 0");
    }
    
    // Testing signTransaction() function 
    function testShouldDenySignaturesByNonOwners() public {
        throwableMultiSigIdentity.signTransaction(uint256(0));
        throwProxy.shouldThrow();
    }
    // @todo create a throw proxy with delegatecall instead of call()
    // function testShouldDenySignaturesToInvalidTransactions() public {
    //     throwableMultiSigIdentity.signTransaction(uint256(1));
    //     throwProxy.shouldThrow();
    // }

    function testOwnerCanSignTransaction() public {
        bool result = multiSigIdentity.signTransaction(uint256(0));
        Assert.equal(result, true, "The transaction 0 must be signed");
    }
    
    // @todo create a throw proxy with delegatecall instead of call()
    // function testShouldDenyDuplicatedSignatures() public {
    //     throwableMultiSigIdentity.signTransaction(uint256(0));
    //     throwProxy.shouldThrow();
    // }

    // Testing executeTransaction() function
    // @todo create a throw proxy with delegatecall instead of call()
    // function testShouldDenyTryingToExecuteTransactionWithoutEnoughSignatures() public {
    //     SomeContract someInstance = SomeContract(address(this));
    //     someInstance.someFunction();
    //     uint256 transactionId = multiSigIdentity.addTransaction(address(someInstance), 0, msgData);
    //     throwableMultiSigIdentity.executeTransaction(transactionId);
    //     throwProxy.shouldThrow();
    // }
    
    function testUserCanExecuteTransaction() public {
        bool result = multiSigIdentity.executeTransaction(uint256(0));
        Assert.equal(result, true, "The transaction 0 must be executed");
    }


    function testShouldDenyDuplicatedExecutions() public {
        throwableMultiSigIdentity.executeTransaction(uint256(0));
        throwProxy.shouldThrow();
    }

    function testOwnersCanChangeIdentityProfile() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.setFinancialData("QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879");
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The profile data must be changed");
    }

    function testOwnersCanRemoveAnOwner() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.removeOwner(address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The owner must be removed");
        uint256 activeOwners = multiSigIdentity.activeOwners();
        Assert.equal(activeOwners, uint256(1), "The number of owners must be equal 1");
    }

    function testOwnersCannotRemoveAnInvalidOwner() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.removeOwner(address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        throwableMultiSigIdentity.executeTransaction(transactionId); 
        throwProxy.shouldThrow();
    }


    function testOwnersCanAddAnOwner() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.addOwner(address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        bool executed = multiSigIdentity.executeTransaction(transactionId); 
        Assert.equal(executed, true, "The owner must be added");
        uint256 activeOwners = multiSigIdentity.activeOwners();
        Assert.equal(activeOwners, uint256(2), "The number of owners must be equal 1");
    }

    function testOwnersCannotAddAnCurrentOwner() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.addOwner(address(anotherOwner));
        uint256 transactionId = multiSigIdentity.addTransaction(address(multiSigIdentity), 0, msgData);
        multiSigIdentity.signTransaction(transactionId);
        throwableMultiSigIdentity.executeTransaction(transactionId); 
        throwProxy.shouldThrow();
    }

    function testOwnersCanChangeSignaturesRequirement() public {
        MultiSigIdentity identityInterface = MultiSigIdentity(address(this));
        identityInterface.changeRequired(uint256(2));
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