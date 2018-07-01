pragma solidity ^0.4.23;
import "node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract MsiBlockCerts{

    // Math functions with verified safety implementations
    using SafeMath for uint256;

    /*------ Data Models ------*/

    // Represents a certification issuer
    struct Issuer {
        address issuingAccount;
        string issuerName;
        bool active;
    }

    // Represents a certificate class
    struct CertificateClass {
        string certificateName;
        string certificateDescription;
        address issuingInstitutionAddress;
        bool valid;
    }

    // Represents an issued certificate
    struct IssuedCertificate {
        address issuingAddress;
        address recipientAddress;
        uint certificateId;
        bytes digitalSignature;
        bool valid;
    }

    /*------ Data Storage ------*/

    // Stores an indexed list of registered issuers
    mapping(uint => Issuer) private registeredIssuers;
    uint public totalIssuers;

    // Stores an indexed list of certificate classes
    mapping(uint => CertificateClass) private registeredCertificates;
    uint public totalCertificates;

    // Stores an indexed list of registered isued certifications
    mapping(uint => IssuedCertificate) private issuedCertificates;
    uint public totalIssuedCertificates;

    // Stores an indexed list of the registered issuer's addresses, for easier access
    // This avoids having to recover issuing address information from the Issuer struct
    mapping(address => uint) private accounts;

    /*------ Events ------*/

    // Emmits events in order to log the operations performed in the system
    event LogAddedIssuer(address issuingAccount, uint issuerId, string issuerName);
    event LogAddedCertificate(address issuingAccount, uint certificateId, string certificateName, string certificateDescription);
    event LogIssuedCertification(address issuingAccount, address recipientAddress, bytes digitalSignature, uint certificationId);    

    /*------ Modifiers ------*/
    modifier onlyCertificateIssuer(uint certificateId){
        require(isCertificateIssuer(msg.sender, certificateId), "The user isn't an issuer");
        _;
    }

    modifier onlyActiveIssuer(address issuerAccount){
        uint issuerId = accounts[issuerAccount];

        require(totalIssuers >= issuerId && issuerId > uint(0), "Invalid issuer");
        require(registeredIssuers[issuerId].active, "Inactive issuer");
        _;
    }

    modifier onlyValidCertificate(uint certificateId){
        require(totalCertificates >= certificateId && certificateId > uint(0), "Invalid certificate");
        require(registeredCertificates[certificateId].valid, "Invalid certificate");
        _;
    }

    modifier onlyValidIssuedCertification(uint certificationId){
        require(totalIssuedCertificates >= certificationId && certificationId > uint(0), "Invalid certification");
        require(issuedCertificates[certificationId].valid, "Invalid certification");
        _;
    }

    /*------ Validation Functions ------*/
    function isCertificateIssuer(address account, uint certificateId)
      view
      internal
      returns(bool)
    {
        return registeredCertificates[certificateId].issuingInstitutionAddress == account;
    }

    /*------ Main Functions ------*/
    function addIssuer(string issuerName)
      public 
    {
        // Sets the issuer address as the contract caller's address
        address issuingAccount = msg.sender;

        // Creates new Issuer object
        Issuer memory newIssuer = Issuer(issuingAccount, issuerName, true);

        // Increments total issuers tracker
        totalIssuers = totalIssuers.add(1);

        // Stores new issuer object on the last position of the mapping structure
        registeredIssuers[totalIssuers] = newIssuer;

        // Stores new valid emitting address on the accounts mapping structure
        accounts[issuingAccount] = totalIssuers;

        // Logs addition of this issuer      
        emit LogAddedIssuer(issuingAccount, totalIssuers, issuerName);
    }

    function addCertificate(string name, string description)
      onlyActiveIssuer(msg.sender)
      public
    {     
        // Sets the issuer institution's address as the contract caller's address
        address ownerInstitutionAddress = msg.sender;

        // Creates new certification object
        CertificateClass memory newCertificate = CertificateClass(name, description, ownerInstitutionAddress, true);

        // Icrements total certificates tracker
        totalCertificates = totalCertificates.add(1);

        // Stores the new certificate object on the last position of the mapping structure
        registeredCertificates[totalCertificates] = newCertificate;

        // Log addition of new certificate
        emit LogAddedCertificate(ownerInstitutionAddress, totalCertificates, name, description);
    }

    function issueCertificate(address recipientAddress, uint certificateId, bytes digitalSignature)
      onlyValidCertificate(certificateId)
      onlyCertificateIssuer(certificateId)
      public
      returns (uint issuedCertificateId)
    {
        // Sets issuing address as the contract caller's address
        address issuingAddress = msg.sender;

        // Creates new issued certificate object
        IssuedCertificate memory newCertification = IssuedCertificate(issuingAddress, recipientAddress, certificateId, digitalSignature, true);

        // Increments issued certifications tracker
        totalIssuedCertificates = totalIssuedCertificates.add(1);

        // Stores new object on the last position of the mapping structure
        issuedCertificates[totalIssuedCertificates] = newCertification;

        // This ID value is returned to the front-end to be stored on the JSON certificate output
        issuedCertificateId = totalIssuedCertificates;

        // Log certificate issuing
        emit LogIssuedCertification(issuingAddress, recipientAddress, digitalSignature, totalIssuedCertificates);
    }

    // Verification function draft - not working yet
    function verifyCertificate(uint issuingId, bytes calculatedHash)
      onlyValidIssuedCertification(issuingId)
      public
      view
      returns (bool validCertificate)
    {
        // Recovers the issued certificate object from the mapping structure
        IssuedCertificate memory certificate = issuedCertificates[issuingId];

        // Recovers digital signature from the issued certificate object
        bytes memory digSignature = certificate.digitalSignature;

        // @TODO: It is still necessary to implement the digital signature
        // verification.
        if(keccak256(digSignature) == keccak256(calculatedHash))
            return true;
        else
            return false;
    }

}
