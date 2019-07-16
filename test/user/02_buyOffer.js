const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert, time } = require('openzeppelin-test-helpers');
const utils = require("./../utils.js");

contract('SocialBet', ([owner, admin, user, offerOwner, offerBuyer, ...accounts]) => {

	let instance;
	let token;

	let now;

	let eventId;
	let closedEventId;
	let marketIndex = 0;
	let amount = web3.utils.toWei('1', 'ether');
	let price = amount;
	let outcome = 2;
	let timestampExpiration;

	let offerId;
	let expiredOfferId;
	let closedEventOfferId;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		await instance.addAdmin(admin, {from: owner});

		now = await time.latest();

		await token.deposit({from: offerOwner, value: amount});
		await token.approve(instance.address, amount, {from: offerOwner});

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);
		let markets = [marketIndex];
		let data = [''];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});
		eventId = await instance.m_nbEvents.call();

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});
		closedEventId = await instance.m_nbEvents.call();
		
		timestampExpiration = parseInt(now) + 1000;

		await instance.openOffer(eventId, marketIndex, amount, price, outcome, timestampExpiration, {from: offerOwner});
		offerId = await instance.m_nbOffers.call();

		let timestampExpirationExpiredOffer = parseInt(now) + 100;

		await instance.openOffer(eventId, marketIndex, amount, price, outcome, timestampExpirationExpiredOffer, {from: offerOwner});
		expiredOfferId = await instance.m_nbOffers.call();

		await time.increase(200);

		await instance.openOffer(closedEventId, marketIndex, amount, price, outcome, timestampExpiration, {from: offerOwner});
		closedEventOfferId = await instance.m_nbOffers.call();

		await instance.cancelEvent(closedEventId, {from: admin});
	});

	it("should revert because offer doesn't exist", async () => {
		let nbOffers = offerId = await instance.m_nbOffers.call();

		let invalidOfferId = (parseInt(nbOffers) + 1).toString();
		
		await expectRevert(
			instance.buyOffer(invalidOfferId, amount, {from: offerBuyer}),
			'Offer id does not exist yet');
	});

	it("should revert because offer is expired", async () => {
		await expectRevert(
			instance.buyOffer(expiredOfferId, amount, {from: offerBuyer}),
			'Offer is expired');
	});

	it("should revert because event is not open", async () => {
		await expectRevert(
			instance.buyOffer(closedEventOfferId, amount, {from: offerBuyer}),
			'Event is not open');
	});

	it("should revert because offer owner balance is below minimum", async () => {

	});

	it("should revert because offer owner allowance is below minimum", async () => {

	});

	it("should revert because amount is below minimum", async () => {

	});

	it("should revert because amount exceeds sender balance", async () => {

	});

	it("should buy the offer", async () => {

	});
});