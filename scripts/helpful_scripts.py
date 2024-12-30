from brownie import accounts, config, network, MockV3Aggregator

FORKED_ENVIORMENTS = ["mainnet_fork"]
LOCAL_ENVIRONMENTS = ["development", "ganache-local"]

DECIMALS = 8
INITIAL_PRICE = 2000 * 10 ** 8

def get_account():
    if(network.show_active() not in FORKED_ENVIORMENTS or network.show_active() not in LOCAL_ENVIRONMENTS):
        return accounts.add(config["wallets"]["from_key"])
    else:
        return accounts[0]
    

def deploy_mocks():
    print("The active network is " + network.show_active())
    print("Deploying Mocks...")
    if(len(MockV3Aggregator) <= 0):
        MockV3Aggregator.deploy(DECIMALS, INITIAL_PRICE, {"from" : get_account()})
    print("Mocks Deployed!")