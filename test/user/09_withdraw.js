var SocialBet = artifacts.require("./../SocialBet.sol");

contract('SocialBet', (accounts) => {

	let exceptions = require("./../exceptions.js");


	let instance;
	let watcher;
	let logEvents;
	
	let owner;
	let admin;
	let user;
	let userBalance;
	let contractBalance;

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

	it("should revert because of the empty balance", async () => {

		userBalance = await instance.balances.call(user);

		if(parseInt(userBalance) > 0)
			await instance.withdraw(parseInt(userBalance), {from: user});

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);

		await exceptions.catchRevert(instance.withdraw(web3.utils.toWei('1', 'ether'), {from: user}));

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);
	});

	it("should revert because try to withdraw too much", async () => {

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		oldUserBalance = await instance.balances.call(user);

		await exceptions.catchRevert(instance.withdraw(oldUserBalance.toString()+1, {from: user}));

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(userBalance.toString(), oldUserBalance.toString());
	});

	it("should withdraw 1 ETH", async () => {

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		oldUserBalance = await instance.balances.call(user);

		await instance.withdraw(web3.utils.toWei('1', 'ether'), {from: user});

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(parseInt(userBalance), parseInt(oldUserBalance) - web3.utils.toWei('1', 'ether'));
	});
})