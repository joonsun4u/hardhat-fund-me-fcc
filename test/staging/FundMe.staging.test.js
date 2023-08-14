const { assert } = require("chai")
const { network, ethers, getNamedAccounts } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

//let variable = true
//let someVar ? "yes" : "no"
//same as above:
//if (variable) {someVar = "yes"} else (someVar = "no")

developmentChains.includes(network.name)
    ? describe.skip
    : describe("FundMe", async function () {
          let deployer
          let fundMe
          const sendValue = ethers.utils.parseEther("0.000001")
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              fundMe = await ethers.getContract("FundMe", deployer)
          })

          it("allows people to fund and withdraw", async function () {
              await fundMe.fund({ value: sendValue })
              await fundMe.withdraw()
              const endingFundMeBalance = await fundMe.provider.getBalance(
                  fundMe.address
              )
              assert.equal(endingFundMeBalance.toString(), "0")
          })
      })
