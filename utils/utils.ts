import fs from "fs";
import path from "path";

const getFilePath = (networkName: string): string => {
  return path.join(__dirname, `../addresses-${networkName}.json`);
};

const getNetworkName = (chainId: number): string => {
  switch (chainId) {
    case 1:
      return "mainnet";
    case 5:
      return "goerli";
    default:
      return "local";
  }
};

export const writeAddresses = async (
  chainId: number,
  addresses: any
): Promise<void> => {
  const prevAddresses = await getAddresses(chainId);
  const newAddresses = {
    ...prevAddresses,
    ...addresses,
  };

  return new Promise((resolve, _reject) => {
    fs.writeFile(
      getFilePath(getNetworkName(chainId)),
      JSON.stringify(newAddresses),
      () => {
        resolve();
      }
    );
  });
};

export const getAddresses = async (chainId: number): Promise<any> => {
  const networkName = getNetworkName(chainId);
  return new Promise((resolve, reject) => {
    fs.readFile(getFilePath(networkName), (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(JSON.parse(data.toString()));
      }
    });
  });
};
