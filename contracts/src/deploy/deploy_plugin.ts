import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getGelatoAddress } from "@gelatonetwork/relay-context";
import { ZeroAddress } from "ethers";
const { ethers } = require('hardhat');

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deployer, recoverer } = await getNamedAccounts();
    console.log(deployer);    
    console.log(await ethers.provider.getBalance(deployer));
    const { deploy } = deployments;

    const wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", ethers.provider);
    const signer = ethers.provider;
    const tx = await wallet.sendTransaction({
        to: "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
        value: "10000000000000000000",
    });
    await tx.wait();
    console.log(`Transaction sent! Hash: ${tx.hash}`);

    // execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)
    // https://www.4byte.directory/signatures/?bytes4_signature=0x6a761202
    const relayMethod = "0x6a761202"
    // We don't use a trusted origin right now to make it easier to test.
    // For production networks it is strongly recommended to set one to avoid potential fee extraction.
    const trustedOrigin = ZeroAddress // hre.network.name === "hardhat" ? ZeroAddress : getGelatoAddress(hre.network.name)
    await deploy("RelayPlugin", {
        from: deployer,
        args: [trustedOrigin, relayMethod],
        log: true,
        deterministicDeployment: true,
    });

    await deploy("WhitelistPlugin", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });

    await deploy("RecoveryWithDelayPlugin", {
        from: deployer,
        args: [recoverer],
        log: true,
        deterministicDeployment: true,
    });

};

deploy.tags = ["plugins"];
export default deploy;