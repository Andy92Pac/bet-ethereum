var SocialBet = artifacts.require("./SocialBet.sol");

module.exports = function(deployer) {
	deployer.deploy(SocialBet);
};