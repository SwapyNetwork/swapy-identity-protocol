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

const getTree = ipfsHash => {
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
    return treeLib.dfs(tree, search)
}

/*
    insertion = {
        parentLabel : string,
        label : string,
        data : string
        or 
        childrens: [{
            label : string,
            data: string
            or 
            childrens : [...]
        }]
    }

*/

const insertNodes = async (ipfsTreeHash, insertions) => {
    const tree = await getTree(ipfsTreeHash)
    handleInsertions(tree, insertions)       
    return await saveTree(tree)
}

const handleInsertions = (tree, insertions, parentLabel = null) => {
    insertions.forEach(insertion => {
        parentLabel = parentLabel ? parentLabel : insertion.parentLabel
        let data = null
        if(!(insertion.childrens && insertion.childrens.length > 0)){
            if(insertion.data) data = insertion.data 
        }
        
    })
} 

/*let hash = null
if(data && !childrens) data = await saveData(data)
else hash = data      
treeLib.insertNode(tree, parentLabel, label, hash, childrens)*/


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
    insertNode,
    updateNode,
    removeNode,
}