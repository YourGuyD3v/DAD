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
    error Marketplace__NotEnoughEthSent();
    struct ListedItems {
        string name;
        uint256 price;
        string description;
        bytes32 productSnap;
    }
    /* State Variables */
    // Local Variables

    uint256 private immutable i_listingPrice;
    ListedItems[] private s_listItems;

    // Events
    event ItemListed(string productName, string description, uint256 price);

    constructor(uint256 listingPrice) {
        i_listingPrice = listingPrice;
    }

    /////////////////
    /// Functions ///
    /////////////////

    function listItem(
        string memory _productName,
        string memory _description,
        uint256 _price,
        bytes32 _productSnap
    ) external payable {
        if (msg.value < i_listingPrice) {
            revert Marketplace__NotEnoughEthSent();
        }
        s_listItems.push(ListedItems(_productName, _price, _description, _productSnap));
    }
}
