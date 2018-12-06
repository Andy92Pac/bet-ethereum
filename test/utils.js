var bs58 = require('bs58');

exports.getBytes32FromIpfsHash = function(ipfsListing) {
	return "0x"+bs58.decode(ipfsListing).slice(2).toString('hex')
}

exports.getIpfsHashFromBytes32 = function(bytes32Hex) {
	const hashHex = "1220" + bytes32Hex.slice(2)
	const hashBytes = Buffer.from(hashHex, 'hex');
	const hashStr = bs58.encode(hashBytes)
	return hashStr
}

exports.timeTravel = async function() {
	return new Promise((resolve) => {
		web3.currentProvider.send({
			jsonrpc: '2.0', 
			method: 'evm_increaseTime', 
			params: [10000], 
			id: new Date().getSeconds()
		}, (err, resp) => {
			if (!err) {
				web3.currentProvider.send({
					jsonrpc: '2.0', 
					method: 'evm_mine', 
					params: [], 
					id: new Date().getSeconds()
				}, () => {
					resolve();
				})
			}
		})
	})
}

exports.snapshot = async function() {
	return new Promise((resolve) => {
		web3.currentProvider.send({
			jsonrpc: '2.0', 
			method: 'evm_snapshot', 
			params: [], 
			id: new Date().getSeconds()
		}, (err, res) => {
			resolve(res);
		})
	})
}

exports.revert = async function(id) {
	return new Promise((resolve) => {
		web3.currentProvider.send({
			jsonrpc: '2.0', 
			method: 'evm_revert', 
			params: [id], 
			id: new Date().getSeconds()
		}, () => {
			resolve();
		})
	})
}