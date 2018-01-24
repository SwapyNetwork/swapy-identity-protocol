const treeLib = require('./treeLib')
const ipfsAPI = require('ipfs-api')

let ipfs = null;

const setProvider = (host,port,protocol) => {
    ipfs = ipfsAPI({host, port, protocol})
}

const initTree = async () => {
    const tree = treeLib.initTree()
    const ipfsHash = await saveData(JSON.stringify(tree))
    return ipfsHash
}

const saveTree = jsonData => {
    const stringData = JSON.stringify(jsonData)
    return saveData(stringData)
}

const getTree = async ipfsHash => {
    const stringTree = await getData(ipfsHash)
    return JSON.parse(stringTree)
}

const saveData = stringData => {
    const data = Buffer.from(stringData)
    return new Promise((resolve, reject) => {
        ipfs.files.add(data, (err, cid) => {
            if(err) reject(err)
            else resolve(cid[0].path)
        })
    }) 
}

const getData = ipfsHash => {
    return new Promise((resolve, reject) => {
        ipfs.files.get(`/ipfs/${ipfsHash}`, (err, data) => {
            if(err) reject(err)
            else resolve(data[0].content.toString())
        })
    })
}

const dfs = async (ipfsTreeHash, search) => {
    const tree = await getTree(ipfsTreeHash)
    console.log(tree)
    return treeLib.dfs(tree, search)
}

const insertNodes = async (ipfsTreeHash, insertions) => {
    const tree = await getTree(ipfsTreeHash)
    await handleInsertions(tree, insertions)    
    const treeHash = await saveTree(tree)
    return treeHash
}

const handleInsertions = async (tree, insertions, parentLabel = null) => {
    await insertions.forEach(async  insertion => {
        parentLabel = parentLabel ? parentLabel : insertion.parentLabel
        let data = null
        let childrens = null
        if(!(insertion.childrens && insertion.childrens.length > 0)){
            if(insertion.data) {
                data = insertion.data
            }  
            childrens = null            
        }
        if(data) data = await saveData(data)
        treeLib.insertNode(tree, parentLabel, insertion.label, data)
        if(insertion.childrens && insertion.childrens.length > 0)
            await handleInsertions(tree, insertion.childrens, insertion.label)
        return tree
    })
} 

const updateNode = async (ipfsTreeHash, search, data) => {
    const dataIpfsHash = await saveData(data)
    const tree = await getTree(ipfsTreeHash)
    treeLib.updateNode(tree, search, dataIpfsHash)
    return await saveTree(tree)
}

const removeNode = async (ipfsTreeHash, search, data) => {
    const tree = await getTree(ipfsTreeHash)
    treeLib.removeNode(tree, search)
    return await saveTree(tree)
}

module.exports = { 
    setProvider,
    initTree,
    saveTree,
    saveData,
    getTree,
    getData,
    dfs,
    insertNodes,
    updateNode,
    removeNode,
}