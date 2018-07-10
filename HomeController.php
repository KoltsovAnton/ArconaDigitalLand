<?php

namespace App\Http\Controllers;


use kornrunner\Keccak;
use Web3p\RLP\RLP;
use App\JSON_RPC;
use kornrunner\Ethereum\Transaction;
use BN\BN;


class HomeController
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {

    }
 

    //"ac8e26d0": "createLand(address,string,string,string,string,string)",
    public function createLand()
    {

        //адрес и приватный ключ от которого отправляется транзакция.
        $addressFrom = '';
        $privateKey = '';

        //Адрес контракта токена
        $contractAddr = '0xdf4d691c84519caf7de74281fe57f60740c23d77';

        //параметры для метода createLand
        $owner = $this->createAddrParam('0x02A3D45252Fa254bA7Bb42C5D8D3ED2c0FCdC8Df');
        $name =  'test1';
        $cord1 = '47.244717, 39.701625';
        $cord2 = '47.244717, 39.701625';
        $cord3 = '47.244717, 39.701625';
        $cord4 = '47.244717, 39.701625';


        $rpc = new JSON_RPC('https://rinkeby.infura.io/oLaEtrL2ogdAD8qZpXk2');

        $chainID = 4;

        $nonce = $rpc->request('eth_getTransactionCount',$addressFrom,'latest');
        $nonce['result'] = $nonce['result'] == '0x0' ? '' : $nonce['result'];
        $gasPrice = $rpc->request('eth_gasPrice');


        $lenName  = $this->createParam(dechex(strlen($name)));
        $lencord1 = $this->createParam(dechex(strlen($cord1)));
        $lencord2 = $this->createParam(dechex(strlen($cord2)));
        $lencord3 = $this->createParam(dechex(strlen($cord3)));
        $lencord4 = $this->createParam(dechex(strlen($cord4)));

        $name =  $this->createLeftParam(bin2hex($name));
        $cord1 = $this->createLeftParam(bin2hex($cord1));
        $cord2 = $this->createLeftParam(bin2hex($cord2));
        $cord3 = $this->createLeftParam(bin2hex($cord3));
        $cord4 = $this->createLeftParam(bin2hex($cord4));
        $offset = '00000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c0';

        $nonce    = $nonce['result'];
        $gasPrice = $gasPrice['result'];
        $gasLimit = '0x493E0';
        $to       = $contractAddr;
        $value    = '0';
        $data     = '0xac8e26d0' . $owner . $offset . $lenName . $name . $lencord1 . $cord1 . $lencord2 . $cord2 . $lencord3 . $cord3 . $lencord4 . $cord4;


        $transaction = new Transaction($nonce, $gasPrice, $gasLimit, $to, $value, $data);
        $rawTx = $transaction->getRaw($privateKey, $chainID);

        $res = $rpc->request('eth_sendRawTransaction','0x'.$rawTx);


        if (isset($res['error'])) {
            return $res;
        }

        if(preg_match('/[a-f0-9]+/', $res['result'])) {
            return $res['result'];
        }

        return $res;
    }



    public function createParam($val) {
        if(substr($val, 0, 2) == '0x')
            $val = substr($val, 2);

        $zeroVal = '0000000000000000000000000000000000000000000000000000000000000000';

        $res = substr($zeroVal, 0, strlen($zeroVal)-strlen($val)).$val;

        return $res;
    }

    public function createLeftParam($val) {
        if(substr($val, 0, 2) == '0x')
            $val = substr($val, 2);

        $zeroVal = '0000000000000000000000000000000000000000000000000000000000000000';

        $res = $val.substr($zeroVal, 0, strlen($zeroVal)-strlen($val));

        return $res;
    }

    public function createAddrParam($addr) {
        if(substr($addr, 0, 2) == '0x')
            $addr = substr($addr, 2);
        return '000000000000000000000000'.$addr;
    }
}
