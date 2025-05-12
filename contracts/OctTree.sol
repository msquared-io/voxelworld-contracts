// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OctTree {
    // Constants for bit operations
    uint256 constant DEPTH_BITS = 6;
    uint256 constant COORD_BITS = 32;
    uint256 constant MORTON_BITS = 96;
    uint256 constant MAX_DEPTH = 32;
    uint256 constant DEPTH_MASK = ((1 << DEPTH_BITS) - 1) << MORTON_BITS;

    // Node values are those that have children
    uint8 constant NODE_VALUE = 255;

    // Sub-nodes are beyond the leaf node, they
    // have their values inherited from their parent
    uint8 constant BEYOND_LEAF_VALUE = 0;

    // the tree needs an initial value
    constructor(uint8 value) {
        // set the root node to the value
        _set(encode(0, 0, 0, 0), value);
        require(
            _get(encode(0, 0, 0, 0)) == value,
            "Root node not set correctly"
        );
    }

    function insert(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth,
        uint8 value
    ) public {
        require(value > 0 && value < NODE_VALUE, "Invalid value"); // Values 1-254 are valid
        uint256 target = encode(x, y, z, depth);
        uint8 node = _get(target);

        if (node == NODE_VALUE) {
            clearChildren(target);
        } else if (node == BEYOND_LEAF_VALUE) {
            subdivideToTarget(target);
        }
        _set(target, value);
    }

    function readValue(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth
    ) public view returns (uint8) {
        uint256 target = encode(x, y, z, depth);
        uint8 value = _get(target);

        // If target is beyond a leaf (0), traverse up to find parent leaf value
        if (value == BEYOND_LEAF_VALUE) {
            uint256 current = target;
            while (true) {
                current = getParent(current);
                value = _get(current);
                // Found a leaf node (1-254) or root
                if (value > 0 && value < NODE_VALUE) break;
                require(getDepth(current) > 0, "No leaf parent found");
            }
            return value;
        }

        return value;
    }

    function clearChildren(uint256 encoded) internal {
        if (getDepth(encoded) >= MAX_DEPTH) return;

        uint256[8] memory children = getChildren(encoded);
        for (uint256 i = 0; i < 8; i++) {
            uint8 childValue = _get(children[i]);
            if (childValue == NODE_VALUE) {
                clearChildren(children[i]);
            }
            _set(children[i], BEYOND_LEAF_VALUE);
        }
    }

    function subdivideToTarget(uint256 target) internal {
        uint256 current = target;
        uint8 currentValue;

        // early out if we're already at the root
        if (getDepth(target) == 0) return;

        // Find parent leaf
        while (true) {
            current = getParent(current);
            currentValue = _get(current);
            // if we find a leaf, break
            if (currentValue > 0) break;
        }

        if(currentValue == NODE_VALUE) {
            // coordinate is already a node, so we don't need to subdivide
            return;
        }

        uint256 parentLeaf = current;
        uint8 parentLeafValue = currentValue;

        // Start from target and work up to parent leaf
        current = target;
        while (current != parentLeaf) {
            // Get the parent of current node
            uint256 parent = getParent(current);

            // Set parent as a node
            _set(parent, NODE_VALUE);

            // Get all children of parent
            uint256[8] memory siblings = getChildren(parent);

            // Set all children to parent's original value except for our path
            for (uint256 i = 0; i < 8; i++) {
                if (siblings[i] != current) {
                    _set(siblings[i], parentLeafValue);
                }
            }

            // Move up to parent
            current = parent;
        }
    }

    function _set(uint256 index, uint8 value) internal {
        uint256 baseSlot = 0x21749721894721479821482745325987122189;
        assembly {
            // Calculate slot: baseSlot + (index >> 5) - equivalent to div(index, 32)
            let slot := add(baseSlot, shr(5, index))

            // Calculate offset: (index & 0x1f) * 8 - equivalent to mod(index, 32) * 8
            let shift := shl(3, and(index, 0x1f))

            // Mask for clearing target byte: ~(0xff << shift)
            let mask := shl(shift, 0xff)

            // Load current value, clear byte, set new value
            let current := sload(slot)
            let cleared := and(current, not(mask))
            let newValue := or(cleared, shl(shift, and(value, 0xff)))

            // Store updated value back
            sstore(slot, newValue)
        }
    }

    function _get(uint256 index) internal view returns (uint8 value) {
        uint256 baseSlot = 0x21749721894721479821482745325987122189;
        assembly {
            // Calculate slot: baseSlot + (index >> 5)
            let slot := add(baseSlot, shr(5, index))

            // Calculate shift: (index & 0x1f) * 8
            let shift := shl(3, and(index, 0x1f))

            // Load and extract the byte
            value := and(shr(shift, sload(slot)), 0xff)
        }
    }

        // Encode three uint32 coordinates and depth into single uint102
    // Depth bits are most significant for better spatial locality
    function morty(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth
    ) public pure returns (uint256) {
        require(depth <= MAX_DEPTH, "Depth exceeds maximum");

        // Calculate morton code
        uint256 morton = encodeMorton3D(x, y, z);

        // Combine depth (in most significant bits) and morton code
        return (uint256(depth) << MORTON_BITS) | morton;
    }

    // Encode three uint32 coordinates and depth into single uint102
    // Depth bits are most significant for better spatial locality
    function encode(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth
    ) public pure returns (uint256) {
        require(depth <= MAX_DEPTH, "Depth exceeds maximum");

        // Calculate morton code
        uint256 morton = encodeMorton3D(x, y, z);

        // Combine depth (in most significant bits) and morton code
        return (uint256(depth) << MORTON_BITS) | morton;
    }

    // Helper function to encode Morton 3D (Z-order curve)
    function encodeMorton3D(
        uint32 x,
        uint32 y,
        uint32 z
    ) public pure returns (uint256) {
        return expandBits(x) | (expandBits(y) << 1) | (expandBits(z) << 2);
    }

    // Helper function to expand bits
    // function expandBits(uint32 v) internal pure returns (uint256) {
    //     uint256 x = uint256(v);
    //     x = (x | (x << 16)) & 0x0000FFFF0000FFFF;
    //     x = (x | (x << 8)) & 0x00FF00FF00FF00FF;
    //     x = (x | (x << 4)) & 0x0F0F0F0F0F0F0F0F;
    //     x = (x | (x << 2)) & 0x3333333333333333;
    //     x = (x | (x << 1)) & 0x5555555555555555;
    //     return x;
    // }

    // // Helper function to compact bits
    // function compactBits(uint256 x) internal pure returns (uint32) {
    //     x = x & 0x5555555555555555;
    //     x = (x | (x >> 1)) & 0x3333333333333333;
    //     x = (x | (x >> 2)) & 0x0F0F0F0F0F0F0F0F;
    //     x = (x | (x >> 4)) & 0x00FF00FF00FF00FF;
    //     x = (x | (x >> 8)) & 0x0000FFFF0000FFFF;
    //     x = (x | (x >> 16)) & 0x00000000FFFFFFFF;
    //     return uint32(x);
    // }



    // Helper function to expand bits - fixed version
    function expandBits(uint32 v) internal pure returns (uint256) {
        uint256 x = uint256(v);
        x = (x | (x << 32)) & 0xFFFF00000000FFFF;
        x = (x | (x << 16)) & 0x00FF0000FF0000FF;
        x = (x | (x << 8)) & 0xF00F00F00F00F00F;
        x = (x | (x << 4)) & 0x30C30C30C30C30C3;
        x = (x | (x << 2)) & 0x9249249249249249;
        return x;
    }

    // Helper function to compact bits - fixed version
    function compactBits(uint256 x) internal pure returns (uint32) {
        x = x & 0x9249249249249249;
        x = (x | (x >> 2)) & 0x30C30C30C30C30C3;
        x = (x | (x >> 4)) & 0xF00F00F00F00F00F;
        x = (x | (x >> 8)) & 0x00FF0000FF0000FF;
        x = (x | (x >> 16)) & 0xFFFF00000000FFFF;
        x = (x | (x >> 32)) & 0x00000000FFFFFFFF;
        return uint32(x);
    }

    // Decode coordinates from encoded value
    function decodeCoordinates(
        uint256 encoded
    ) public pure returns (uint32 x, uint32 y, uint32 z) {
        uint256 morton = encoded & ((1 << MORTON_BITS) - 1);
        x = compactBits(morton);
        y = compactBits(morton >> 1);
        z = compactBits(morton >> 2);
    }

    // Get depth from encoded value
    function getDepth(uint256 encoded) public pure returns (uint32) {
        return uint32((encoded & DEPTH_MASK) >> MORTON_BITS);
    }

    // Get parent encoded value
    function getParent(uint256 encoded) public pure returns (uint256) {
        uint32 depth = getDepth(encoded);
        require(depth > 0, "Root node has no parent");

        // Get morton code without depth bits
        uint256 morton = encoded & ((1 << MORTON_BITS) - 1);
        // Shift morton code right by 3 (removing lowest level detail)
        uint256 parentMorton = morton >> 3;
        // Add new depth in most significant bits
        return (uint256(depth - 1) << MORTON_BITS) | parentMorton;
    }

    // Get children encoded values
    function getChildren(
        uint256 encoded
    ) public pure returns (uint256[8] memory) {
        uint32 depth = getDepth(encoded);
        require(depth < MAX_DEPTH, "Maximum depth reached");

        uint256[8] memory children;
        uint256 morton = encoded & ((1 << MORTON_BITS) - 1);
        morton = morton << 3; // Make room for child bits

        // Generate all 8 children
        for (uint256 i = 0; i < 8; i++) {
            // Add child index bits and new depth in most significant bits
            children[i] = (uint256(depth + 1) << MORTON_BITS) | (morton | i);
        }

        return children;
    }

    function readTree(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth
    ) public view returns (bytes memory) {
        // Start with empty dynamic bytes array
        bytes memory result = new bytes(0);
        uint256 target = encode(x, y, z, depth);

        // Recursively traverse tree and append to result
        result = traverseNode(target);

        return result;
    }

    function traverseNode(
        uint256 encoded
    ) internal view returns (bytes memory) {
        uint8 value = _get(encoded);

        if (value == NODE_VALUE) {
            // For nodes, we start with 255 and append all children
            bytes memory result = new bytes(1);
            result[0] = bytes1(value);

            // Get and traverse all children
            uint256[8] memory children = getChildren(encoded);
            for (uint256 i = 0; i < 8; i++) {
                bytes memory childResult = traverseNode(children[i]);
                result = bytes.concat(result, childResult);
            }
            return result;
        } else if (value == BEYOND_LEAF_VALUE) {
            // If we hit a beyond-leaf value, we need to find its parent leaf value
            uint256 current = encoded;
            while (true) {
                current = getParent(current);
                value = _get(current);
                if (value > 0 && value < NODE_VALUE) break;
                require(getDepth(current) > 0, "No leaf parent found");
            }
            bytes memory result = new bytes(1);
            result[0] = bytes1(value);
            return result;
        } else {
            // For leaf values (1-254), just return the value
            bytes memory result = new bytes(1);
            result[0] = bytes1(value);
            return result;
        }
    }

    function writeTree(
        uint32 x,
        uint32 y,
        uint32 z,
        uint32 depth,
        bytes calldata data
    ) public {
        require(data.length > 0, "Empty data");
        uint256 target = encode(x, y, z, depth);
        clearChildren(target);
        subdivideToTarget(target);
        uint256 consumed = writeTreeInternal(target, data, 0);
        require(consumed == data.length, "Data not fully consumed");
    }

    function writeTreeInternal(
        uint256 encoded,
        bytes calldata data,
        uint256 dataIndex
    ) internal returns (uint256) {
        require(dataIndex < data.length, "Data underflow");
        require(uint8(data[dataIndex]) > 0, "No encoded value can be zero");

        _set(encoded, uint8(data[dataIndex]));

        if (uint8(data[dataIndex]) == NODE_VALUE) {
            uint256[8] memory children = getChildren(encoded);
            uint256 consumed = 1;
            for (uint256 i = 0; i < 8; i++) {
                consumed += writeTreeInternal(
                    children[i],
                    data,
                    dataIndex + consumed
                );
            }
            return consumed;
        }

        return 1;
    }
}