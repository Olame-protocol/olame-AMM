import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

import fs from "fs";

// const getSecret = (secretKey: string, defaultValue = "") => {
//   const SECRETS_FILE = "./secrets.js";
//   let secret = defaultValue;
//   if (fs.existsSync(SECRETS_FILE)) {
//     const { secrets } = require(SECRETS_FILE);
//     if (secrets[secretKey]) {
//       secret = secrets[secretKey];
//     }
//   }

//   return secret;
// };


const PRIVATE_KEY:any ="01f1f0bd43e981bfef51271a5b8238045aa129008459cac9a378e5b409812e48"


const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      chainId: 44787,
      gas: 10000000,
      accounts: [PRIVATE_KEY],
    }
  },
};

export default config;