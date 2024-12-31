from brownie import accounts, config, network, MockV3Aggregator, Contract

FORKED_ENVIORMENTS = ["mainnet_fork"]
LOCAL_ENVIRONMENTS = ["development", "ganache-local"]

DECIMALS = 8
INITIAL_PRICE = 2000 * 10 ** 8

def get_account(index=None, id=None):

    if(index):
        return accounts[index]
    
    if(id):
        return accounts.load(id) 
    
    if(network.show_active() in FORKED_ENVIORMENTS or network.show_active() in LOCAL_ENVIRONMENTS):
        return accounts[0]
    
    return accounts.add(config["wallets"]["from_key"])
    

def deploy_mocks(decimals = DECIMALS, inital_price = INITIAL_PRICE):
    print("The active network is " + network.show_active())
    print("Deploying Mocks...")
    if(len(MockV3Aggregator) <= 0):
        MockV3Aggregator.deploy(decimals, inital_price, {"from" : get_account()})
    print("Mocks Deployed!")



contract_to_mock = {

    "eth_usd_price_feed" : MockV3Aggregator,


}

def get_contract(contract_name):

    """
    This fucntion will grab contract addresses from brownie configs if defined,
    otherwise it will deploy mock version of that contract, and return that 
    mock contract.

    Args:
        contract_name(string)

    Returns:
        brownie.network.contract.ProjectContract:
            The most recently deployed version of this contract.
    """

    contract_type = contract_to_mock[contract_name]

    if network.show_active() in LOCAL_ENVIRONMENTS:
        if len(contract_type) <= 0:
            deploy_mocks()
        contract = contract_type[-1]
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        contract = Contract.from_abi(contract_type._name, contract_address, contract_type.abi)

    return contract
