pragma solidity ^0.4.23;
import "node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract MsiBlockCerts{

    using SafeMath for uint256;

    struct Issuer {
        address issuingAccount;
        string issuerName;
        bool active;
    }

    struct CertificateClass {
        string certificateName;
        string certificateDescription;
        address issuingInstitutionAddress;
        bool valid;
    }

    struct IssuedCertificate {
        //address transactionAddress;
        address issuingAddress;
        address recipientAddress;
        bytes digitalSignature;
        bool valid;
    }

    //Issuer[] public registeredIssuers;
    mapping(uint => Issuer) private registeredIssuers;
    uint public totalIssuers;

    //CertificateClass[] public registeredCertificates;
    mapping(uint => CertificateClass) private registeredCertificates;
    uint public totalCertificates;

    //IssuedCertificate[] public issuedCertificates;
    mapping(uint => IssuedCertificate) private issuedCertificates;
    uint public totalIssuedCertificates;

    mapping(address => uint) private accounts;

    event LogAddedIssuer(address issuingAccount, uint issuerId, string issuerName);
    event LogAddedCertificate(address issuingAccount, uint certificateId, string certificateName, string certificateDescription);
    event LogIssuedCertification(address issuingAccount, address recipientAddress, bytes digitalSignature, uint certificationId);    

    modifier onlyCertificateIssuer(uint certificateId){
        require(isCertificateIssuer(msg.sender, certificateId), "The user isn't an issuer");
        _;
    }

    modifier onlyActiveIssuer(uint issuerId){
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

    function isCertificateIssuer(address account, uint certificateId)
      view
      internal
      returns(bool)
    {
        return registeredCertificates[certificateId].issuingInstitutionAddress == account;
    }

    function addIssuer(string issuerName)
      public
      //returns(uint)  
    {
        address issuingAccount = msg.sender;
        Issuer memory newIssuer = Issuer(issuingAccount, issuerName, true);

        totalIssuers = totalIssuers.add(1);
        registeredIssuers[totalIssuers] = newIssuer;
        accounts[issuingAccount] = totalIssuers;

        //log        
        emit LogAddedIssuer(issuingAccount, totalIssuers, issuerName);
        
        //return registeredIssuers.length - 1;
    }

    function addCertificate(string name, string description, address issuingAccount)
      public
      //returns (uint)
    {      
        CertificateClass memory newCertificate = CertificateClass(name, description, issuingAccount, true);

        totalCertificates = totalCertificates.add(1);
        registeredCertificates[totalCertificates] = newCertificate;

        //log
        emit LogAddedCertificate(issuingAccount, totalCertificates, name, description);
        //return registeredCertificates.length - 1;
    }

    function issueCertificate(address issuingAddress, address recipientAddress, bytes digitalSignature)
      public
      //returns (uint)
    {
        IssuedCertificate memory newCertification = IssuedCertificate(issuingAddress, recipientAddress, digitalSignature, true);

        totalIssuedCertificates = totalIssuedCertificates.add(1);
        issuedCertificates[totalIssuedCertificates] = newCertification;

        //log    
        emit LogIssuedCertification(issuingAddress, recipientAddress, digitalSignature, totalIssuedCertificates);

        //return issuedCertificates.length - 1;
    }

}
