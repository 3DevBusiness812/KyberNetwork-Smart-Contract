# IKeyring

## Methods

### create

```solidity
function create() external nonpayable
```

### forceExpiration

```solidity
function forceExpiration(address user) external nonpayable
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |

### forceRemove

```solidity
function forceRemove(address user) external nonpayable
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |

### isValid

```solidity
function isValid(address user) external view returns (bool)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |

#### Returns

| Name | Type | Description |
| ---- | ---- | ----------- |
| \_0  | bool | undefined   |

### refresh

```solidity
function refresh(address user) external nonpayable
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |

### remove

```solidity
function remove() external nonpayable
```

### withdrawLink

```solidity
function withdrawLink() external nonpayable
```

## Events

### IdentityTokenAssigned

```solidity
event IdentityTokenAssigned(address indexed user)
```

#### Parameters

| Name           | Type    | Description |
| -------------- | ------- | ----------- |
| user `indexed` | address | undefined   |

### IdentityTokenError

```solidity
event IdentityTokenError(address indexed user)
```

#### Parameters

| Name           | Type    | Description |
| -------------- | ------- | ----------- |
| user `indexed` | address | undefined   |

### IdentityTokenRefreshed

```solidity
event IdentityTokenRefreshed(address indexed user)
```

#### Parameters

| Name           | Type    | Description |
| -------------- | ------- | ----------- |
| user `indexed` | address | undefined   |

### IdentityTokenRemoved

```solidity
event IdentityTokenRemoved(address indexed user)
```

#### Parameters

| Name           | Type    | Description |
| -------------- | ------- | ----------- |
| user `indexed` | address | undefined   |

## Errors

### Keyring\_\_Expired

```solidity
error Keyring__Expired(address user)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |

### Keyring\_\_Invalid

```solidity
error Keyring__Invalid(address user)
```

#### Parameters

| Name | Type    | Description |
| ---- | ------- | ----------- |
| user | address | undefined   |
