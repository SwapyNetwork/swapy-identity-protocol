
const BigNumber = web3.BigNumber
const signer = require("eth-signer")
const should = require("chai")
    .use(require("chai-as-promised"))
    .should()
const expect = require("chai").expect

// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")

// --- Test variables
const someIpfsHash = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
const anotherIpfsHash = "QmWHyrPWQnsz1wxHR219ooJDYTvxJPyZuDUPSDpdsAovN5"
const someIdentityHash = "4645956063920ed5773c8e2a8f040d9e9f966bf43a4b1e070b577d035d5a0b54"
const anotherIdentityHash = "990500271c247830a00ce921c32a71f066d663ef6b68c2dc4a7e6540c464b979"
const PERSONAL_IDENTITY = new BigNumber(0)
const MULTISIG_IDENTITY = new BigNumber(1)
// Contracts
let protocol = null

let Swapy = null;
let identityOwner = null;

contract("IdentityProtocol", async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[1]
        protocol = await IdentityProtocol.new({ from: Swapy })

    })

    context('Create Identities', () => {
        
        it("should create a personal identity", async () => {
            const {logs} = await protocol.createPersonalIdentity(
                someIdentityHash,
                someIpfsHash,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === "IdentityCreated")
            const args = event.args
            expect(args).to.include.all.keys([
                "creator",
                "identity",
                "identityType",
                "timestamp"
            ])
            assert.equal(args.creator, identityOwner, "The user must be identity's owner")
            assert.equal(args.identityType.toNumber(), PERSONAL_IDENTITY.toNumber(), "The identity must be personal" )
        })

        it("should deny if try to create a personal identity with duplicated id", async () => {
            await protocol.createPersonalIdentity(
                someIdentityHash,
                someIpfsHash,
                { from: identityOwner }
            ).should.be.rejectedWith("VM Exception")
        })


        it("should create a multi sig identity", async () => {
            const {logs} = await protocol.createMultiSigIdentity(
                anotherIdentityHash,
                anotherIpfsHash,
                [identityOwner],
                1,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === "IdentityCreated")
            const args = event.args
            assert.equal(args.identityType.toNumber(), MULTISIG_IDENTITY.toNumber(), "The identity must be an company" )
        })

        it("should deny if try to create a multi sig identity with duplicated id", async () => {
            await protocol.createMultiSigIdentity(
                anotherIdentityHash,
                anotherIpfsHash,
                [identityOwner],
                1,
                { from: identityOwner }
            ).should.be.rejectedWith("VM Exception")
        })

    })

})
