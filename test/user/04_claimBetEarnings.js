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

	let betId;
	let canceledEventBetId;

	let approvedAmount = web3.utils.toWei('2', 'ether');

	let balanceOfferOwner;
	let balanceOfferBuyer;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		await instance.addAdmin(admin, {from: owner});

		now = await time.latest();

		await token.deposit({from: offerOwner, value: approvedAmount});
		await token.approve(instance.address, approvedAmount, {from: offerOwner});

		await token.deposit({from: offerBuyer, value: approvedAmount});
		await token.approve(instance.address, approvedAmount, {from: offerBuyer});

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);
		let markets = [marketIndex];
		let data = [''];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});
		eventId = await instance.m_nbEvents.call();

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});
		canceledEventId = await instance.m_nbEvents.call();
		
		timestampExpiration = parseInt(now) + 1000;

		await instance.openOffer(eventId, marketIndex, amount, price, outcome, timestampExpiration, {from: offerOwner});
		offerId = await instance.m_nbOffers.call();

		await instance.buyOffer(offerId, amount, {from: offerBuyer});

		betId = await instance.m_nbBets.call();

		await instance.setEventResult(eventId, [marketIndex], [outcome], {from: admin});

		await instance.openOffer(canceledEventId, marketIndex, amount, price, outcome, timestampExpiration, {from: offerOwner});
		offerId = await instance.m_nbOffers.call();

		await instance.buyOffer(offerId, amount, {from: offerBuyer});

		canceledEventBetId = await instance.m_nbBets.call();

		await instance.cancelEvent(canceledEventId, {from: admin});
	});

	it("should send back funds to both users", async () => {
		balanceOfferBuyer = await token.balanceOf(offerBuyer);
		balanceOfferOwner = await token.balanceOf(offerOwner);

		await instance.claimBetEarnings(canceledEventBetId);

		let expectedBalanceOfferBuyer = parseInt(balanceOfferBuyer) + parseInt(amount);
		let expectedBalanceOfferOwner = parseInt(balanceOfferOwner) + parseInt(amount);

		balanceOfferBuyer = await token.balanceOf(offerBuyer);
		balanceOfferOwner = await token.balanceOf(offerOwner);

		assert.equal(balanceOfferBuyer.toString(), expectedBalanceOfferBuyer.toString());
		assert.equal(balanceOfferOwner.toString(), expectedBalanceOfferOwner.toString());
	});

	it("should send funds to winner of the bet", async () => {
		balanceOfferBuyer = await token.balanceOf(offerBuyer);
		balanceOfferOwner = await token.balanceOf(offerOwner);

		await instance.claimBetEarnings(betId);

		let expectedBalanceOfferBuyer = parseInt(balanceOfferBuyer) + 2 * parseInt(amount);
		let expectedBalanceOfferOwner = parseInt(balanceOfferOwner);

		balanceOfferBuyer = await token.balanceOf(offerBuyer);
		balanceOfferOwner = await token.balanceOf(offerOwner);

		assert.equal(balanceOfferBuyer.toString(), expectedBalanceOfferBuyer.toString());
		assert.equal(balanceOfferOwner.toString(), expectedBalanceOfferOwner.toString());
	});
});