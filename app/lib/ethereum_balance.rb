class EthereumBalance

  def self.get
    uri = URI( Currency.find_by_code('eth').rpc )
    web3 = Web3::Eth::Rpc.new({host: uri.host, port: uri.port})
    accounts = web3.eth.accounts
    accounts.inject(0) { |sum, account| sum + web3.eth.getBalance(account) }
  end

  def self.get_erc20 currency
    uri = URI( currency.rpc )
    web3 = Web3::Eth::Rpc.new({host: uri.host, port: uri.port})
    api = Web3::Eth::Etherscan.new currency[:etherscan_api_key]
    sleep 3
    abi = api.contract_getabi address: currency[:erc20_contract_address]

    myContract = web3.eth.contract(abi)
    myContractInstance = myContract.at(currency[:erc20_contract_address])

    accounts = web3.eth.accounts
    balance = accounts.inject(0) { |sum, account| sum + myContractInstance.balanceOf(account) }
    CoinRPC[currency[:key]].convert_from_base_unit(balance)
  end

end