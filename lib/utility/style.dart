import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

TextStyle extraSmall = GoogleFonts.montserrat(
  fontSize: 10,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.normal,
);

TextStyle small = GoogleFonts.montserrat(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.normal,
);

TextStyle medium = GoogleFonts.montserrat(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.normal,
);

TextStyle large = GoogleFonts.montserrat(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.normal,
);

TextStyle extraLarge = GoogleFonts.montserrat(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.normal,
);

TextStyle extraSmallBold = GoogleFonts.montserrat(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.normal,
);

TextStyle smallBold = GoogleFonts.montserrat(
  fontSize: 12,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.normal,
);

TextStyle mediumBold = GoogleFonts.montserrat(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.normal,
);

TextStyle largeBold = GoogleFonts.montserrat(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.normal,
);

TextStyle extraLargeBold = GoogleFonts.montserrat(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.normal,
);

ButtonStyle simpleElevatedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColor.primary,
  textStyle: medium,
);

ButtonStyle squareElevatedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColor.black,
  disabledBackgroundColor: AppColor.grey,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  padding: EdgeInsets.zero,
);

InputDecoration textFormFieldDecoration = InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder()
);

Widget dropdownContainer(String text, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Text(text, style: small.copyWith(color: AppColor.black)),
        const Spacer(),
        Icon(icon),
      ],
    ),
  );
}