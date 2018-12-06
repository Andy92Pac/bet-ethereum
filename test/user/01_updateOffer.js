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

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(nbEvents, 0);

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(nbEvents, 1);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await instance.openOffer(1, web3.utils.toWei('1', 'ether'), web3.utils.toWei('1', 'ether'), 1, {from: user});

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(nbOffers, 1);

		offer = await instance.offers.call(1);

		assert.equal(offer._id, 1);
		assert.equal(offer._eventId, 1);
		assert.equal(offer._owner, user);
		assert.equal(offer._amount, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._price, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._pick, 1);
		assert.equal(offer._state, 0);

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 0);
	});

	it("should abort because new price is too low", async () => {

		await exceptions.catchRevert(instance.updateOffer(1, web3.utils.toWei('0.0001', 'ether'), {from: user}));

	});

	it("should abort because offer doesn't belong to sender", async () => {

		await exceptions.catchRevert(instance.updateOffer(1, web3.utils.toWei('1.5', 'ether'), {from: admin}));

	});

	it("should abort because event is close", async () => {

		var snapshotId = (await utils.snapshot()).result;

		await utils.timeTravel();

		await exceptions.catchRevert(instance.updateOffer(1, web3.utils.toWei('1.5', 'ether'), {from: user}));

		await utils.revert(snapshotId);
	});

	it("should abort because offer is close", async () => {

		var snapshotId = (await utils.snapshot()).result;

		await instance.closeOffer(1, {from: user});

		offer = await instance.offers.call(1);

		assert.equal(offer._state.toString(), 1);
		assert.equal(offer._amount, 0);
		assert.equal(offer._price, 0);

		await exceptions.catchRevert(instance.updateOffer(1, web3.utils.toWei('1.5', 'ether'), {from: user}));

		await utils.revert(snapshotId);
	});

	it("should update offer", async () => {

		await instance.updateOffer(1, web3.utils.toWei('1.5', 'ether'), {from: user});

		offer = await instance.offers.call(1);

		assert.equal(offer._state.toString(), 0);
		assert.equal(offer._amount, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._price, web3.utils.toWei('1.5', 'ether'));

	});

})