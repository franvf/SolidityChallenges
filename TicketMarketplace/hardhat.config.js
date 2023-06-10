require("@nomicfoundation/hardhat-toolbox");

const COMPILERS = [
  {
    version: '0.8.1',
  },
   {
    version: '0.6.12',
   },
]

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: COMPILERS
  }
};
