import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ProductContractModule = buildModule("ProductContract", (m) => {

  const product_contract = m.contract("ProductContract");

  return { product_contract };
});

export default ProductContractModule;