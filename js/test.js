$(document).ready(function () {


    let abi = [ { "anonymous": false, "inputs": [ { "indexed": true, "name": "user", "type": "address" } ], "name": "NewUser", "type": "event" }, { "payable": true, "stateMutability": "payable", "type": "fallback" } ];

    let address = '0x1bd3100ae2d82c73658c467440a6e2d0a259762d';
    let provider = new ethers.providers.Web3Provider(web3.currentProvider, ethers.providers.networks.rinkeby);
    let contract = new ethers.Contract(address, abi, provider.getSigner());


    contract.onnewuser = function(user) {
        console.log(user);
    };

});


