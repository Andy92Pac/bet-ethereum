var SocialBet = artifacts.require("./SocialBet.sol");

contract('SocialBet', (accounts) => {

	let catchRevert = require("./exceptions.js").catchRevert;

	let instance;
	let watcher;
	let logEvents;

	"QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4"

	it("should add new event", async () => {
		instance = await SocialBet.deployed();
		
		watcher = instance.LogNewEvent();

		await instance.addEvent("QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4", 1640718470, {from: accounts[0]});

		var nbEvents = await instance.m_nbEvents.call();

		assert.equal(nbEvents, 1);

		logEvents = await watcher.get();

		assert.equal(logEvents.length, 1);
		assert.equal(logEvents[0].args.id.valueOf(), 1);
		assert.equal(web3.toAscii(logEvents[0].args.ipfsAddress.valueOf()), "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4");
		assert.equal(logEvents[0].args.timestampStart, 1640718470);

		var event = await instance.events(1);

		console.log(event);

		assert.equal(event[0].toNumber(), 1);
		assert.equal(web3.toAscii(event[1]), "QmRAQB6YaCyidP37UdDnjFY5vQuiBrcqdyoW1CuDgwxkD4");
		assert.equal(event[2], 1640718470);
		assert.equal(event[3].toNumber(), 0);

		await instance.deposit({from: accounts[0], value: 100000000000});

		await instance.openOffer(1, 2, 1, 1, {from: accounts[0]});

		await instance.buyOffer(1, 1, {from: accounts[0]});

	});
})