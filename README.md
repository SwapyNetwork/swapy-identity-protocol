# Swapy Identity Protocol
[![Join the chat at https://gitter.im/swapynetwork/general](https://badges.gitter.im/swapynetwork/general.svg)](https://gitter.im/swapynetwork/general?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://travis-ci.org/SwapyNetwork/swapy-identity-protocol.svg?branch=master)](https://travis-ci.org/SwapyNetwork/swapy-identity-protocol)


## Table of Contents

* [Overview](#overview)
* [Setup](#setup)

## Overview

* [Self-Sovereign Identity](https://github.com/swapynetwork/wiki/wiki/Self-Sovereign-Identity)
* [Swapy Financial ID](https://github.com/swapynetwork/wiki/wiki/Swapy-Financial-ID)

## Setup

Install [Node v8.9.1](https://nodejs.org/en/download/releases/)

[Truffle](http://truffleframework.com/) is used for deployment. We run the version installed from our dependencies using npm scripts, but if you prefer to install it globally you can do:
```
$ npm install -g truffle
```

Install project dependencies:
```
$ npm install
```
For setup your wallet configuration, addresses and blockchain node provider to deploy, an environment file is necessary. We provide a `sample.env` file. We recommend that you set up your own variables and rename the file to `.env`.

sample.env
```
export NETWORK_ID=...
export PROVIDER_URL="https://yourfavoriteprovider.../..."
export DEV_NETWORK_ID=...
export WALLET_MNEMONIC="twelve words mnemonic ... potato bread coconut pencil"
```
Use your own provider. Some known networks below:
#### NOTE: the current protocol version is not intended to be used on mainnet.

| Network   | Description        | URL                         |
|-----------|--------------------|-----------------------------|
| Mainnet   | main network       | https://mainnet.infura.io   |
| Ropsten   | test network       | https://ropsten.infura.io   |
| INFURAnet | test network       | https://infuranet.infura.io |
| Kovan     | test network       | https://kovan.infura.io     |
| Rinkeby   | test network       | https://rinkeby.infura.io   |
| Local     | Local provider     | http://localhost:8545       |
| Etc       | ...                | ...                         |

Use a NETWORK_ID that matches with your network:
* 0: Olympic, Ethereum public pre-release testnet
* 1: Frontier, Homestead, Metropolis, the Ethereum public main network
* 1: Classic, the (un)forked public Ethereum Classic main network, chain ID 61
* 1: Expanse, an alternative Ethereum implementation, chain ID 2
* 2: Morden, the public Ethereum testnet, now Ethereum Classic testnet
* 3: Ropsten, the public cross-client Ethereum testnet
* 4: Rinkeby, the public Geth Ethereum testnet
* 42: Kovan, the public Parity Ethereum testnet
* 7762959: Musicoin, the music blockchain
* etc

After that, make available your environment file inside the bash context:
```
$ source .env
```

By using a local network, this lecture may be useful: [Connecting to the network](https://github.com/ethereum/go-ethereum/wiki/Connecting-to-the-network)

Compile the contracts with truffle:
```
$ npm run compile
```
Run our migrations:
```
$ npm run migrate
```
We're running the contracts in a custom network defined in  [truffle.js](https://github.com/swapynetwork/swapy-identity-protocol/blob/master/truffle.js).

After the transaction mining, the protocol is disponible for usage.

We're using Truffle's test support. The script scripts/test.sh creates a local network and calls the unit tests.

Type
```
$ npm test
```
and run our tests.

[Truffle console](https://truffle.readthedocs.io/en/beta/getting_started/console/) can be used to interact with protocol. For example:
```
$ truffle console --network custom
```
```
truffle(custom)> IdentityProtocol.deployed(); // ...
```
