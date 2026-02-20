// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 🔹 Interface to talk to CompanyRegistry
interface ICompanyRegistry {
    function isCompanyVerified(address company) external view returns (bool);
}

contract CarbonCredit {

    // 🔹 Admin (deployer)
    address public admin;

    // 🔹 External registry contract
    ICompanyRegistry public companyRegistry;

    // 🔹 Credit lifecycle
    enum CreditStatus { Issued, Transferred, Retired }

    // 🔹 Carbon Credit structure
    struct Credit {
        uint256 id;
        address owner;
        CreditStatus status;
    }

    // 🔹 Global credit counter
    uint256 public creditIdCounter;

    // 🔹 Mapping: creditId → Credit
    mapping(uint256 => Credit) public credits;

    // ================= EVENTS =================

    event CreditIssued(uint256 indexed creditId, address indexed company);
    event CreditTransferred(
        uint256 indexed creditId,
        address indexed from,
        address indexed to
    );

    // ================= MODIFIERS =================

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    modifier onlyVerifiedCompany(address company) {
        require(
            companyRegistry.isCompanyVerified(company),
            "Company not verified"
        );
        _;
    }

    // ================= CONSTRUCTOR =================

    constructor(address _companyRegistryAddress) {
        admin = msg.sender;
        companyRegistry = ICompanyRegistry(_companyRegistryAddress);
    }

    // ================= CORE LOGIC =================

    // 🔹 Admin issues a new carbon credit to a verified company
    function issueCredit(address company)
        external
        onlyAdmin
        onlyVerifiedCompany(company)
    {
        creditIdCounter++;

        credits[creditIdCounter] = Credit({
            id: creditIdCounter,
            owner: company,
            status: CreditStatus.Issued
        });

        emit CreditIssued(creditIdCounter, company);
    }

    // 🔹 Transfer credit to another verified company
    function transferCredit(uint256 creditId, address to)
        external
        onlyVerifiedCompany(to)
    {
        Credit storage credit = credits[creditId];

        require(credit.owner == msg.sender, "Not credit owner");
        require(
            credit.status != CreditStatus.Retired,
            "Credit already retired"
        );

        credit.owner = to;
        credit.status = CreditStatus.Transferred;

        emit CreditTransferred(creditId, msg.sender, to);
    }

    // 🔹 View helper (frontend/backend friendly)
    function getCredit(uint256 creditId)
        external
        view
        returns (uint256, address, CreditStatus)
    {
        Credit memory credit = credits[creditId];
        return (credit.id, credit.owner, credit.status);
    }
}
