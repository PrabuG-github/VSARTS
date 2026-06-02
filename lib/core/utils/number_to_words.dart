/// A utility class for translating numeric amounts to Indian Rupee Words representation.
class NumberToWords {
  /// Converts a [double] amount to Indian Rupees in words.
  /// E.g., 7820.00 -> "Seven Thousand Eight Hundred Twenty Rupees Only"
  static String convert(double amount) {
    if (amount.isNaN || amount.isInfinite) return "Zero Rupees Only";
    if (amount <= 0) return "Zero Rupees Only";

    // Standardize decimals and avoid floating point inaccuracies
    int rupees = amount.truncate();
    int paise = ((amount - rupees) * 100).round();

    // Adjust for roundoffs that overflow to rupees
    if (paise >= 100) {
      rupees += 1;
      paise -= 100;
    }

    final rupeePart = _convertIntegerToWords(rupees);
    final paisePart = paise > 0 ? _convertIntegerToWords(paise) : "";

    String result = "";
    if (rupeePart.isNotEmpty) {
      result += "$rupeePart Rupee${rupees == 1 ? "" : "s"}";
    }

    if (paisePart.isNotEmpty) {
      if (result.isNotEmpty) {
        result += " and ";
      }
      result += "$paisePart Paise";
    }

    if (result.isNotEmpty) {
      result += " Only";
    } else {
      result = "Zero Rupees Only";
    }

    return result;
  }

  static String _convertIntegerToWords(int number) {
    if (number == 0) return "";

    final units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
      "Seventeen", "Eighteen", "Nineteen"
    ];

    final tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    ];

    String convertLessThanOneThousand(int n) {
      String str = "";
      if (n >= 100) {
        str += "${units[n ~/ 100]} Hundred";
        n %= 100;
        if (n > 0) str += " ";
      }
      if (n >= 20) {
        str += tens[n ~/ 10];
        if (n % 10 > 0) {
          str += " ${units[n % 10]}";
        }
      } else if (n > 0) {
        str += units[n];
      }
      return str;
    }

    int temp = number;
    String words = "";

    // Crore (1,00,00,000)
    int crores = temp ~/ 10000000;
    temp %= 10000000;
    if (crores > 0) {
      words += "${convertLessThanOneThousand(crores)} Crore";
      if (temp > 0) words += " ";
    }

    // Lakh (1,00,000)
    int lakhs = temp ~/ 100000;
    temp %= 100000;
    if (lakhs > 0) {
      words += "${convertLessThanOneThousand(lakhs)} Lakh";
      if (temp > 0) words += " ";
    }

    // Thousand (1,000)
    int thousands = temp ~/ 1000;
    temp %= 1000;
    if (thousands > 0) {
      words += "${convertLessThanOneThousand(thousands)} Thousand";
      if (temp > 0) words += " ";
    }

    // Hundreds & Units
    if (temp > 0) {
      words += convertLessThanOneThousand(temp);
    }

    return words.trim();
  }
}
