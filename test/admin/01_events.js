const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert, time } = require('openzeppelin-test-helpers');
const utils = require("./../utils.js");

contract('SocialBet', ([owner, admin, user, ...accounts]) => {

	let instance;
	let token;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		await instance.addAdmin(admin, {from: owner});
	});


	it("should add new event", async () => {
		let currentNbEvents = await instance.m_nbEvents.call();

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let timestampStart = await time.latest();

		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);

		let txReceipt = await instance.addEvent(bytes32, timestampStart, [], [], {from: admin});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewEvent');

		let newNbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(newNbEvents), parseInt(currentNbEvents) + 1);
	});

	it("should revert because user is not admin", async () => {
		let currentNbEvents = await instance.m_nbEvents.call();

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let timestampStart = await time.latest();

		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);

		await expectRevert(
			instance.addEvent(bytes32, timestampStart, [], [], {from: user}),
			'Sender is not an admin');

		let newNbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(newNbEvents), parseInt(currentNbEvents));
	});

	it("should add markets to event", async () => {
		let nbEvents = await instance.m_nbEvents.call();

		let markets = [0, 2, 3];
		let data = ['', '125', '+12.5'];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		let txReceipt = await instance.addMarkets(nbEvents, markets, dataToBytes10, {from: admin});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewMarkets');
	});

	it("should set event result", async () => {
		let nbEvents = await instance.m_nbEvents.call();

		let event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		let markets = [0, 2, 3];
		let outcomes = [2, 5, 2];

		let txReceipt = await instance.setEventResult(nbEvents, markets, outcomes, {from: admin});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogResultEvent',
			{
				id: nbEvents
			});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state

		let market;

		for(let i=0; i<markets.length; i++) {
			market = await instance.getMarket(event._id, markets[i]);
			assert.equal(market._outcome, outcomes[i]);
		}
	});

	it("should cancel event", async () => {

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let timestampStart = await time.latest();

		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);

		await instance.addEvent(bytes32, timestampStart, [], [], {from: admin});

		let nbEvents = await instance.m_nbEvents.call();

		let event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.cancelEvent(nbEvents, {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 2); // 2 is value for CANCELED state
	});
})