var SocialBet = artifacts.require('./SocialBet.sol');

module.exports = function(deployer) {
	const maticWethAddress = '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1';
	deployer.deploy(SocialBet, maticWethAddress);
};