import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const EventNftModule = buildModule("EventNftModule", (m) => {

  const nft = m.contract("EventNft");

  return { nft };
});

export default EventNftModule;
