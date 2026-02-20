// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CompanyRegistry {

    // 🔹 Admin address
    address public admin;

    // 🔹 Company structure
    struct Company {
        bool isRegistered;
        bool isVerified;
    }

    // 🔹 Mapping of company address to Company data
    mapping(address => Company) public companies;

    // 🔹 Events (for audit trail)
    event CompanyRegistered(address indexed company);
    event CompanyVerified(address indexed company);

    // 🔹 Constructor: sets deployer as admin
    constructor() {
        admin = msg.sender;
    }

    // 🔹 Modifier: only admin can call
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    // 🔹 Modifier: only verified companies
    modifier onlyVerifiedCompany() {
        require(
            companies[msg.sender].isVerified,
            "Company not verified"
        );
        _;
    }

    // 🔹 Register a company (called by company itself)
    function registerCompany() external {
        require(
            !companies[msg.sender].isRegistered,
            "Company already registered"
        );

        companies[msg.sender] = Company({
            isRegistered: true,
            isVerified: false
        });

        emit CompanyRegistered(msg.sender);
    }

    // 🔹 Verify a company (admin only)
    function verifyCompany(address _company) external onlyAdmin {
        require(
            companies[_company].isRegistered,
            "Company not registered"
        );
        require(
            !companies[_company].isVerified,
            "Company already verified"
        );

        companies[_company].isVerified = true;

        emit CompanyVerified(_company);
    }

    // 🔹 Helper function (used by other contracts)
    function isCompanyVerified(address _company) external view returns (bool) {
        return companies[_company].isVerified;
    }
}
