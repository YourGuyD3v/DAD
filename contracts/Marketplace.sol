/*
it's a marketplace that can store items that are on sell.
1. seller can list the item with description, price
2. buyer can bi=uy the item
3. item can be trackable
4. listing can be update on purchasing
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Marketplace {

    struct ListedItems {
        string name;
        uint256 price;
        string description;
    }
    /* State Variables */
    // Local Variables

    // Mapping
    mapping (string => mapping (bytes => ListedItems)) internal i_listedItem;

    // Events
    event ItemListed(string productName, string description, uint256 price);

    constructor() {}

     /////////////////
    /// Functions ///
   /////////////////

   function listItem(string memory productName, string memory description, uint256 price) public {}

}