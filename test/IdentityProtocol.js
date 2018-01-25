
const BigNumber = web3.BigNumber
const signer = require('eth-signer')
const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect

const ether = require('./helpers/ether')

// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")
const Identity = artifacts.require("./identity/Identity.sol")
// --- Test variables
const someIpfsHash = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
const anotherIpfsHash = "QmWHyrPWQnsz1wxHR219ooJDYTvxJPyZuDUPSDpdsAovN5"
const PERSONAL_IDENTITY = new BigNumber(0)
const COMPANY_IDENTITY = new BigNumber(1)
// Contracts
let protocol = null
let personalIdentity = null
let companyIdentity = null

contract('IdentityProtocol', async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[2]
        protocol = await IdentityProtocol.new({ from: Swapy })

    })

    context('Manage identities', () => {
        
        it("should create an personal identity", async () => {
            const {logs} = await protocol.createIdentity(
                someIpfsHash,
                true,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            expect(args).to.include.all.keys([
                'creator',
                'identity',
                'identityType'
            ])
            assert.equal(args.creator, identityOwner, "The user must be identity's owner")
            assert.equal(args.identityType.toNumber(), PERSONAL_IDENTITY.toNumber(), "The identity must be personal" )
            personalIdentity = await Identity.at(args.identity)
            const storedIpfsData = await personalIdentity.financialData.call()
            assert.equal(web3.toAscii(storedIpfsData), someIpfsHash, "The financial data must be the same was sent" )
        })

        it("should create an company identity", async () => {
            const {logs} = await protocol.createIdentity(
                someIpfsHash,
                false,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            assert.equal(args.identityType.toNumber(), COMPANY_IDENTITY.toNumber(), "The identity must be an company" )
            companyIdentity = await Identity.at(args.identity)
        })

        it("should deny if try to set the financial data of another user identity", async () => {
            await protocol.setIdentityData(
                personalIdentity.address,
                anotherIpfsHash,
                { from: Swapy }
            ).should.be.rejectedWith('VM Exception')
        })

        it("should set a new identity's financial data", async () => {
            const {logs} = await protocol.setIdentityData(
                personalIdentity.address,
                anotherIpfsHash,
                { from: identityOwner }
            )
            const storedIpfsData = await personalIdentity.financialData.call()
            assert.equal(web3.toAscii(storedIpfsData), anotherIpfsHash, "The financial data must be changed according to the value sent")
        })
      

    })

    context("Forward transactions", () => {
        
        it("should deny if try to forward transaction by using another user identity", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData('createIdentity', ['bytes', 'bool'], [someIpfsHash, true]);
            await protocol.forwardTo(
                personalIdentity.address,
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: Swapy }
            ).should.be.rejectedWith('VM Exception')
        })

        it("should forward transactions by proxy", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData('createIdentity', ['bytes', 'bool'], [someIpfsHash, true]);
            const {logs} = await protocol.forwardTo(
                personalIdentity.address,
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            assert.equal(args.creator, personalIdentity.address, "The identity must be the owner of new identity" )
        })

    })

})
