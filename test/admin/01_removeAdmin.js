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

	it("should remove admin", async () => {

		await instance.addAdmin(admin, {from: owner});

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);

		await instance.removeAdmin(admin, {from: owner});

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, false);
	});

	it("should abort because user can't remove admin", async () => {

		await instance.addAdmin(admin, {from: owner});

		await catchRevert(instance.removeAdmin(admin, {from: user}));

		isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);
	});

	it("should abort because owner can't remove owner from admin", async () => {

		isAdmin = await instance.admins.call(owner);

		assert.equal(isAdmin, true);

		await catchRevert(instance.removeAdmin(owner, {from: owner}));

		isAdmin = await instance.admins.call(owner);

		assert.equal(isAdmin, true);
	});
})