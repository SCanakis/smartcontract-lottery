from brownie import Lottery, accounts, config, network
from scripts.helpful_scripts import deploy_mocks 
from web3 import Web3


def test_get_entrance_fee():
    account = accounts[0]
    lottery = Lottery.deploy(config["networks"][network.show_active()]["eth_usd_price_feed"], 50, {"from" : account})
    assert lottery.getPrice() > Web3.to_wei(0.013, "ether")
    assert lottery.getPrice() < Web3.to_wei(0.015, "ether")