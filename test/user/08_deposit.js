var SocialBet = artifacts.require("./../SocialBet.sol");

contract('SocialBet', (accounts) => {

	let exceptions = require("./../exceptions.js");


	let instance;
	let watcher;
	let logEvents;
	
	let owner;
	let admin;
	let user;
	let userBalance

	before("setup", async () => {
		
		owner = accounts[0];
		admin = accounts[1];
		user = accounts[2];

		instance = await SocialBet.deployed();
	});

	it("should be an empty balance", async () => {

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);
	});

	it("should still be an empty balance", async () => {

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);

		await exceptions.catchRevert(instance.deposit({from: user, value: 0}));

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);
	});

	it("should be a 1 ETH balance", async () => {

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);
	});

	it("should be a 2 ETH balance", async () => {

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 2);
	});

})