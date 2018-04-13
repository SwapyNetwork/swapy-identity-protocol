var IdentityProtocol = artifacts.require("./IdentityProtocol.sol");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(IdentityProtocol)
};
