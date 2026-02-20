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

    // 🔹 creditId => Credit
    mapping(uint256 => Credit) public credits;

    // ================= EVENTS =================

    event CreditIssued(uint256 indexed creditId, address indexed company);
    event CreditTransferred(
        uint256 indexed creditId,
        address indexed from,
        address indexed to
    );
    event CreditRetired(uint256 indexed creditId, address indexed owner);

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

    // 🔹 Issue ONE credit
    function issueCredit(address company)
        external
        onlyAdmin
        onlyVerifiedCompany(company)
    {
        _mintCredit(company);
    }

    // 🔹 Issue MULTIPLE credits (batch minting)
    function issueCredits(address company, uint256 amount)
        external
        onlyAdmin
        onlyVerifiedCompany(company)
    {
        require(amount > 0, "Amount must be > 0");
        require(amount <= 100, "Too many credits at once");

        for (uint256 i = 0; i < amount; i++) {
            _mintCredit(company);
        }
    }

    // 🔹 Internal mint logic
    function _mintCredit(address company) internal {
        creditIdCounter++;

        credits[creditIdCounter] = Credit({
            id: creditIdCounter,
            owner: company,
            status: CreditStatus.Issued
        });

        emit CreditIssued(creditIdCounter, company);
    }

    // 🔹 Transfer credit
    function transferCredit(uint256 creditId, address to)
        external
        onlyVerifiedCompany(to)
    {
        Credit storage credit = credits[creditId];

        require(credit.owner == msg.sender, "Not credit owner");
        require(credit.status != CreditStatus.Retired, "Credit retired");

        credit.owner = to;
        credit.status = CreditStatus.Transferred;

        emit CreditTransferred(creditId, msg.sender, to);
    }

    // 🔹 Retire credit (final state)
    function retireCredit(uint256 creditId) external {
        Credit storage credit = credits[creditId];

        require(credit.owner == msg.sender, "Not credit owner");
        require(credit.status != CreditStatus.Retired, "Already retired");

        credit.status = CreditStatus.Retired;

        emit CreditRetired(creditId, msg.sender);
    }

    // 🔹 View helper
    function getCredit(uint256 creditId)
        external
        view
        returns (uint256, address, CreditStatus)
    {
        Credit memory credit = credits[creditId];
        return (credit.id, credit.owner, credit.status);
    }
}
