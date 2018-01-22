const sha3_256 = require('js-sha3').sha3_256;
const ipfsAPI = require('ipfs-api')
let ipfs = null;

const setProvider = (host,port,protocol) => {
    ipfs = ipfsAPI({host, port, protocol})
}

const getIpfsTree = (ipfsHash) => {
    return new Promise((resolve, reject) => {
        ipfs.files.get(`/ipfs/${ipfsHash}`, (err, data) => {
            if(err) reject(err)
            else resolve(JSON.parse(data[0].content.toString()))
        })
    })
}

const initTreeIpfs = async () => {
    const tree = initTree()
    const ipfsHash = await saveIpfsData(JSON.stringify(tree))
    return ipfsHash
}

const saveIpfsData = (stringData) => {
    const data = Buffer.from(stringData)
    return new Promise((resolve, reject) => {
        ipfs.files.add(data, (err, cid) => {
            if(err) reject(err)
            else resolve(cid[0].path)
        })
    }) 
}

const getIpfsData = (ipfsHash) => {
    return new Promise((resolve, reject) => {
        ipfs.files.get(`/ipfs/${ipfsHash}`, (err, data) => {
            if(err) reject(err)
            else resolve(data[0].content.toString())
        })
    })
}

const insertNodeIpfs = async (ipfsTreeHash, parentLabel, label, data, childrens = null) => {
    let hash = null
    if(data && !childrens) data = await saveIpfsData(data)
    else hash = data      
    const stringTree = await getIpfsData(ipfsTreeHash)
    const tree = JSON.parse(stringTree)
    insertNode(tree, parentLabel, label, hash, childrens)
    return await saveIpfsData(JSON.stringify(tree))
}

const updateNodeIpfs = async (ipfsTreeHash, search, data) => {
    const dataIpfsHash = await saveIpfsData(data)
    const stringTree = await getIpfsData(ipfsTreeHash)
    const tree = JSON.parse(stringTree)
    updateNode(tree, search, dataIpfsHash)
    return await saveIpfsData(JSON.stringify(tree))
}

const removeNodeIpfs = async (ipfsTreeHash, search, data) => {
    const stringTree = await getIpfsData(ipfsTreeHash)
    const tree = JSON.parse(stringTree)
    removeNode(tree, search)
    return await saveIpfsData(JSON.stringify(tree))
}

const dfsIpfs = async (ipfsTreeHash, search) => {
    const stringTree = await getIpfsData(ipfsTreeHash)
    const tree = JSON.parse(stringTree)
    return dfs(tree, search)
}


// init tree structure
const initTree = () => { 
    return { label : 'root', hash : null }
}

// apply a depth-first search and insert a new node under the parentLabel
const insertNode = (node, parentLabel, label, hash, childrens = null) => {
    if(node.label === parentLabel) {
        let newNode = {}
        if(childrens) newNode = { label, hash, childrens }
        else newNode = { label, hash }
        if(node.childrens && node.childrens.length > 0) node.childrens.push(newNode)
        else node.childrens = [newNode]    
        return renewNodeHash(node)
    } 
    else if(node.childrens && node.childrens.length > 0) {
        for(let i = 0; i < node.childrens.length; i++){
            result = insertNode(node.childrens[i], parentLabel, label, hash, childrens)
            if(result) return renewNodeHash(node)
        }
    }
    return null  
}

// apply a depth-first search and return the node with its childrens 
const dfs = (node, search) => {
    if(node.label === search) return node
    else if(node.childrens && node.childrens.length > 0) {
        for(let i = 0; i < node.childrens.length; i++){
            result = dfs(node.childrens[i], search)
            if(result) return result
        }
    }
    return null  
}

// apply a depth-first search, update the node and parent's hash  
const updateNode = (node, search, data) => {
    if(node.label === search && (!node.childrens || node.childrens.length === 0)) {
        node.hash = data;
        return node
    }
    else if(node.childrens && node.childrens.length > 0) {
        for(let i = 0; i < node.childrens.length; i++){
            result = updateNode(node.childrens[i], search, data)
            if(result) return renewNodeHash(node)
        }
    }
    return null  
}

// apply a depth-first search, remove the node and update its parent's hash
const removeNode = (node, search) => {
    if(search === 'root') return false
    if(node.label === search) return node
    else if(node.childrens && node.childrens.length > 0) {
        for(let i = 0; i < node.childrens.length; i++){
            result = removeNode(node.childrens[i], search)
            if(result && result.label === search) {
                node.childrens.splice(i,1)
            }
            if(result) return renewNodeHash(node)
        }
    }
    return null  
}


// renew node's hash following its childrens hashes
const renewNodeHash = (node) => {
    if(node.childrens && node.childrens.length > 0)  { 
        let data = null;
        for(let j = 0; j < node.childrens.length; j++){
            if(node.childrens[j].hash) {
                if(data) data += node.childrens[j].hash  
                else data = node.childrens[j].hash
            } 
        }
        if(data) node.hash = sha3_256(data)  
    }
    return node
}

module.exports = { 
    setProvider,
    initTree,
    initTreeIpfs,
    saveIpfsData,
    getIpfsTree,
    insertNodeIpfs,
    updateNodeIpfs,
    removeNodeIpfs,
    dfsIpfs,
    insertNode,
    updateNode,
    removeNode,
    dfs,
}   