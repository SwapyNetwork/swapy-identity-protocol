var IdentityProtocol = artifacts.require("./IdentityProtocol.sol");

module.exports = function(deployer, network, accounts) {
    if(network.indexOf('test') != -1) return
    deployer.deploy(IdentityProtocol)
};
