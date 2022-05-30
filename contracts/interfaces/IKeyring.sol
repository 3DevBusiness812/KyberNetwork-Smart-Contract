// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

interface IKeyring {
    function create() external;

    function refresh(address user) external;

    function remove() external;

    function isValid(address user) external view returns (bool);

    function forceRemove(address user) external;

    function forceExpiration(address user) external;

    function withdrawLink() external;

    event IdentityTokenAssigned(address indexed user);
    event IdentityTokenRefreshed(address indexed user);
    event IdentityTokenRemoved(address indexed user);
    event IdentityTokenError(address indexed user);

    error Keyring__Invalid(address user);
    error Keyring__Expired(address user);
}
