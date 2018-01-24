const ipfs = require('./helpers/ipfsLib')
const treeLib = require('./helpers/treeLib')

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
        let treeHash = await ipfs.initTree()
        // insert some nodes for test
        // const insertions = [{
        //     parentLabel: 'root',
        //     label: 'root_profile',
        //     childrens:[{
        //         label: 'profile_name',
        //         data: 'Any User'
        //     },{
        //         label: 'profile_email',
        //         data: 'any@email.com'
        //     },{
        //         label: 'profile_phone',
        //         data: '1122224444'
        //     },{
        //         label: 'profile_id',
        //         data: '123123123'
        //     }]
        // },{
        //     parentLabel: 'root',
        //     label: 'root_financial',
        //     childrens: [{
        //         label: 'financial_loan_requests',
        //         data: '3'
        //     },
        //     {
        //         label: 'financial_investments',
        //         childrens: [{
        //             label: 'investments_2014',
        //             data: '2'
        //         },{
        //             label: 'investments_2015',
        //             data: '8'
        //         }]
        //     }]
        // }]
        const insertions = [{
            parentLabel: 'root',
            label: 'root_profile',
            data: 'oi'
        }]
        treeHash = await ipfs.insertNodes(treeHash, insertions)
        console.log('Logging the tree Before tests...')
        const tree = await ipfs.getTree(treeHash)
        console.log(JSON.stringify(tree))
        firstHash = treeHash
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
            // search the node 'root_profile'
            const node = await ipfs.dfs(storedIpfsData, 'profile_phone')
            console.log("Retrieving 'profile_phone' ...")
            console.log(node)
        })

        it("should update a node", async () => {
            // get ipfs hash
            let storedIpfsData = await identity.financialData.call()
            storedIpfsData = web3.toAscii(storedIpfsData)
            // update the node 'profile_name' and get the new tree's hash
            const ipfsHash = await ipfs.updateNode(storedIpfsData, 'profile_name', 'Some User')
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
            // update the node 'root_financial' and get the new tree's hash
            const ipfsHash = await ipfs.removeNode(storedIpfsData, 'root_financial')
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
        let tree = await ipfs.getData(storedIpfsData)
        console.log('Logging the tree after tests...')
        console.log(tree)
    })

})
