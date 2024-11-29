// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library Array {
    /**
     * @notice Removes an element from the array at the specified index.
     * @dev Moves the last element into the place to delete and then pops the last element.
     * @param arr The storage array from which the element will be removed.
     * @param index The index of the element to remove.
     * @require The array must not be empty.
     */
    function remove(address[] storage arr, uint256 index) internal {
        // Move the last element into the place to delete
        require(arr.length > 0, "Can't remove from empty array");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}
