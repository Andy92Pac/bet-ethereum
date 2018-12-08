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
	let userBalance

	before("setup", async () => {
		
		owner = accounts[0];
		admin = accounts[1];
		user = accounts[2];

		instance = await SocialBet.deployed();

		userBalance = await instance.balances.call(user);

		if(parseInt(userBalance) > 0)
			await instance.withdraw(parseInt(userBalance), {from: user});
	});

	it("should be an empty balance", async () => {

		userBalance = await instance.balances.call(user);

		if(parseInt(userBalance) > 0)
			await instance.withdraw(parseInt(userBalance), {from: user});

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);
	});

	it("should be a 1 ETH balance", async () => {

		var snapshotId = (await utils.snapshot()).result;

		userBalance = await instance.balances.call(user);

		if(parseInt(userBalance) > 0)
			await instance.withdraw(parseInt(userBalance), {from: user});

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await utils.revert(snapshotId);
	});


})