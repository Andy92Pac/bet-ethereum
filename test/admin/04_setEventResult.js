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

	it("should set event result", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		await utils.timeTravel();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.setEventResultBulk([nbEvents], [1], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state
		assert.equal(event._result.toString(), 1); // 1 is value for HOME result

		await utils.revert(snapshotId);
	});

	it("should revert because arrays are not the same length", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();
		console.log(oldNbEvents.toString());

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();
		console.log(nbEvents.toString());

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		await utils.timeTravel();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await exceptions.catchRevert(instance.setEventResultBulk([nbEvents], [1,2], {from: admin}));

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state
		assert.equal(event._result.toString(), 0); // 0 is value for NULL result

		await utils.revert(snapshotId);

	});

	it("should not set result because event hasn't started", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.setEventResultBulk([nbEvents], [1], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state
		assert.equal(event._result.toString(), 0); // 0 is value for NULL result
		assert.equal(event._resultAttempts.toString(), 0);

		await utils.revert(snapshotId);
	});

	it("should not change event result because event is closed already", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		await utils.timeTravel();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.setEventResultBulk([nbEvents], [1], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state
		assert.equal(event._result.toString(), 1); // 1 is value for HOME result
		assert.equal(event._resultAttempts.toString(), 1);

		await instance.setEventResultBulk([nbEvents], [2], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state
		assert.equal(event._result.toString(), 1); // 1 is value for HOME result
		assert.equal(event._resultAttempts.toString(), 1);

		await utils.revert(snapshotId);
	});

	it("should set event result to canceled because of too many tries to set result", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		await utils.timeTravel();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.setEventResultBulk([nbEvents], [0], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state
		assert.equal(event._result.toString(), 0); // 0 is value for NULL result
		assert.equal(event._resultAttempts.toString(), 1);

		await instance.setEventResultBulk([nbEvents], [0], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for CLOSE state
		assert.equal(event._result.toString(), 0); // 0 is value for NULL result
		assert.equal(event._resultAttempts.toString(), 2);

		await instance.setEventResultBulk([nbEvents], [0], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 1); // 1 is value for CLOSE state
		assert.equal(event._result.toString(), 4); // 1 is value for CANCELED result
		assert.equal(event._resultAttempts.toString(), 3);

		await utils.revert(snapshotId);
	});

	it("should not set event result because of unknown result argument", async () => {

		var snapshotId = (await utils.snapshot()).result;

		oldNbEvents = await instance.m_nbEvents.call();

		var typeArr = [0];
		var ipfsHashArr = ["QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"];
		var timestamp = parseInt((new Date()).getTime() / 1000) + 300;
		var timestampStartArr = [timestamp];

		var bytes32Arr = ipfsHashArr.map((e) => { return utils.getBytes32FromIpfsHash(e); });

		await instance.addEventBulk(typeArr, bytes32Arr, timestampStartArr, {from: admin});

		nbEvents = await instance.m_nbEvents.call();

		assert.equal(parseInt(nbEvents), parseInt(oldNbEvents) + 1);

		await utils.timeTravel();

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state

		await instance.setEventResultBulk([nbEvents], [5], {from: admin});

		event = await instance.events.call(nbEvents);

		assert.equal(event._state.toString(), 0); // 0 is value for OPEN state
		assert.equal(event._result.toString(), 0); // 0 is value for NULL result
		assert.equal(event._resultAttempts.toString(), 1);

		await utils.revert(snapshotId);
	});

})