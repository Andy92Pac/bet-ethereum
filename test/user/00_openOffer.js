const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert, time } = require('openzeppelin-test-helpers');
const utils = require("./../utils.js");

contract('SocialBet', ([owner, admin, user, ...accounts]) => {

	let instance;
	let token;

	let now;

	let eventId;
	let marketIndex = 0;
	let amount = web3.utils.toWei('1', 'ether');
	let price = amount;
	let outcome = 2;
	let timestampExpiration;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		await instance.addAdmin(admin, {from: owner});

		now = await time.latest();

		await token.deposit({from: user, value: amount});
		await token.approve(instance.address, amount, {from: user});

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);
		let markets = [marketIndex];
		let data = [''];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});

		eventId = await instance.m_nbEvents.call();
	});

	it("should open offer", async () => {
		timestampExpiration = parseInt(now) + 1000;

		let txReceipt = await instance.openOffer(eventId, marketIndex, amount, price, outcome, timestampExpiration, {from: user});

		let nbOffers = await instance.m_nbOffers.call();

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewOffer',
			{
				id: nbOffers,
				eventId: eventId,
				marketIndex: marketIndex.toString(),
				owner: user,
				amount: amount,
				price: price,
				outcome: outcome.toString(),
				timestampExpiration: timestampExpiration.toString()
			});

		let offer = await instance.offers.call(nbOffers);

		assert.equal(offer._id.toString(), nbOffers.toString());
		assert.equal(offer._eventId.toString(), eventId.toString());
		assert.equal(offer._marketIndex, marketIndex.toString());
		assert.equal(offer._owner, user);
		assert.equal(offer._amount, amount);
		assert.equal(offer._price, price);
		assert.equal(offer._outcome, outcome.toString());
		assert.equal(offer._timestampExpiration, timestampExpiration.toString());
	});

	it("should revert because event doesn't exist", async () => {
		let invalidEventId = (parseInt(eventId) + 1).toString();
		
		await expectRevert(
			instance.openOffer(invalidEventId, marketIndex, amount, price, outcome, timestampExpiration, {from: user}),
			'Event id does not exist yet');
	})

	it("should revert because market is not available", async () => {
		let invalidMarketIndex = '1';
		
		await expectRevert(
			instance.openOffer(eventId, invalidMarketIndex, amount, price, outcome, timestampExpiration, {from: user}),
			'Market is not available');
	})

	it("should revert because selected outcome is not valid", async () => {
		let invalidOutcome = '5';
		
		await expectRevert(
			instance.openOffer(eventId, marketIndex, amount, price, invalidOutcome, timestampExpiration, {from: user}),
			'Selected outcome is not valid for HOMEAWAYDRAW market');
	})

	it("should revert because price is below minimum", async () => {
		let invalidPrice = '1';
		
		await expectRevert(
			instance.openOffer(eventId, marketIndex, amount, invalidPrice, outcome, timestampExpiration, {from: user}),
			'Price is below minimum');
	})

	it("should revert because amount is below minimum", async () => {
		let invalidAmount = '1';
		
		await expectRevert(
			instance.openOffer(eventId, marketIndex, invalidAmount, price, outcome, timestampExpiration, {from: user}),
			'Amount is below minimum');
	})

	it("should revert because expiration timestamp is in the past", async () => {
		let invalidTimestampExpiration = parseInt(now) - 1000;
		
		await expectRevert(
			instance.openOffer(eventId, marketIndex, amount, price, outcome, invalidTimestampExpiration, {from: user}),
			'Expiration timestamp is in the past');
	})
});