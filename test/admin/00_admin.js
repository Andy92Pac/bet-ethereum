const SocialBet = artifacts.require('./../SocialBet.sol');
const Weth = artifacts.require('./../MaticWETH');
const { BN, expectEvent, expectRevert } = require('openzeppelin-test-helpers');

contract('SocialBet', ([owner, admin, user, ...accounts]) => {

	let instance;
	let token;

	before("setup", async () => {
		token = await Weth.new();
		instance = await SocialBet.new(token.address);
	});

	it("should add admin", async () => {
		await instance.addAdmin(admin, {from: owner});

		let isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);
	});

	it("should revert because user can't add admin", async () => {
		await expectRevert(
			instance.addAdmin(user, {from: user}),
			'Sender it not owner');
	});

	it("should remove admin", async () => {
		await instance.removeAdmin(admin, {from: owner});

		let isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, false);
	});

	it("should revert because user can't remove admin", async () => {
		await instance.addAdmin(admin, {from: owner});

		await expectRevert(
			instance.removeAdmin(admin, {from: user}),
			'Sender it not owner');

		let isAdmin = await instance.admins.call(admin);

		assert.equal(isAdmin, true);
	});

	it("should revert because owner can't be removed from admins", async () => {
		await expectRevert(
			instance.removeAdmin(owner, {from: owner}),
			'Owner can not be removed from admins');

		isAdmin = await instance.admins.call(owner);

		assert.equal(isAdmin, true);
	});
});