pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdentityProtocol.sol";
import "../contracts/identity/MultiSigIdentity.sol";
import "./helpers/ThrowProxy.sol";

contract TestMultiSigIdentity_transactions {

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;
    AnotherOwner anotherOwner = new AnotherOwner();
    SomeContract someInstance = new SomeContract();
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
    
    // Testing denied calls without a multi sig transaction
    // add owner
    function testShouldExistMultiSigTransactionToAddOwner() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("addOwner(address)",address(anotherOwner)));
        throwProxy.shouldThrow();
    }
    // change required number of signatures
    function testShouldExistMultiSigTransactionToChangeRequirement() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("changeRequired(uint256)",uint256(1)));
        throwProxy.shouldThrow();
    }
    // remove owner
    function testShouldExistMultiSigTransactionToRemoveOwner() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("removeOwner(address)",address(this)));
        throwProxy.shouldThrow();
    }

    function testShouldExistMultiSigTransactionToChangeProfile() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("setFinancialData(bytes)","QmeHy1gq8QHVchad7ndEsdAnaBWGu1CAVmYCb4aTJW2879"));
        throwProxy.shouldThrow();    
    }

    // Testing addTransaction() function
    function testShouldDenyTransactionsByNonOwners() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("addTransaction(address,uint256,bytes)",address(someInstance), 0, abi.encodeWithSignature("someFunction()")));
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
        uint256 transactionId = multiSigIdentity.addTransaction(address(someInstance), 0, abi.encodeWithSignature("someFunction()"));
        Assert.equal(transactionId, 0, "The transaction should have ID 0");
    }
    
    // Testing signTransaction() function 
    function testShouldDenySignaturesByNonOwners() public {
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("signTransaction(uint256)",uint256(0)));
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
        address(throwableMultiSigIdentity).call(abi.encodeWithSignature("executeTransaction(uint256)",uint256(0)));
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

contract AnotherOwner {

    function interactWith(address _multiSigIdentity, bytes transaction) public {
        require(_multiSigIdentity.call(transaction));
    }

}