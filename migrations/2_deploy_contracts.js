var SocialBet = artifacts.require('./SocialBet.sol');

module.exports = function(deployer) {
	const maticWethAddress = '0x31074c34a757a4b9FC45169C58068F43B717b2D0';
	deployer.deploy(SocialBet, maticWethAddress);
};