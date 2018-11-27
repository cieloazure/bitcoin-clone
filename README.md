# Bitcoin Clone

*Project 4.1 of COP 5536 Distributed Operating System Principles.*

The goal of this project was to learn about internal workings of bitcoin and implement them in Elixir with the help of Erlang's crypto library. The requirements for the first part of the project were as follows - 
> 1. Implement enough of the bitcoin protocol to be able to 
>* Mine bitcoins(For mining, make sure you set the threshold low so you can mine very fast (milliseconds to seconds))
>* Implement wallets (enough to get the other goals)
>* Transact bitcoins. 
> 2. Write test cases verifying the correctness for each task. Specifically, you need to 
>* write unit test (for focused functionality such as correct computation of the hashes)
>* functional tests (simple scenarios in which a transaction happens between two participants).
> 3. **Bonus**: Implements more bitcoin "features" for part I (+20%)

### Functionalities Implemented

#### Core functionalities implemented
1. Mining Blocks/Bitcoins
    - Mine genesis block by setting initial difficulty bits to `1EFFFFFF`
    - Create a candidate block for mining from the blockchain
    - Mine the candidate block by using the calculated difficulty by reaching the specified difficulty
    - The block contains a coinbase transaction which will give bitcoins to the block owner
    - When the block is mined it is broadcasted to the network
    - Consensus is achieved when the nodes accept the block 
2. Wallets
    - Generated private key of the wallet based on a random seed
    - Generated public key of the wallet based on Elliptic curve cryptography
      algorithm
    - Generated Base58Check encoded Bitcoin address using the public key
    - Assists in creating new transactions by assimilation user's unspent
      transaction outputs
3. Transactions
    - *TO BE ADDED*

#### Bonus features implemented
1. Merkle tree for constructing the merkle root of the block header and getting a authentication path for a transaction in order to facilitate light weight nodes
2. Bloom filter to filter out transactions in the blocks
3. Base58 and Base58Check encoding for Bitcoin Wallet's public address
4. Validating the block for correctness
5. Expressing the difficulty of the block in "compact form"
6. Broadcast of the block and transaction using Chord peer to peer network implemented in previous project. Implemented effiecient broadcast in a structured peer to peer network based on this [white paper](http://www-kiv.zcu.cz/~ledvina/DHT/paper3.pdf)
7. Adjust difficulty of the block dynamically by calculating the average time required to mine `10 blocks`; We are assuming it takes `1 second` to mine `1 block` in this simulation and the difficulty will be adjusted if the average is above or below that.
8. Implemented `Pay2PublicKeyHash` for  transactions in which we verify the
   signature of the recipient of the bitcoin using locking and unlocking  
   scripts. Can be extended to implement `Pay2PublicHash`, `Pay2ScriptHash`


### Getting Started
#### From zip directory
Type the following command in your terminal
1. `unzip AkashShingte_PulkitTripathi.zip`
2. `cd bitcoin_clone`

#### From github
Type the following commands in your terminal
1. `git clone https://github.com/cieloazure/bitcoin-clone.git`
2. `cd bitcoin_clone`

### Pre-requisites

You will need Elixir to run this project. 
To install elixir follow instructions given on [Elixir website](https://elixir-lang.org/install.html)

### Installing
Type the following commands in your terminal
1. `mix deps.get`
2. `mix compile`

### Running the tests
You can run the tests with coverage using the command: 

`mix test --trace --cover`

You can view the coverage details in the `cover/` directory 

Functional tests can be executed using

`mix test test/bitcoin/functional_test.exs`

## Authors

* **Pulkit Tripathi**
* **Akash Shingte**

## References

* [Bitcoin white paper](https://bitcoin.org/bitcoin.pdf)
* [Bitcoin.org](https://bitcoin.org/en/)
* [Mastering Bitcoin Book](https://www.docdroid.net/ELs0cbB/mastering-bitcoin.pdf)
* [Bitcoin Wiki](https://en.bitcoin.it/wiki/Main_Page)
* [Effiecient Broadcast in structured peer to peer network](http://www-kiv.zcu.cz/~ledvina/DHT/paper3.pdf)
* [Elixir Docs](https://hexdocs.pm/elixir/Kernel.html)
