const ipfsAPI = require('ipfs-api')
let ipfs = null;

// renew node's hash following its childrens hashes
const renewNodeHash = (node) => {
    node.hash = null
    for(let j = 0; j < node.childrens.length; j++){
        if(node.hash) node.hash += `|${node.childrens[j].hash}`
        else node.hash = node.childrens[j].hash
    }
    return node
}

const setProvider = (host,port,protocol) => {
    ipfs = ipfsAPI({host, port, protocol})
}

const saveIpfsTree = (tree) => {
    const data = Buffer.from(JSON.stringify(tree))
    return new Promise((resolve, reject) => {
        ipfs.files.add(data, (err, cid) => {
            if(err) reject(err)
            else resolve(cid[0].path)
        })
    }) 
}

const getIpfsTree = (ipfsHash) => {
    return new Promise((resolve, reject) => {
        ipfs.files.get(`/ipfs/${ipfsHash}`, (err, data) => {
            if(err) reject(err)
            else resolve(JSON.parse(data[0].content.toString()))
        })
    })
}

// init tree structure
// <persist> save on ipfs or not
const initTree = (persist) => {
    const tree = { label : 'root', hash : null }
    if(persist) {
        const data = Buffer.from(JSON.stringify(tree))
        ipfs.files.add(data, (err, cid) => cid[0].path )
    }
    return tree
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

module.exports = { setProvider, saveIpfsTree, getIpfsTree, initTree, insertNode, dfs, updateNode, removeNode }   