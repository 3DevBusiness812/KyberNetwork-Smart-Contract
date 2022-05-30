// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/OracleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol";
import "./SafeMathChainlink.sol";

contract ChainlinkOracleMock is ChainlinkRequestInterface, OracleInterface {
    using SafeMathChainlink for uint256;

    uint256 public constant EXPIRY_TIME = 5 minutes;

    uint256 private constant MINIMUM_CONSUMER_GAS_LIMIT = 400000;
    uint256 private constant ONE_FOR_CONSISTENT_GAS_COST = 1;
    uint256 private constant SELECTOR_LENGTH = 4;
    uint256 private constant EXPECTED_REQUEST_WORDS = 2;
    uint256 private constant MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);

    LinkTokenInterface internal LinkToken;
    mapping(bytes32 => bytes32) private commitments;
    mapping(address => bool) private authorizedNodes;
    uint256 private withdrawableTokens = ONE_FOR_CONSISTENT_GAS_COST;

    event OracleRequest(
        bytes32 indexed specId,
        address requester,
        bytes32 requestId,
        uint256 payment,
        address callbackAddr,
        bytes4 callbackFunctionId,
        uint256 cancelExpiration,
        uint256 dataVersion,
        bytes data
    );

    event CancelOracleRequest(bytes32 indexed requestId);

    constructor(address _link) {
        LinkToken = LinkTokenInterface(_link);
    }

    function onTokenTransfer(
        address _sender,
        uint256 _amount,
        bytes memory _data
    ) public onlyLINK validRequestLength(_data) permittedFunctionsForLINK(_data) {
        assembly {
            // solhint-disable-line no-inline-assembly
            mstore(add(_data, 36), _sender) // ensure correct sender is passed
            mstore(add(_data, 68), _amount) // ensure correct amount is passed
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).delegatecall(_data);
        require(success, "Unable to create request"); // calls oracleRequest
    }

    function oracleRequest(
        address _sender,
        uint256 _payment,
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce,
        uint256 _dataVersion,
        bytes memory _data
    ) external onlyLINK checkCallbackAddress(_callbackAddress) {
        bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
        require(commitments[requestId] == 0, "Must use a unique ID");
        // solhint-disable-next-line not-rely-on-time
        uint256 expiration = (block.timestamp).add(EXPIRY_TIME);

        commitments[requestId] = keccak256(
            abi.encodePacked(_payment, _callbackAddress, _callbackFunctionId, expiration)
        );

        emit OracleRequest(
            _specId,
            _sender,
            requestId,
            _payment,
            _callbackAddress,
            _callbackFunctionId,
            expiration,
            _dataVersion,
            _data
        );

        // Mocked Reply
        bytes32 response;
        fulfillOracleRequest(requestId, _payment, _callbackAddress, _callbackFunctionId, expiration, response);
    }

    function fulfillOracleRequest(
        bytes32 _requestId,
        uint256 _payment,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _expiration,
        bytes32 _data
    ) public onlyAuthorizedNode isValidRequest(_requestId) returns (bool) {
        bytes32 paramsHash = keccak256(abi.encodePacked(_payment, _callbackAddress, _callbackFunctionId, _expiration));
        require(commitments[_requestId] == paramsHash, "Params do not match request ID");
        withdrawableTokens = withdrawableTokens.add(_payment);
        delete commitments[_requestId];
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");
        (bool valid, ) = _callbackAddress.call(abi.encodeWithSelector(_callbackFunctionId, _requestId, _data)); // solhint-disable-line avoid-low-level-calls

        return valid;
    }

    // UNUSED FUNCTIONS

    function getAuthorizationStatus(address _node) external view returns (bool) {
        return authorizedNodes[_node];
    }

    function setFulfillmentPermission(address _node, bool _allowed) external {
        authorizedNodes[_node] = _allowed;
    }

    function withdraw(address _recipient, uint256 _amount) external hasAvailableFunds(_amount) {
        withdrawableTokens = withdrawableTokens.sub(_amount);
        assert(LinkToken.transfer(_recipient, _amount));
    }

    function withdrawable() external view returns (uint256) {
        return withdrawableTokens.sub(ONE_FOR_CONSISTENT_GAS_COST);
    }

    /**
     * @notice Allows requesters to cancel requests sent to this oracle contract. Will transfer the LINK
     * sent for the request back to the requester's address.
     * @dev Given params must hash to a commitment stored on the contract in order for the request to be valid
     * Emits CancelOracleRequest event.
     * @param _requestId The request ID
     * @param _payment The amount of payment given (specified in wei)
     * @param _callbackFunc The requester's specified callback address
     * @param _expiration The time of the expiration for the request
     */
    function cancelOracleRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunc,
        uint256 _expiration
    ) external {
        bytes32 paramsHash = keccak256(abi.encodePacked(_payment, msg.sender, _callbackFunc, _expiration));
        require(paramsHash == commitments[_requestId], "Params do not match request ID");
        // solhint-disable-next-line not-rely-on-time
        require(_expiration <= block.timestamp, "Request is not expired");

        delete commitments[_requestId];
        emit CancelOracleRequest(_requestId);

        assert(LinkToken.transfer(msg.sender, _payment));
    }

    function isAuthorizedSender(address node) external view returns (bool) {}

    // MODIFIERS

    /**
     * @dev Reverts if amount requested is greater than withdrawable balance
     * @param _amount The given amount to compare to `withdrawableTokens`
     */
    modifier hasAvailableFunds(uint256 _amount) {
        require(
            withdrawableTokens >= _amount.add(ONE_FOR_CONSISTENT_GAS_COST),
            "Amount requested is greater than withdrawable balance"
        );
        _;
    }

    /**
     * @dev Reverts if request ID does not exist
     * @param _requestId The given request ID to check in stored `commitments`
     */
    modifier isValidRequest(bytes32 _requestId) {
        require(commitments[_requestId] != 0, "Must have a valid requestId");
        _;
    }

    /**
     * @dev Reverts if `msg.sender` is not authorized to fulfill requests
     */
    modifier onlyAuthorizedNode() {
        /// require(authorizedNodes[msg.sender], "Not an authorized node to fulfill requests");
        _;
    }

    /**
     * @dev Reverts if not sent from the LINK token
     */
    modifier onlyLINK() {
        require(msg.sender == address(LinkToken), "Must use LINK token");
        _;
    }

    /**
     * @dev Reverts if the given data does not begin with the `oracleRequest` function selector
     * @param _data The data payload of the request
     */
    modifier permittedFunctionsForLINK(bytes memory _data) {
        bytes4 funcSelector;
        assembly {
            // solhint-disable-line no-inline-assembly
            funcSelector := mload(add(_data, 32))
        }
        require(funcSelector == this.oracleRequest.selector, "Must use whitelisted functions");
        _;
    }

    /**
     * @dev Reverts if the callback address is the LINK token
     * @param _to The callback address
     */
    modifier checkCallbackAddress(address _to) {
        require(_to != address(LinkToken), "Cannot callback to LINK");
        _;
    }

    /**
     * @dev Reverts if the given payload is less than needed to create a request
     * @param _data The request payload
     */
    modifier validRequestLength(bytes memory _data) {
        require(_data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
        _;
    }
}
