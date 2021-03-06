
const BigNumber = web3.BigNumber
const signer = require("eth-signer")
const should = require("chai")
    .use(require("chai-as-promised"))
    .should()
const expect = require("chai").expect

// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")
const Identity = artifacts.require("./identity/Identity.sol")
// --- Test variables
const someIpfsHash = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
const anotherIpfsHash = "QmWHyrPWQnsz1wxHR219ooJDYTvxJPyZuDUPSDpdsAovN5"
const someIdentityHash = "4645956063920ed5773c8e2a8f040d9e9f966bf43a4b1e070b577d035d5a0b54"
const anotherIdentityHash = "990500271c247830a00ce921c32a71f066d663ef6b68c2dc4a7e6540c464b979"
const PERSONAL_IDENTITY = new BigNumber(0)
const MULTISIG_IDENTITY = new BigNumber(1)
// Contracts
let protocol = null
let personalIdentity = null
let companyIdentity = null

contract("Identity", async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[2]
        protocol = await IdentityProtocol.new({ from: Swapy })

    })

    context("Manage Identity", () => {
        
        it("should create a personal identity", async () => {
            const {logs} = await protocol.createPersonalIdentity(
                someIdentityHash,
                someIpfsHash,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === "LogIdentityCreated")
            const args = event.args
            personalIdentity = await Identity.at(args.identity)
        })

        it("should deny if try to set the financial data of another user identity", async () => {
            await personalIdentity.setFinancialData(
                anotherIpfsHash,
                { from: Swapy }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should set a new identity's financial data", async () => {
            const {logs} = await personalIdentity.setFinancialData(
                anotherIpfsHash,
                { from: identityOwner }
            )
            const storedIpfsData = await personalIdentity.financialData.call()
            assert.equal(web3.toAscii(storedIpfsData), anotherIpfsHash, "The financial data must be changed according to the value sent")
        })
      

    })

    context("Forward transactions", () => {
        
        it("should deny if try to forward transaction by using another user identity", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData("createPersonalIdentity", ["bytes","bytes"], [anotherIdentityHash, someIpfsHash]);
            await personalIdentity.forward(
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: Swapy }
            ).should.be.rejectedWith("VM Exception")
        })

        it("should forward transactions by proxy", async () => {
            const transactionData = signer.txutils._encodeFunctionTxData("createPersonalIdentity", ["bytes","bytes"], [anotherIdentityHash, someIpfsHash]);
            const {logs} = await personalIdentity.forward(
                protocol.address,
                0,
                `0x${transactionData}`,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === "LogForwarded")
            const args = event.args
            expect(args).to.include.all.keys([
                "destination",
                "value",
                "data",
                "timestamp"
            ])
            assert.equal(args.destination, protocol.address, "The transaction must be destinated to the address sent" )
        })

    })

})
