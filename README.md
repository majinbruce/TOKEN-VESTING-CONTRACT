# TOKEN-VESTING-CONTRACT

## Technology Stack & Tools

* Solidity (Writing Smart Contract)

* Javascript (React & Testing)

* Ethers (Blockchain Interaction)

* Hardhat (Development Framework)

#

### Description:-

#### Token Vesting Contract with 3% TGE for Advisors, 5 % TGE for Partnerships, and 4% TGE for Mentors,</br> admin can create multiple vesting schedules for diffrent address & roles,


#### Code is split into 2 diffrent smart contracts:-

## MyToken.sol contarct

Custom ERC20 token for vesting.

* Contract deployed on rinkeby test network at:

> 0xDD6754CB805140dEa14D6Dd3bA8a7B1f2e4B2168

## vesting.sol contarct

#### Create schedules & claim token every 24hours which are linearly vested </br>



| Roles  | TGE% |
| ------------- | ------------- |
| Advisors   | 3% |
| Partnerships  | 5 %   |
| Mentors  | 4%  |


* Contract deployed on rinkeby test network at:

> 0x73231F79A2605ad1C2A65521F6065BF342Af2B11

## Requirements For Initial Setup

* Install NodeJS, should work with any node version below 16.5.0

* Install Hardhat

## Setting Up

1. Clone/Download the Repository </br>

> git clone https://github.com/majinbruce/TOKEN-VESTING-CONTRACT.git

3. Install Dependencies:

> npm init --yes </br>

> npm install --save-dev hardhat </br>

> npm install dotenv --save </br>

3. Install Plugins:

> npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai </br>

> npm install --save-dev @nomiclabs/hardhat-etherscan  </br>

> npm install @openzeppelin/contracts

4. Compile:

> npx hardhat compile

5. Migrate Smart Contracts

> npx hardhat run scripts/deploy.js --network <network-name>

6. Run Tests

> $ npx hardhat test
