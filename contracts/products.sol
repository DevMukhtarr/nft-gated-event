// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ProductContract {

    address public owner;
    uint256 private _productIdCounter;

    struct Product {
        string name;
        string description;
        uint256 basePrice;
        uint256 subsidyAmount;
        uint256 quantity;
        address manufacturer;
        bool isSubsidized;
    }

    struct Reseller {
        uint256 maxMarkupPercentage;
        bool isApproved;
    }

    struct ResellerProduct {
        uint256 productId;
        uint256 quantity;
        uint256 price;
    }

    mapping(uint256 => Product) private _products;
    mapping(address => Reseller) private _resellers;
    mapping(address => mapping(uint256 => ResellerProduct)) private _resellerProducts;

    event ProductRegistered(uint256 indexed productId, string name, uint256 basePrice, uint256 quantity);
    event ProductSubsidized(uint256 indexed productId, uint256 subsidyAmount);
    event ResellerApproved(address indexed reseller, uint256 maxMarkupPercentage);
    event ResellerProductAdded(address indexed reseller, uint256 indexed productId, uint256 quantity, uint256 price);
    event ProductSoldToReseller(uint256 indexed productId, address indexed reseller, uint256 quantity);
    event ProductSoldToCustomer(uint256 indexed productId, address indexed customer, uint256 quantity, uint256 price);

    constructor() {
        owner = msg.sender;
        _productIdCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }

    function registerProduct(
        string memory name,
        string memory description,
        uint256 basePrice,
        uint256 quantity
    ) external onlyOwner {
        require(bytes(name).length > 0, "Product name cannot be empty");
        require(basePrice > 0, "Base price must be greater than zero");
        require(quantity > 0, "Quantity must be greater than zero");

        uint256 productId = _productIdCounter++;
        _products[productId] = Product({
            name: name,
            description: description,
            basePrice: basePrice,
            subsidyAmount: 0,
            quantity: quantity,
            manufacturer: msg.sender,
            isSubsidized: false
        });

        emit ProductRegistered(productId, name, basePrice, quantity);
    }

    function subsidizeProduct(uint256 productId, uint256 subsidyAmount) external onlyOwner {
        Product storage product = _products[productId];
        require(product.manufacturer != address(0), "Product does not exist");
        require(!product.isSubsidized, "Product is already subsidized");
        require(subsidyAmount > 0 && subsidyAmount < product.basePrice, "Invalid subsidy amount");

        product.subsidyAmount = subsidyAmount;
        product.isSubsidized = true;

        emit ProductSubsidized(productId, subsidyAmount);
    }

    function approveReseller(address resellerAddress, uint256 maxMarkupPercentage) external onlyOwner {
        require(resellerAddress != address(0), "Invalid reseller address");
        require(maxMarkupPercentage > 0 && maxMarkupPercentage <= 100, "Invalid markup percentage");

        _resellers[resellerAddress] = Reseller({
            maxMarkupPercentage: maxMarkupPercentage,
            isApproved: true
        });

        emit ResellerApproved(resellerAddress, maxMarkupPercentage);
    }

    function buyFromManufacturer(uint256 productId, uint256 quantity) external payable {
        require(_resellers[msg.sender].isApproved, "Not an approved reseller");
        Product storage product = _products[productId];
        require(product.manufacturer != address(0), "Product does not exist");
        require(product.quantity >= quantity, "Insufficient product quantity");

        uint256 totalPrice = (product.basePrice - product.subsidyAmount) * quantity;
        require(msg.value >= totalPrice, "Insufficient payment");

        product.quantity -= quantity;
        ResellerProduct storage resellerProduct = _resellerProducts[msg.sender][productId];
        resellerProduct.productId = productId;
        resellerProduct.quantity += quantity;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit ProductSoldToReseller(productId, msg.sender, quantity);
    }

    function setResellerProductPrice(uint256 productId, uint256 price) external {
        require(_resellers[msg.sender].isApproved, "Not an approved reseller");
        Product storage product = _products[productId];
        require(product.manufacturer != address(0), "Product does not exist");

        uint256 maxAllowedPrice = product.basePrice + (product.basePrice * _resellers[msg.sender].maxMarkupPercentage / 100);
        require(price <= maxAllowedPrice, "Price exceeds maximum allowed markup");

        ResellerProduct storage resellerProduct = _resellerProducts[msg.sender][productId];
        require(resellerProduct.quantity > 0, "Reseller does not have this product");

        resellerProduct.price = price;

        emit ResellerProductAdded(msg.sender, productId, resellerProduct.quantity, price);
    }

    function buyFromReseller(address reseller, uint256 productId, uint256 quantity) external payable {
        ResellerProduct storage resellerProduct = _resellerProducts[reseller][productId];
        require(resellerProduct.quantity >= quantity, "Insufficient reseller quantity");

        uint256 totalPrice = resellerProduct.price * quantity;
        require(msg.value >= totalPrice, "Insufficient payment");

        resellerProduct.quantity -= quantity;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        payable(reseller).transfer(totalPrice);

        emit ProductSoldToCustomer(productId, msg.sender, quantity, resellerProduct.price);
    }

    function getProduct(uint256 productId) external view returns (Product memory) {
        return _products[productId];
    }

    function getResellerProduct(address reseller, uint256 productId) external view returns (ResellerProduct memory) {
        return _resellerProducts[reseller][productId];
    }

    function getReseller(address resellerAddress) external view returns (Reseller memory) {
        return _resellers[resellerAddress];
    }
}