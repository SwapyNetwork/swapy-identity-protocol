
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

})
