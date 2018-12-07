var SocialBet = artifacts.require("./../SocialBet.sol");

contract('SocialBet', (accounts) => {

	let exceptions = require("./../exceptions.js");
	let utils = require("./../utils.js");

	let instance;
	let watcher;
	let logEvents;

	let owner;
	let admin;
	let user;
	let isAdmin;
	let nbEvents;
	let nbOffers;
	let event;
	let offer;

	before("setup", async () => {
		
		owner = accounts[0];
		admin = accounts[1];
		user = accounts[2];

		instance = await SocialBet.deployed();

		await instance.addAdmin(admin, {from: owner});

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);
	});

	it("should abort because of empty balance", async () => {

		oldNbOffers = await instance.m_nbOffers.call();

		await exceptions.catchRevert(instance.openOffer(nbEvents, web3.utils.toWei('1', 'ether'), web3.utils.toWei('1', 'ether'), 1));

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers));
	});

	it("should abort because of price inferior to min value", async () => {

		oldNbOffers = await instance.m_nbOffers.call();

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await exceptions.catchRevert(instance.openOffer(nbEvents, web3.utils.toWei('1', 'ether'), web3.utils.toWei('0.0001', 'ether'), 1));

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers));
	});

	it("should open offer", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbOffers = await instance.m_nbOffers.call();

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await instance.openOffer(nbEvents, web3.utils.toWei('1', 'ether'), web3.utils.toWei('1', 'ether'), 1, {from: user});

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers) + 1);

		offer = await instance.offers.call(nbOffers);

		assert.equal(offer._id, parseInt(nbOffers));
		assert.equal(offer._eventId, parseInt(nbEvents));
		assert.equal(offer._owner, user);
		assert.equal(offer._amount, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._price, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._pick, 1);
		assert.equal(offer._state, 0);

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 0);

		await utils.revert(snapshotId);
	});

	it("should abort because event is not available", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbOffers = await instance.m_nbOffers.call();

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		await exceptions.catchRevert(instance.openOffer(nbEvents + 1, web3.utils.toWei('1', 'ether'), web3.utils.toWei('1', 'ether'), 1));

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers));

		await utils.revert(snapshotId);
	});

	it("should abort because pick is not valid", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbOffers = await instance.m_nbOffers.call();

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		await exceptions.catchRevert(instance.openOffer(nbEvents, web3.utils.toWei('1', 'ether'), web3.utils.toWei('0.0001', 'ether'), 4));

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers));

		await utils.revert(snapshotId);
	});

})