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

		oldNbOffers = await instance.m_nbOffers.call();

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		await instance.openOffer(nbEvents, web3.utils.toWei('1', 'ether'), web3.utils.toWei('1', 'ether'), 1, {from: user});

		nbOffers = await instance.m_nbOffers.call();

		assert.equal(parseInt(nbOffers), parseInt(oldNbOffers) + 1);

		offer = await instance.offers.call(nbOffers);

		assert.equal(offer._id, parseInt(nbOffers));
		assert.equal(offer._eventId.toString(), nbEvents.toString());
		assert.equal(offer._owner, user);
		assert.equal(offer._amount, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._price, web3.utils.toWei('1', 'ether'));
		assert.equal(offer._pick, 1);
		assert.equal(offer._state, 0);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		await instance.buyOffer(offer._id.toString(), offer._price.toString(), {from: user});
	});

	it("should update position", async () => {

		nbPositions = await instance.m_nbPositions.call();

		position = await instance.positions.call(nbPositions);

		assert.equal(position._price, 0);

		await instance.updatePosition(nbPositions, web3.utils.toWei('1', 'ether'), {from: user});

		position = await instance.positions.call(nbPositions);

		assert.equal(position._price, web3.utils.toWei('1', 'ether'));
	});

})