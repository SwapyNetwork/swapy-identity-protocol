
const BigNumber = web3.BigNumber
const signer = require("eth-signer")
const should = require("chai")
    .use(require("chai-as-promised"))
    .should()
const expect = require("chai").expect

// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")
const MultiSigIdentity = artifacts.require("./identity/MultiSigIdentity.sol")
// --- Test variables
const someIpfsHash = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
const anotherIpfsHash = "QmWHyrPWQnsz1wxHR219ooJDYTvxJPyZuDUPSDpdsAovN5"
const PERSONAL_IDENTITY = new BigNumber(0)
const MULTISIG_IDENTITY = new BigNumber(1)
// Contracts
let protocol = null
let multiSigIdentity = null

let Swapy = null;
let identityOwner_1 = null;
let identityOwner_2 = null;
let identityOwner_3 = null;
let identityOwner_4 = null;

contract("MultiSigIdentity", async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner_1 = accounts[1]
        identityOwner_2 = accounts[2]
        identityOwner_3 = accounts[3]
        identityOwner_4 = accounts[4]
        protocol = await IdentityProtocol.new({ from: Swapy })
        const {logs} = await protocol.createMultiSigIdentity(
            someIpfsHash,
            [identityOwner_1, identityOwner_2, identityOwner_3],
            2,
            { from: identityOwner_1 }
        )
        const event = logs.find(e => e.event === "IdentityCreated")
        const args = event.args
        multiSigIdentity = await MultiSigIdentity.at(args.identity)

    })

    context("Access control", () => {

        it("should deny if try to add an owner without a multi sig transaction", async () => {
            await multiSigIdentity.addOwner(
                identityOwner_4,
                { from: identityOwner_1 }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should deny if try to change the required signatures without a multi sig transaction", async () => {
            await multiSigIdentity.changeRequired(
                1,
                { from: identityOwner_1 }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should deny if try to remove an owner without a multi sig transaction", async () => {
            await multiSigIdentity.removeOwner(
                identityOwner_2,
                { from: identityOwner_1 }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should deny if try to change the financial data without a multi sig transaction", async () => {
            await multiSigIdentity.setFinancialData(
                anotherIpfsHash,
                { from: identityOwner_1 }
            ).should.be.rejectedWith("VM Exception")
        })

    })

    context("Multi sig transactions", () => {

        it("should deny transactions by non owners", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData("changeRequired", ["uint"], [3]);
            const {logs} = await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                `0x${transactionData}`,
                { from: Swapy }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should deny transactions with value destinated to the MultiSigIdentity", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData("changeRequired", ["uint"], [3]);
            const {logs} = await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                100,
                `0x${transactionData}`,
                { from: identityOwner_1 }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should create a multi sig transaction", async () => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(3);
            const {logs} = await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            const event = logs.find(e => e.event === "TransactionCreated")
            const args = event.args
            expect(args).to.include.all.keys([
                "creator",
                "destination",
                "value",
                "data",
                "timestamp"
            ])
            assert.equal(args.destination, multiSigIdentity.address, "The transaction must be destinated to the address sent" )
        })

    })

    context("Sign transactions", () => {

        it("should deny signatures by non owners", async () => {
            await multiSigIdentity.signTransaction(0, { from: Swapy })
                .should.be.rejectedWith("VM Exception")
        })

        it("should deny if try to sign an invalid transaction", async () => {
            await multiSigIdentity.signTransaction(3, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should sign transactions", async () => {
            const {logs} = await multiSigIdentity.signTransaction(0, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "TransactionSigned")
            const args = event.args
            expect(args).to.include.all.keys([
                "signer",
                "transactionId",
                "timestamp"
            ])
            assert.equal(args.signer, identityOwner_1, "The transaction must be signed by the signature sender" )
        }) 

        it("should deny duplicated signatures", async () => {
            await multiSigIdentity.signTransaction(0, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })
    })

    context("Execute a multi sig transaction", () => {

        it("should deny if try to execute a transaction without enough signatures", async () => {
            await multiSigIdentity.executeTransaction(0, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should execute a transaction", async () => {
            await multiSigIdentity.signTransaction(0, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(0, { from: identityOwner_3 })
            const {logs} = await multiSigIdentity.executeTransaction(0, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "TransactionExecuted")
            const args = event.args
            expect(args).to.include.all.keys([
                "executor",
                "transactionId",
                "timestamp"
            ])
            assert.equal(args.executor, identityOwner_1, "The transaction must be executed by the execution sender" )
        })

        it("should deny duplicated executions", async () => {
            await multiSigIdentity.executeTransaction(0, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })
    })

    context("Change profile data", () => {

        it("should change the profile data hash", async () => {
            const transactionData = multiSigIdentity.contract.setFinancialData.getData(anotherIpfsHash);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(1, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(1, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(1, { from: identityOwner_3 })
            const {logs} = await multiSigIdentity.executeTransaction(1, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "ProfileChanged")
            const args = event.args
            expect(args).to.include.all.keys([
                "financialData",
                "timestamp"
            ])
        })

    })

    context("Change requirement", () => {

        it("should deny if try to set a negative value", async () => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(-1);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(2, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(2, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(2, { from: identityOwner_3 })
            await multiSigIdentity.executeTransaction(2, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should deny if try to set a value greater than active owners", async () => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(10);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(3, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(3, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(3, { from: identityOwner_3 })
            await multiSigIdentity.executeTransaction(3, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should change the required number of owners", async () => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(2);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(4, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(4, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(4, { from: identityOwner_3 })
            const {logs} = await multiSigIdentity.executeTransaction(4, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "RequiredChanged")
            const args = event.args
            expect(args).to.include.all.keys([
                "required",
                "timestamp"
            ])
        })

    })

    context("Add owner", () => {

        it("should deny if try to add an owner already added", async () => {
            const transactionData = multiSigIdentity.contract.addOwner.getData(identityOwner_2);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(5, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(5, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(5, { from: identityOwner_3 })
            await multiSigIdentity.executeTransaction(5, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should add an owner", async () => {
            const transactionData = multiSigIdentity.contract.addOwner.getData(identityOwner_4);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(6, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(6, { from: identityOwner_2 })
            await multiSigIdentity.signTransaction(6, { from: identityOwner_3 })
            const {logs} = await multiSigIdentity.executeTransaction(6, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "OwnerAdded")
            const args = event.args
            expect(args).to.include.all.keys([
                "owner",
                "timestamp"
            ])
        })

    })

    context("Remove owner", () => {

        it("should deny if try to remove an owner not added", async () => {
            const transactionData = multiSigIdentity.contract.removeOwner.getData(Swapy);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(7, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(7, { from: identityOwner_3 })
            await multiSigIdentity.signTransaction(7, { from: identityOwner_4 })
            await multiSigIdentity.executeTransaction(7, { from: identityOwner_1 })
                .should.be.rejectedWith("VM Exception")
        })

        it("should remove an owner", async () => {
            const transactionData = multiSigIdentity.contract.removeOwner.getData(identityOwner_2);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(8, { from: identityOwner_1 })
            await multiSigIdentity.signTransaction(8, { from: identityOwner_3 })
            await multiSigIdentity.signTransaction(8, { from: identityOwner_4 })
            const {logs} = await multiSigIdentity.executeTransaction(8, { from: identityOwner_1 })
            const event = logs.find(e => e.event === "OwnerRemoved")
            const args = event.args
            expect(args).to.include.all.keys([
                "owner",
                "timestamp"
            ])
        })

        it("should deny transactions created by the old owner", async() => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(1);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_2 }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should deny the old owner's signature", async() => {
            const transactionData = multiSigIdentity.contract.changeRequired.getData(1);
            await multiSigIdentity.addTransaction(
                multiSigIdentity.address,
                0,
                transactionData,
                { from: identityOwner_1 }
            )
            await multiSigIdentity.signTransaction(9, { from: identityOwner_2 })
                .should.be.rejectedWith("VM Exception")
        })

    })


})
