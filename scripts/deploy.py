from brownie import Lottery, network, config, MockV3Aggregator
from scripts.helpful_scripts import get_account, deploy_mocks, LOCAL_ENVIRONMENTS, FORKED_ENVIORMENTS, get_contract


USD_ENTRY_PRICE = 50

def deploy_lotter():
    
    account = get_account()

    if(network.show_active() in LOCAL_ENVIRONMENTS):
        deploy_mocks()
        mock_address = MockV3Aggregator[-1].address
    else: 
        mock_address = config["networks"][network.show_active()]["eth_usd_price_feed"]

    # lotter = Lottery.deploy(mock_address, USD_ENTRY_PRICE, {"from" : account}, publish_source=config["networks"][network.show_active()].get("verify"))

    lotter = Lottery.deploy(get_contract("eth_usd_price_feed").address, 50, 100000, get_contract("vrf_coordinator").address)

    print("Contract Deployed!")
    return lotter

def main():
    deploy_lotter()

