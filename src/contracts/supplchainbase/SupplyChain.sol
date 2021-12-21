pragma solidity ^0.6.0;


import '../coffeeaccesscontrol/FarmerRole.sol';
import '../coffeeaccesscontrol/DistributorRole.sol';
import '../coffeeaccesscontrol/RetailerRole.sol';
import '../coffeeaccesscontrol/ConsumerRole.sol';
import '../coffeecore/Ownable.sol';


// Define a contract 'Supplychain'
contract SupplyChain is Ownable, FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;

  // Define enum 'State' with the following values:
  enum State
  {
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
    }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID potentially a combination of upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint upc);
  event Processed(uint upc);
  event Packed(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);


  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address, "This account is not the owner of this item");
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "The amount sent is not sufficient for the price");
    _;
  }

  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValueForDistributor(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].distributorID.transfer(amountToReturn);
  }

    // Define a modifier that checks the price and refunds the remaining balance
    // to the Consumer
  modifier checkValueForConsumer(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].consumerID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested, "The Item is not in Harvested state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed, "The Item is not in Processed state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed, "The Item is not in Packed state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale, "The Item is not in ForSale state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold, "The Item is not in Sold state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped, "The Item is not in Shipped state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received, "The Item is not in Received state!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased, "The Item is not in Purchased state!");
    _;
  }

  // and set 'sku' to 1
  // and set 'upc' to 1
  // Using Ownable to define the ownwerm
  constructor() public payable {
    sku = 1;
    upc = 1;
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(
  uint _upc,
  address payable _originFarmerID,
  string memory _originFarmName,
  string memory _originFarmInformation,
  string memory _originFarmLatitude,
  string memory _originFarmLongitude,
  string memory productNotes) public
  //Only Farmer
  onlyFarmer
  {
    // Add the new item as part of Harvest
    Item memory newItem;
    newItem.upc = _upc;
    newItem.ownerID = _originFarmerID;
    newItem.originFarmerID = _originFarmerID;
    newItem.originFarmName = _originFarmName;
    newItem.originFarmInformation = _originFarmInformation;
    newItem.originFarmLatitude = _originFarmLatitude;
    newItem.originFarmLongitude = _originFarmLongitude;
    newItem.productNotes = productNotes;
    newItem.sku = sku;
    newItem.productID = _upc + sku;
    // Increment sku
    sku = sku + 1;
    // Setting state
    newItem.itemState = State.Harvested;
    // Adding new Item to map
    items[_upc] = newItem;
    // Emit the appropriate event
    emit Harvested(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) public
  //Only Farmer
  onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
  harvested(_upc)
  // Call modifier to verify caller of this function
  verifyCaller(items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Processed;
    // Emit the appropriate event
    emit Processed(_upc);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public
  //Only Farmer
  onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
  processed(_upc)
  // Call modifier to verify caller of this function
  verifyCaller(items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Packed;
    // Emit the appropriate event
    emit Packed(_upc);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public
  //Only Farmer
  onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
  packed(_upc)
  // Call modifier to verify caller of this function
  verifyCaller(items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.ForSale;
    existingItem.productPrice = _price;
    // Emit the appropriate event
    emit ForSale(_upc);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) public payable
    // Only Distributor
    onlyDistributor
    // Call modifier to check if upc has passed previous supply chain stage
    forSale(_upc)
    // Call modifer to check if buyer has paid enough
    paidEnough(items[_upc].productPrice)
    // Call modifer to send any excess ether back to buyer
    checkValueForDistributor(_upc)
    {
    // Update the appropriate fields - ownerID, distributorID, itemState
    Item storage existingItem = items[_upc];
    existingItem.ownerID = msg.sender;
    existingItem.itemState = State.Sold;
    existingItem.distributorID = msg.sender;
    // Transfer money to farmer
    uint productPrice = items[_upc].productPrice;
    items[_upc].originFarmerID.transfer(productPrice);
    // emit the appropriate event
    emit Sold(_upc);
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) public
    // Only Distributor
    onlyDistributor
    // Call modifier to check if upc has passed previous supply chain stage
    sold(_upc)
    // Call modifier to verify caller of this function
    verifyCaller(items[_upc].distributorID)
    {
    // Update the appropriate fields
    Item storage existingItem = items[_upc];
    existingItem.itemState = State.Shipped;
    // Emit the appropriate event
    emit Shipped(_upc);
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) public
    // Only Retailer
    onlyRetailer
    // Call modifier to check if upc has passed previous supply chain stage
    shipped(_upc)
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
    Item storage existingItem = items[_upc];
    existingItem.ownerID = msg.sender;
    existingItem.itemState = State.Received;
    existingItem.retailerID = msg.sender;
    // Emit the appropriate event
    emit Received(_upc);
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public payable
    //Only Consumer
    onlyConsumer
    // Call modifier to check if upc has passed previous supply chain stage
    received(_upc)
    // Make sure paid enough
    paidEnough(items[_upc].productPrice)
    // Access Control List enforced by calling Smart Contract / DApp
    checkValueForConsumer(_upc)
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
      Item storage existingItem = items[_upc];
      existingItem.ownerID = msg.sender;
      existingItem.itemState = State.Purchased;
      existingItem.consumerID = msg.sender;
    // Emit the appropriate event
      emit Purchased(_upc);
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string  memory originFarmName,
  string  memory originFarmInformation,
  string  memory originFarmLatitude,
  string  memory originFarmLongitude
  ) 
  {
  // Assign values to the 8 parameters
  Item memory existingItem = items[_upc];

  itemSKU = existingItem.sku;
  itemUPC = existingItem.upc;
  ownerID = existingItem.ownerID;
  originFarmerID = existingItem.originFarmerID;
  originFarmName = existingItem.originFarmName;
  originFarmInformation = existingItem.originFarmInformation;
  originFarmLatitude = existingItem.originFarmLatitude;
  originFarmLongitude = existingItem.originFarmLongitude;

  return 
  (
  itemSKU,
  itemUPC,
  ownerID,
  originFarmerID,
  originFarmName,
  originFarmInformation,
  originFarmLatitude,
  originFarmLongitude
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string  memory productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  ) 
  {
    // Assign values to the 9 parameters
  Item memory existingItem = items[_upc];
  itemSKU = existingItem.sku;
  itemUPC = existingItem.upc;
  productID = existingItem.productID;
  productNotes = existingItem.productNotes;
  productPrice = existingItem.productPrice;
  itemState = uint(existingItem.itemState);
  distributorID = existingItem.distributorID;
  retailerID = existingItem.retailerID;
  consumerID = existingItem.consumerID;
  
  return 
  (
  itemSKU,
  itemUPC,
  productID,
  productNotes,
  productPrice,
  itemState,
  distributorID,
  retailerID,
  consumerID
  );
  }

}
