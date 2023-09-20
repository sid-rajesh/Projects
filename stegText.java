import java.awt.Color;
import java.util.ArrayList;
import java.util.Scanner;

/**
 * This class provides functionality for text steganography, which involves
 * hiding and revealing text within an image.
 * 
 * @author Sidharth Rajesh
 */
public class SteganographyText {

    /**
     * The main driver program for steganographic text methods and algorithm.
     * It takes user input, hides the input text within an image, and then reveals
     * the hidden text.
     * 
     * @param args Command-line arguments (not used).
     */
    public static void main(String[] args) {
        // Using Scanner for Getting Input from User
        Scanner in = new Scanner(System.in);
        System.out.println("Please enter the text to hide");
        String textToEncrypt = in.nextLine();

        Picture beach = new Picture("images/beach.jpg");
        hideText(beach, textToEncrypt);
        beach.explore();

        String secretMessage = revealText(beach);
        System.out.println("Secret Message you typed is: " + secretMessage);
    }

    /**
     * Takes a string consisting of letters and spaces and encodes the string into
     * an ArrayList of integers. The integers are 1-26, 27 for space, and 0 for the
     * end of the string. The ArrayList of integers is returned.
     * 
     * @param s A string consisting of letters and spaces.
     * @return ArrayList containing integer encoding of the uppercase version of s.
     */
    private static ArrayList<Integer> encodeString(String s) {
        s = s.toUpperCase();
        String alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        ArrayList<Integer> result = new ArrayList<Integer>();

        for (int i = 0; i < s.length(); i++) {
            if (s.substring(i, i + 1).equals(" ")) {
                result.add(27); // Use 27 to represent a space
            } else {
                result.add(alpha.indexOf(s.substring(i, i + 1)) + 1); // Encode letters as 1-26
            }
        }
        result.add(0); // Use 0 to represent the end of the string
        return result;
    }

    /**
     * Returns the string represented by the codes ArrayList. 1-26 corresponds to
     * A-Z, 27 corresponds to space.
     * 
     * @param codes The encoded string.
     * @return The decoded string.
     */
    private static String decodeString(ArrayList<Integer> codes) {
        String result = "";

        String alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        for (int i = 0; i < codes.size(); i++) {
            if (codes.get(i) == 27) {
                result = result + " ";
            } else if (codes.get(i) == 0) {
                break; // End of the string
            } else {
                result = result + alpha.substring(codes.get(i) - 1, codes.get(i));
            }
        }

        return result;
    }

    /**
     * Given a number from 0 to 63, creates and returns a 3-element int array
     * consisting of the integers representing the pairs of bits in the number from
     * right to left.
     * 
     * @param num The number to be broken up.
     * @return An array of bit pairs in the number.
     */
    private static int[] getBitPairs(int num) {
        int[] bits = new int[3];
        int code = num;
        for (int i = 0; i < 3; i++) {
            bits[i] = code % 4;
            code = code / 4;
        }

        return bits;
    }

    /**
     * Hide a string (must be only capital letters and spaces) in a Picture. The
     * string always starts in the upper left corner.
     * 
     * @param p The picture to hide the string in.
     * @param s The string to hide.
     */
    private static void hideText(Picture p, String s) {
        Pixel[][] originalPixels = p.getPixels2D();
        ArrayList<Integer> encodedString = encodeString(s);

        for (int i = 0; i < encodedString.size(); i++) {
            int[] bits = getBitPairs(encodedString.get(i));
            Pixel pixel = originalPixels[0][i];
            Color color = getColor(pixel, bits);
            p.getPixel(0, i).setColor(color);
        }
    }

    /**
     * Get the modified color based on the text bit.
     * 
     * @param p        The original pixel color.
     * @param bits     The bits to encode.
     * @return The modified color.
     */
    private static Color getColor(Pixel p, int[] bits) {
        Integer red = getModifiedColor(p.getRed(), bits[0]);
        Integer green = getModifiedColor(p.getGreen(), bits[1]);
        Integer blue = getModifiedColor(p.getBlue(), bits[2]);
        return new Color(red, green, blue);
    }

    /**
     * Replace the last two bits of the color with the text bit.
     * 
     * @param color    The original color.
     * @param textBit  The text bit to hide.
     * @return The modified color.
     */
    private static Integer getModifiedColor(int color, int textBit) {
        String source = String.format("%8s", Integer.toBinaryString(color)).replace(' ', '0');
        String text = String.format("%4s", Integer.toBinaryString(textBit)).replace(' ', '0');

        String modifiedString = source.substring(0, source.length() - 2) + text.substring(text.length() - 2);

        return Integer.parseInt(modifiedString, 2);
    }

    /**
     * Return a string hidden in the picture.
     * 
     * @param source The picture with hidden string.
     * @return The revealed string.
     */
    private static String revealText(Picture source) {
        ArrayList<Integer> decodedStrings = new ArrayList<Integer>();
        Pixel[][] sourcePixels = source.getPixels2D();
        Integer resultingInt = 0;

        for (int i = 0; i < sourcePixels[0].length; i++) {
            Pixel p = source.getPixel(0, i);
            String red = getTwoBits(p.getRed());
            String green = getTwoBits(p.getGreen());
            String blue = getTwoBits(p.getBlue());
            resultingInt = Integer.parseInt(blue + green + red, 2);
            if (resultingInt == 0) {
                break; // End of the hidden text
            } else {
                decodedStrings.add(resultingInt);
            }
        }

        return decodeString(decodedStrings);
    }

    /**
     * Extract the last two bits of the color to unhide text.
     * 
     * @param color The color to extract bits from.
     * @return The last two bits as a string.
     */
    private static String getTwoBits(int color) {
        String source = String.format("%8s", Integer.toBinaryString(color)).replace(' ', '0');
        return source.substring(source.length() - 2);
    }
}
