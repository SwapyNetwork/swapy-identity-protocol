
const BigNumber = web3.BigNumber
const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect


// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")

// --- Test variables
// Contracts
let protocol = null

contract('IdentityProtocol', async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[2]
        protocol = await IdentityProtocol.new({ from: Swapy })

    })

    context('Manage identities', () => {
        it("should create an identity", async () => {
            const {logs} = await protocol.createIdentity(
                "someIPFSdata",
                {from: identityOwner}
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            expect(args).to.include.all.keys([
                'creator',
                'identity',
            ])
            assert.equal(args.creator, identityOwner, "The user must be identity's owner")
        })

    })

})
