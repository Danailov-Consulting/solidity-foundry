// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 myFavoriteNumber; // 0
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] listOfPeople; // []

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        myFavoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        Person memory person = Person({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        listOfPeople.push(person);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
