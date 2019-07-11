const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert } = require('openzeppelin-test-helpers');

contract('SocialBet', ([owner, admin, user, ...accounts]) => {

	let instance;
	let token;
	let eventId;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		let amount = web3.utils.toWei('1', 'ether');

		await token.deposit({from: user, value: amount});
		await token.approve(instance.address, amount, {from: user});

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);
		let markets = [0];
		let data = [''];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});

		eventId = await instance.m_nbEvents.call();
		console.log(eventId);
	});

});