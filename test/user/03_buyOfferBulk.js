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
	let amount = web3.utils.toWei('2', 'ether');
	let price = amount;
	let outcome = 2;
	let timestampExpiration;

	let offerId1;
	let offerId2;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);

		await instance.addAdmin(admin, {from: owner});

		now = await time.latest();

		await token.deposit({from: offerOwner, value: amount});
		await token.approve(instance.address, amount, {from: offerOwner});

		await token.deposit({from: offerBuyer, value: amount});
		await token.approve(instance.address, amount, {from: offerBuyer});

		let ipfsHash = "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4";
		let bytes32 = utils.getBytes32FromIpfsHash(ipfsHash);
		let markets = [marketIndex];
		let data = [''];
		let dataToBytes10 = data.map(e => web3.utils.asciiToHex(e)); 

		await instance.addEvent(bytes32, markets, dataToBytes10, {from: admin});
		eventId = await instance.m_nbEvents.call();

		timestampExpiration = parseInt(now) + 1000;

		let amountOffer = web3.utils.toWei('1', 'ether');
		let priceOffer = amountOffer;

		await instance.openOffer(eventId, marketIndex, amountOffer, priceOffer, outcome, timestampExpiration, {from: offerOwner});
		offerId1 = await instance.m_nbOffers.call();

		await instance.openOffer(eventId, marketIndex, amountOffer, priceOffer, outcome, timestampExpiration, {from: offerOwner});
		offerId2 = await instance.m_nbOffers.call();
	});

	it("should revert because amount is below minimum", async () => {
		await token.approve(instance.address, amount, {from: offerOwner});

		await expectRevert(
			instance.buyOfferBulk([offerId1, offerId2], '1000', {from: offerBuyer}),
			'Amount is below minimum');
	});

	it("should revert because amount exceeds sender balance", async () => {
		await expectRevert(
			instance.buyOfferBulk([offerId1, offerId2], web3.utils.toWei('3', 'ether'), {from: offerBuyer}),
			'Amount exceeds sender balance');
	});

	it("should revert because amount exceeds sender allowance", async () => {
		await token.approve(instance.address, '1000', {from: offerBuyer});

		await expectRevert(
			instance.buyOfferBulk([offerId1, offerId2], amount, {from: offerBuyer}),
			'Amount exceeds sender allowance');
	});

	it("should buy offers", async () => {
		await token.approve(instance.address, amount, {from: offerBuyer});

		let txReceipt = await instance.buyOfferBulk([offerId1, offerId2], amount, {from: offerBuyer});

		let nbPosition = await instance.m_nbPositions.call();
		let nbBets = await instance.m_nbBets.call();

		let amountPosition = web3.utils.toWei('1', 'ether');

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewPosition',
			{
				id: (nbPosition - 3).toString(),
				betId: (nbBets - 1).toString(),
				owner: offerBuyer,
				amount: amountPosition
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewPosition',
			{
				id: (nbPosition - 2).toString(),
				betId: (nbBets - 1).toString(),
				owner: offerOwner,
				amount: amountPosition
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewBet',
			{
				id: (nbBets - 1).toString(),
				eventId: eventId,
				marketIndex: marketIndex.toString(),
				backPosition: (nbPosition - 3).toString(),
				layPosition: (nbPosition - 2).toString(),
				amount: amount.toString(),
				outcome: outcome.toString(),
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogUpdateOffer',
			{
				id: offerId1,
				amount: '0',
				price: '0',
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewPosition',
			{
				id: (nbPosition - 1).toString(),
				betId: nbBets.toString(),
				owner: offerBuyer,
				amount: amountPosition
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewPosition',
			{
				id: nbPosition,
				betId: nbBets.toString(),
				owner: offerOwner,
				amount: amountPosition
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogNewBet',
			{
				id: nbBets.toString(),
				eventId: eventId,
				marketIndex: marketIndex.toString(),
				backPosition: (nbPosition - 1).toString(),
				layPosition: nbPosition,
				amount: amount.toString(),
				outcome: outcome.toString(),
			});

		await expectEvent.inTransaction(
			txReceipt.tx, 
			SocialBet,
			'LogUpdateOffer',
			{
				id: offerId2,
				amount: '0',
				price: '0',
			});
			
	});
});