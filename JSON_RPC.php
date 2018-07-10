<?php

namespace App;

use Exception;

class JSON_RPC
{
    protected $host, $port, $version;
    protected $id = 0;

    function __construct($host = 'https://rinkeby.infura.io/oLaEtrL2ogdAD8qZpXk2')
    {


        $this->host = $host;
        $this->port = env('ETH_PORT', 443);
        $this->version = "2.0";
    }

    function request($method, $params=array(), $block = '')
    {

        $params = empty($block) ? '['. json_encode($params) .  ']' : '['. json_encode($params) .',"'.$block.'"]';


        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $this->host);
        curl_setopt($ch, CURLOPT_PORT, $this->port);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
        curl_setopt($ch, CURLOPT_POST, TRUE);
        //curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($params));
        curl_setopt($ch, CURLOPT_POSTFIELDS, '{"jsonrpc":"'.$this->version.'", "method":"'.$method.'", "params":'.$params.', "id":1}');

        $ret = curl_exec($ch);
        if($ret !== FALSE)
        {
            $formatted = $this->format_response($ret);

            if(isset($formatted->error))
            {
                throw new RPCException($formatted->error->message, $formatted->error->code);
            }
            else
            {
                return $formatted;
            }
        }
        else
        {
            throw new RPCException("Server did not respond");
        }
    }

    function format_response($response)
    {
        return @json_decode($response, true);
    }
}

class RPCException extends Exception
{
    public function __construct($message, $code = 0, Exception $previous = null)
    {
        parent::__construct($message, $code, $previous);
    }

    public function __toString()
    {
        return __CLASS__ . ": ".(($this->code > 0)?"[{$this->code}]:":"")." {$this->message}\n";
    }
}
