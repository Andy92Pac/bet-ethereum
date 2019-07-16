const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert, time } = require('openzeppelin-test-helpers');
const utils = require("./../utils.js");

contract('SocialBet', ([owner, admin, user, offerOwner, ...accounts]) => {

	let instance;
	let token;

	let now;

	let eventId;
	let marketIndex = 0;
	let amount = web3.utils.toWei('1', 'ether');
	let price = amount;
	let outcome = 2;
	let timestampExpiration;

	let offerId;

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
		timestampExpiration = parseInt(now) + 1000;

		await instance.openOffer(eventId, marketIndex, amount, price, outcome, timestampExpiration, {from: offerOwner});

		offerId = await instance.m_nbOffers.call();
	});

	it("should revert because offer doesn't exist", async () => {
		let invalidOfferId = (parseInt(offerId) + 1).toString();
		
		await expectRevert(
			instance.closeOffer(invalidOfferId, {from: offerOwner}),
			'Offer id does not exist yet');
	})

	it("should revert because sender is not offer owner", async () => {
		await expectRevert(
			instance.closeOffer(offerId, {from: user}),
			'Offer owner is not sender');
	})

	it("should close offer", async () => {
		let txReceipt = await instance.closeOffer(offerId, {from: offerOwner});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogUpdateOffer',
			{
				id: offerId,
				amount: '0',
				price: '0',
			});

		let offer = await instance.offers.call(offerId);

		assert.equal(offer._id.toString(), offerId.toString());
		assert.equal(offer._amount, '0');
		assert.equal(offer._price, '0');
	});

	it("should revert because offer is already closed", async () => {
		await expectRevert(
			instance.closeOffer(offerId, {from: offerOwner}),
			'Offer is already closed');
	})
});