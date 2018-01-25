const sha3_256 = require('js-sha3').sha3_256;

// init tree structure
const initTree = () => { 
    return { label : 'root', hash : null }
}

// apply a depth-first search and insert a new node under the parentLabel
const insertNode = (node, parentLabel, label, hash) => {
    if(node.label === parentLabel) {
        const newNode = { label, hash }
        if(node.childrens && node.childrens.length > 0) node.childrens.push(newNode)
        else node.childrens = [newNode]
        node = renewNodeHash(node)
        return node
    }
    else if(node.childrens && node.childrens.length > 0) {
        for(let i = 0; i < node.childrens.length; i++){
            result = insertNode(node.childrens[i], parentLabel, label, hash)
            if(result) {
                node = renewNodeHash(node)
                return node
            }
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
const renewNodeHash = node => {
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
    initTree,
    insertNode,
    updateNode,
    removeNode,
    dfs,
}   