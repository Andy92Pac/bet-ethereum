var SocialBet = artifacts.require("./../SocialBet.sol");

contract('SocialBet', (accounts) => {

	let catchRevert = require("./../exceptions.js").catchRevert;

	let instance;
	let watcher;
	let logEvents;
	let owner;
	let admin;
	let isAdmin;

	before("setup", async () => {
		
		owner = accounts[0];
		admin = accounts[1];
		user = accounts[2];

		instance = await SocialBet.deployed();
	});

	it("should add admin", async () => {

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, false);

		await instance.addAdmin(admin, {from: owner});

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);
	});

	it("should abort because user can't add admin", async () => {

		isAdmin = await instance.admins.call(user);

		await catchRevert(instance.addAdmin(user, {from: user}));

		isAdmin = await instance.admins.call(user);

		assert.equal(isAdmin, false);
	});
})