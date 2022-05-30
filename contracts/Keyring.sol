// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./libraries/String.sol";
import "./interfaces/IKeyring.sol";
import "./Base.sol";

contract Keyring is Base, ChainlinkClient, IKeyring {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;
    using String for address;

    Counters.Counter private _tokenIds;
    mapping(bytes32 => address) private mintingRequest;
    mapping(bytes32 => address) private refreshRequest;
    mapping(bytes32 => address) private deletionRequest;
    mapping(address => uint256) private timestamp;

    string public constant BASE_URL = "https://oracle.keyring.network";
    string public constant CREATE_ENDPOINT = "/create?walletAddress=";
    string public constant VALIDATE_ENDPOINT = "/validate?walletAddress=";
    string public constant DELETE_ENDPOINT = "/delete?walletAddress=";
    string public constant METADATA_ENDPOINT = "/metadata?walletAddress=";

    IERC20 public immutable linkToken;
    address public immutable oracle;
    bytes32 public immutable jobId;
    uint256 public immutable fee;

    uint256 public immutable validity;

    constructor(
        address _link,
        address _oracle,
        bytes32 _jobId,
        uint256 _linkFee,
        uint256 _validity
    ) Base("Keyring Identity Token", "KIT") {
        setChainlinkToken(_link);
        linkToken = IERC20(_link);
        oracle = _oracle;
        jobId = "90359b4b34c349fba9a9a424b054786c"; /* @todo replace with _jobId */
        fee = _linkFee;
        validity = 5 minutes;
    }

    function create() external override {
        _mint(msg.sender);

        /*
        Chainlink.Request memory req = buildChainlinkRequest("0a546a9302454524a4dec579c50b0579", address(this), this.createCallback.selector);
        req.add("get", _getURL(BASE_URL, (msg.sender).addressToString(), CREATE_ENDPOINT));
        req.add("path", "result");
        bytes32 requestId = sendChainlinkRequestTo(0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40, req, fee);
        mintingRequest[requestId] = msg.sender;
        */
    }

    /*
    function createCallback(bytes32 requestId, bytes32 data) public recordChainlinkFulfillment(requestId) {
        address user = mintingRequest[requestId];
        delete mintingRequest[requestId];

        if(data.length == 0) 
        
        _mint(user);
    }
    */

    function refresh(address person) external override {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.refreshCallback.selector);
        req.add("get", _getURL(BASE_URL, person.addressToString(), VALIDATE_ENDPOINT));
        req.add("path", "result");
        bytes32 requestId = sendChainlinkRequestTo(oracle, req, fee);
        refreshRequest[requestId] = person;
    }

    function refreshCallback(bytes32 requestId, bool valid) public recordChainlinkFulfillment(requestId) {
        address user = refreshRequest[requestId];
        delete refreshRequest[requestId];

        if (valid) {
            timestamp[user] = block.timestamp + validity;
            emit IdentityTokenRefreshed(user);
        } else {
            emit IdentityTokenError(user);
        }
    }

    function remove() external override {
        _burnRequest(msg.sender);
    }

    function forceRemove(address user) external override /* onlyOwner */
    {
        //_burnRequest(user);

        uint256 balance = balanceOf(user);
        if (balance > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(user, 0);
            _burn(tokenId);
            timestamp[user] = 0;

            emit IdentityTokenRemoved(user);
        }
    }

    function forceExpiration(address user) external override /* onlyOwner */
    {
        uint256 balance = balanceOf(user);
        if (balance > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(user, 0);
            timestamp[user] = 0;
        }
    }

    function burnCallback(bytes32 requestId, bool valid) public recordChainlinkFulfillment(requestId) {
        address user = deletionRequest[requestId];
        delete deletionRequest[requestId];

        uint256 balance = balanceOf(user);
        if (balance > 0 && valid) {
            uint256 tokenId = tokenOfOwnerByIndex(user, 0);
            _burn(tokenId);
            timestamp[user] = 0;

            emit IdentityTokenRemoved(user);
        } else {
            emit IdentityTokenError(user);
        }
    }

    function isValid(address user) external view override returns (bool) {
        uint256 balance = balanceOf(user);
        if (balance == 0) revert Keyring__Invalid(user);

        if (timestamp[user] < block.timestamp + validity) revert Keyring__Expired(user);

        return true;
    }

    function withdrawLink() external override onlyOwner {
        uint256 amount = linkToken.balanceOf(address(this));
        linkToken.transfer(msg.sender, amount);
    }

    function _mint(address user) internal {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(user, id);
        _setTokenURI(id, _getURL(BASE_URL, user.addressToString(), METADATA_ENDPOINT));

        emit IdentityTokenAssigned(user);
    }

    function _burnRequest(address user) internal {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.burnCallback.selector);
        req.add("get", _getURL(BASE_URL, user.addressToString(), DELETE_ENDPOINT));
        req.add("path", "result");
        sendChainlinkRequestTo(oracle, req, fee);
    }

    function _getURL(
        string memory baseUrl,
        string memory user,
        string memory endpoint
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(baseUrl, endpoint, user));
    }
}
