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

		assert.equal(userBalance, 0);

		await exceptions.catchRevert(instance.withdraw(web3.utils.toWei('1', 'ether'), {from: user}));

		userBalance = await instance.balances.call(user);

		assert.equal(userBalance, 0);
	});

	it("should revert because try to withdraw too much", async () => {

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(userBalance, 0);
		assert.equal(contractBalance, 0);

		await instance.deposit({from: user, value: web3.utils.toWei('1', 'ether')});

		userBalance = await instance.balances.call(user);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);

		await exceptions.catchRevert(instance.withdraw(web3.utils.toWei('2', 'ether'), {from: user}));

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);
		assert.equal(web3.utils.fromWei(contractBalance), 1);
	});

	it("should withdraw 1 ETH", async () => {

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(web3.utils.fromWei(userBalance.toString(), 'ether'), 1);
		assert.equal(web3.utils.fromWei(contractBalance), 1);

		await instance.withdraw(web3.utils.toWei('1', 'ether'), {from: user});

		userBalance = await instance.balances.call(user);
		contractBalance = await web3.eth.getBalance(instance.address);

		assert.equal(userBalance, 0);
		assert.equal(contractBalance, 0);
	});

})