
const BigNumber = web3.BigNumber
const signer = require('eth-signer')
const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect


// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")
const Identity = artifacts.require("./identity/Identity.sol")
// --- Test variables
const someIpfsHash = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
const anotherIpfsHash = "QmWHyrPWQnsz1wxHR219ooJDYTvxJPyZuDUPSDpdsAovN5"
// Contracts
let protocol = null
let identity = null

contract('IdentityProtocol', async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[2]
        protocol = await IdentityProtocol.new({ from: Swapy })

    })

    context('Manage identities', () => {
        it("should create an identity", async () => {
            const {logs} = await protocol.createIdentity(
                someIpfsHash,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            expect(args).to.include.all.keys([
                'creator',
                'identity',
            ])
            assert.equal(args.creator, identityOwner, "The user must be identity's owner")
            identity = await Identity.at(args.identity)
            const storedIpfsData = await identity.financialData.call()
            assert.equal(web3.toAscii(storedIpfsData), someIpfsHash, "The financial data must be the same was sent" )
        })

        it("should deny if try to set the financial data of another user identity", async () => {
            await protocol.setIdentityData(
                identity.address,
                anotherIpfsHash,
                { from: Swapy }
            ).should.be.rejectedWith('VM Exception')
        })

        it("should set a new identity's financial data", async () => {
            const {logs} = await protocol.setIdentityData(
                identity.address,
                anotherIpfsHash,
                { from: identityOwner }
            )
            const storedIpfsData = await identity.financialData.call()
            assert.equal(web3.toAscii(storedIpfsData), anotherIpfsHash, "The financial data must be changed according to the value sent")
        })

    })

    context("Forward transactions", () => {
        
        it("should deny if try to forward transaction by using another user identity", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData('createIdentity', ['bytes'], [someIpfsHash]);
            await protocol.forwardTo(
                identity.address,
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: Swapy }
            ).should.be.rejectedWith('VM Exception')
        })

        it("should forward transactions by proxy", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData('createIdentity', ['bytes'], [someIpfsHash]);
            const {logs} = await protocol.forwardTo(
                identity.address,
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            assert.equal(args.creator, identity.address, "The identity must be the owner of new identity" )
        })
    })

})
