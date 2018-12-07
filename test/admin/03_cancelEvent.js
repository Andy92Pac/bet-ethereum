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
	let event;

	before("setup", async () => {
		
		owner = accounts[0];
		admin = accounts[1];
		user = accounts[2];

		instance = await SocialBet.deployed();

		await instance.addAdmin(admin, {from: owner});

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);
	});

	it("should cancel event", async () => {

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 1000;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.cancelEventBulk([nbEvents], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 2); // 2 is value for CANCELED state
	});

	it("should not cancel because event does not exists", async () => {

		event = await instance.events.call(2);

		assert.equal(event._state.toString(), 0);

		await instance.cancelEventBulk([2], {from: admin});

		event = await instance.events.call(2);

		assert.equal(event._state.toString(), 0);
	});

	it("should not cancel because event is closed already", async () => {

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		var snapshotId = (await utils.snapshot()).result;
		await utils.timeTravel();
		
		await instance.setEventResultBulk([nbEvents], [1]);

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state

		await instance.cancelEventBulk([nbEvents], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1);

		await utils.revert(snapshotId);
	})

})