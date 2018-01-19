const ipfs = require('./helpers/ipfsTree')

const BigNumber = web3.BigNumber
const signer = require('eth-signer')
const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect

// --- Handled contracts
const IdentityProtocol = artifacts.require("./IdentityProtocol.sol")
const Identity = artifacts.require("./identity/Identity.sol")
// Contracts
let protocol = null
let identity = null

let firstHash = null
contract('IdentityProtocol + IPFS integration', async accounts => {

    before( async () => {

        Swapy = accounts[0]
        identityOwner = accounts[2]
        protocol = await IdentityProtocol.new({ from: Swapy })
        // Config ipfs provider
        ipfs.setProvider('ipfs.infura.io', '5001', 'https') 
        // create the root object
        let tree = ipfs.initTree(false)
        // insert some nodes for test
        ipfs.insertNode(tree, 'root', 'root_profile', null)
        ipfs.insertNode(tree, 'root_profile', 'profile_name', 'Any User')
        ipfs.insertNode(tree, 'root_profile', 'profile_email', 'any@email.com')
        ipfs.insertNode(tree, 'root_profile', 'profile_phone', '1122224444')
        ipfs.insertNode(tree, 'root_profile', 'profile_id', '123123123')
        ipfs.insertNode(tree, 'root', 'root_financial', null)
        ipfs.insertNode(tree, 'root_financial', 'financial_loan_requests', '3')
        ipfs.insertNode(tree, 'root_financial', 'financial_investments', null)
        ipfs.insertNode(tree, 'financial_investments', 'investments_2014', '2')
        ipfs.insertNode(tree, 'financial_investments', 'investments_2015', '8')
        // persist the tree on IPFS
        firstHash = await ipfs.saveIpfsTree(tree)
        console.log('Logging the tree Before tests...')
        console.log(tree)
    })

    context('Manage identities + IPFS data', () => {

        it("Create an identity with the persisted tree's hash", async () => {
            const {logs} = await protocol.createIdentity(
                firstHash,
                { from: identityOwner }
            )
            const event = logs.find(e => e.event === 'IdentityCreated')
            const args = event.args
            identity = await Identity.at(args.identity)
        })

        it("should search and return a node with its childrens", async () => {
            // get ipfs hash
            let storedIpfsData = await identity.financialData.call()
            storedIpfsData = web3.toAscii(storedIpfsData)
            // get tree from ipfs by using the hash
            let tree = await ipfs.getIpfsTree(storedIpfsData)
            // searching the node 'root_profile'
            const node = ipfs.dfs(tree, 'profile_phone')
            console.log("Retrieving 'profile_phone' ...")
            console.log(node)
        })

        it("should update a node", async () => {
            // get ipfs hash
            let storedIpfsData = await identity.financialData.call()
            storedIpfsData = web3.toAscii(storedIpfsData)
            // get tree from ipfs by using the hash
            let tree = await ipfs.getIpfsTree(storedIpfsData)
            // update the node 'profile_name' in memory
            ipfs.updateNode(tree, 'profile_name', 'Some User')
            // persist the new tree on IPFS
            let ipfsHash = await ipfs.saveIpfsTree(tree)
            // update the identity data into the blockchain 
            await protocol.setIdentityData(
                identity.address,
                ipfsHash,
                { from: identityOwner }
            )
            console.log("Changing 'profile_name' from Any User to Some User...")
        })

        it("should remove a node", async () => {
            // get ipfs hash
            let storedIpfsData = await identity.financialData.call()
            storedIpfsData = web3.toAscii(storedIpfsData)
            // get tree from ipfs by using the hash
            let tree = await ipfs.getIpfsTree(storedIpfsData)
            // update the node 'root_financial' in memory
            ipfs.removeNode(tree, 'root_financial')
            // persist the new tree on IPFS
            let ipfsHash = await ipfs.saveIpfsTree(tree)
            // update the identity data into the blockchain 
            await protocol.setIdentityData(
                identity.address,
                ipfsHash,
                { from: identityOwner }
            )
            console.log("Removing 'root_financial'...")
        })


        
    })

    after(async () => {
        // get ipfs hash
        let storedIpfsData = await identity.financialData.call()
        storedIpfsData = web3.toAscii(storedIpfsData)
        // get tree from ipfs by using the hash
        let tree = await ipfs.getIpfsTree(storedIpfsData)
        console.log('Logging the tree after tests...')
        console.log(tree)
    })

})
