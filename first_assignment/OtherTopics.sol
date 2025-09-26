// SPDX-License-Identifier: MIT
pragma solidity ~0.8;

contract ReverseString {
    function reverseString(
        string memory _str
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory reverse_string = new bytes(strBytes.length);
        for (uint i = 0; i < strBytes.length; i++) {
            reverse_string[i] = strBytes[strBytes.length - 1 - i];
        }
        return string(reverse_string);
    }
}

contract RomanToInt {
    mapping(string => uint) private roman_map;

    constructor() {
        roman_map["I"] = 1;
        roman_map["V"] = 5;
        roman_map["X"] = 10;
        roman_map["L"] = 50;
        roman_map["C"] = 100;
        roman_map["D"] = 500;
        roman_map["M"] = 1000;
    }

    function charToValue(bytes1 c) internal view returns (uint) {
        if (c == "I") return roman_map["I"];
        if (c == "V") return roman_map["V"];
        if (c == "X") return roman_map["X"];
        if (c == "L") return roman_map["L"];
        if (c == "C") return roman_map["C"];
        if (c == "D") return roman_map["D"];
        if (c == "M") return roman_map["M"];
        revert(unicode"无效的罗马数字");
    }

    function romanToInt(string memory _str) public view returns (uint) {
        bytes memory strBytes = bytes(_str);
        uint total = 0;
        uint i = 0;

        while (i < strBytes.length) {
            uint current = charToValue(strBytes[i]);
            uint next = 0;

            if (i + 1 < strBytes.length) {
                next = charToValue(strBytes[i + 1]);
            }

            if (next > current) {
                // 特殊减法情况
                total += (next - current);
                i += 2;
            } else {
                total += current;
                i += 1;
            }
        }

        return total;
    }
}

contract IntToRoman {
    mapping(uint => string) private roman_map;

    constructor() {
        roman_map[1] = "I";
        roman_map[4] = "IV";
        roman_map[5] = "V";
        roman_map[9] = "IX";
        roman_map[10] = "X";
        roman_map[40] = "XL";
        roman_map[50] = "L";
        roman_map[90] = "XC";
        roman_map[100] = "C";
        roman_map[400] = "CD";
        roman_map[500] = "D";
        roman_map[900] = "CM";
        roman_map[1000] = "M";
    }

    function intToRoman(uint _number) public view returns (string memory) {
        require(_number > 0 && _number <= 3999, "Number out of range (1-3999)");
        uint[13] memory values = [uint(1000), 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        bytes memory result;

        for (uint i = 0; i < values.length; i++) {
            // 相减之后,符合values的下一个累加值才解除while循环
            while (_number >= values[i]) {
                _number -= values[i];
                result = abi.encodePacked(result, roman_map[values[i]]);
            }
        }

        return string(result);
    }
}

contract MergeSortedArrays {
    function mergeSortedArrays(uint[] memory a, uint[] memory b) public pure returns (uint[] memory) {
        uint totalLength = a.length + b.length;
        uint[] memory result = new uint[](totalLength);

        uint i = 0; // 指针a
        uint j = 0; // 指针b
        uint k = 0; // 指针result

        // 先掏空a或者b,任意一个数组
        while (i < a.length && j < b.length) {
            if (a[i] <= b[j]) {
                result[k] = a[i];
                i++;
            } else {
                result[k] = b[j];
                j++;
            }
            k++;
        }

        // 当a或b被掏空任意一个,剩下只需要把另一个剩下的所有值都挪进去即可
        while (i < a.length) {
            result[k] = a[i];
            i++;
            k++;
        }
        while (j < b.length) {
            result[k] = b[j];
            j++;
            k++;
        }

        return result;
    }
}

contract BinarySearch {
    // 返回目标在arr中的下标索引值(arr应该要从小到大排序)
    function binarySearch(uint[] memory arr, uint target) public pure returns (int) {
        int left = 0;
        int right = int(arr.length) - 1;

        while (left <= right) {
            int mid = left + (right - left) / 2; // 避免溢出
            uint midVal = arr[uint(mid)];

            if (midVal == target) {
                return mid; // 找到了
            } else if (midVal < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return -1; // 没找到
    }
}