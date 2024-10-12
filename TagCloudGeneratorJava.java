import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * Generates a tag cloud from a given input text using Java components.
 *
 * @author P. Shrestha
 * @author S. Rajesh
 *
 */
public final class TagCloudGeneratorJava {

    /**
     * max and minimum font.
     */
    private static final int FontMax = 48;
    private static final int FontMin = 11;

    /**
     * Compare {@code String} in lexicographic order.
     */
    private static class StringLT implements Comparator<Map.Entry<String, Integer>> {
        @Override
        public int compare(Map.Entry<String, Integer> o1, Map.Entry<String, Integer> o2) {
            return o1.getKey().compareToIgnoreCase(o2.getKey());
        }
    }

    /**
     * Compare {@code Integer} in lexicographic order.
     */
    private static class IntegerLT implements Comparator<Map.Entry<String, Integer>> {
        @Override
        public int compare(Map.Entry<String, Integer> o1, Map.Entry<String, Integer> o2) {
            return o2.getValue().compareTo(o1.getValue());
        }
    }

    /**
     * No argument constructor--private to prevent instantiation.
     */
    private TagCloudGeneratorJava() {
    }

    /**
     * Creates a list of words and the number of times they appear from the
     * given strings stored in the stream {@code file}.
     *
     * @param countMap
     *            the list that holds the words and its counts
     * @param file
     *            the stream to be read from
     * @replaces {@code countMap}
     * @requires [{@code countMap} to be empty && {@code file} to not be null]
     * @ensures [{@code countMap} has all the words containing in {@code file}]
     */
    private static void createMapCounts(Map<String, Integer> countMap,
            BufferedReader file) {
        assert countMap.size() == 0 : "Violation of: countMap is empty";
        assert file != null : "Violation of: inputFile is null";

        //goes through the entire file and skips over empty "words"
        try {
            String line = file.readLine();
            while (line != null) {
                line = line.toLowerCase();
                if (!line.isEmpty()) {
                    String[] words = line.split("\\W+");
                    for (String word : words) {
                        //skips over empty and blank "words"
                        if (!word.isBlank() && !word.isEmpty()) {
                            //adds the word if not in already initialized to 1
                            //and adds one to the count if not.
                            if (countMap.containsKey(word)) {
                                countMap.replace(word, countMap.get(word),
                                        countMap.get(word) + 1);
                            } else {
                                countMap.put(word, 1);
                            }
                        }
                    }
                }
                line = file.readLine();
            }
        } catch (Exception e) {
            System.err.println("Error reading the input file");
        }
    }

    /**
     * Sorts the values of {@code countMap} through {@code sortedValues} in a
     * decreasing order.
     *
     * @param countMap
     *            the list that holds the words and its counts
     * @param sortedValues
     *            the updated list holds the contents of the map in an order
     * @replaces {@code sortedValues}
     * @requires [{@code sortedValues} to be empty and {@code countMap} to not
     *           be]
     * @ensures [{@code sortedValues} will contain every word and its count that
     *          is in {@code countMap} in a decreasing order.]
     */
    private static void sortByCounts(Map<String, Integer> countMap,
            ArrayList<Map.Entry<String, Integer>> sortedValues) {
        assert countMap.size() != 0 : "Violation of: countMap is empty";
        assert sortedValues.size() == 0 : "Violation of: countMap is not empty";

        //takes everything out of the map and puts them into the ArrayList
        for (Map.Entry<String, Integer> entry : countMap.entrySet()) {
            sortedValues.add(entry);
        }
        //creates the comparator for the list, which sorts the list
        Comparator<Map.Entry<String, Integer>> order = new IntegerLT();
        sortedValues.sort(order);

    }

    /**
     * Removes n number of pairs from {@code sortedValues} and adds them to
     * {@code sortedKeys}.
     *
     * @param sortedKeys
     *            the list that holds n number of pairs
     * @param sortedValues
     *            the list that holds the sorted pairs to be removed
     * @param n
     *            the number of entries to be removed
     * @replaces sortedKeys
     * @updates sortedValues
     * @requires [{@code sortedValues} to not be empty, and {@code sortedKeys}
     *           to be not empty, and n <= |sortedValues|]
     * @ensures [{@code sortedKeys} has the first n number of entries from
     *          {@code sortedValues}]
     */
    private static void sortByWords(ArrayList<Map.Entry<String, Integer>> sortedValues,
            ArrayList<Map.Entry<String, Integer>> sortedKeys, int n) {
        assert sortedValues.size() != 0 : "Violation of: sortedValues is empty";
        assert sortedKeys.size() == 0 : "Violation of: sortedKeys is not empty";
        assert n <= sortedValues.size() && n > 0 : "Violation of: Invaid n value";

        //takes everything out of one sorting ArrayList and puts it into another
        //goes until n numbers to sort them alphabetically
        for (int i = 0; i < n; i++) {
            Map.Entry<String, Integer> pair = sortedValues.get(i);
            sortedKeys.add(pair);
        }
        //creates the comparator for the list, which sorts the list
        Comparator<Map.Entry<String, Integer>> order = new StringLT();
        sortedKeys.sort(order);
    }

    /**
     * Prints all the HTML tags for the header along with their contents which
     * is required to build an HTML page.
     *
     * @param folderPath
     *            the name of file
     * @param address
     *            the location of the file being read
     * @param n
     *            the number of words to be printed
     * @requires [{@code folderPath} needs to be open, {@code address}, and
     *           {@code fileExtension} all need to be null.]
     * @ensures [{@code folderPath} will print all the HTML tags for the header
     *          along with fileExtension as the title]
     */
    public static void buildHeader(PrintWriter folderPath, String address, int n) {
        assert folderPath != null : "Violation of: folderPath is not null";
        assert address != null : "Violation of: address is not null";
        assert n > 0 : "Violation of: n < 0";

        folderPath.println("<html>");
        folderPath.println("<head>");
        folderPath.println("<title>Top " + n + " words in " + address + "</title>");
        folderPath
                .println("<link href=\"https://cse22x1.engineering.osu.edu/2231/web-sw2/"
                        + "assignments/projects/tag-cloud-generator/data/tagcloud.css\" "
                        + "rel=\"stylesheet\" type=\"text/css\">");
        folderPath.println(
                "<link href=\"tagcloud.css\" " + "rel=\"stylesheet\" type=\"text/css\">");
        folderPath.println("</head>");
        folderPath.println("<body>");
        folderPath.println("<h2>Top " + n + " words in " + address + "</h2>");
        folderPath.println("<hr>");
        folderPath.println("<div class = \"cdiv\">");
        folderPath.println("<p class = \"cbox\">");
    }

    /**
     * Sets the font of the word based on its count.
     *
     * @param countSize
     *            the amount of time a word appears
     * @param minCount
     *            the word that appears the least amount of time
     * @param maxCount
     *            the word that appears the most amount of time
     * @requires <pre> [countSize {@code Integer},
    minCount{@code Integer}, and
     * {@code Integer} to be greater than 0] </pre>
     * @ensures[fontBuilder {@code Integer} will be the new font of the word
     *                      based on its count and the minimum and maximum
     *                      values provided in the argument]
     * @return the new font of the word /** Main method.
     */
    public static int fontBuilder(int countSize, int minCount, int maxCount) {

        int newFont = 0;
        int oldRange = (maxCount - minCount);
        //check for if max and min count are the same
        if (oldRange == 0) {
            newFont = (FontMin + FontMax) / 2;
        } else {
            newFont = (((countSize - minCount) * (FontMax - FontMin)) / oldRange)
                    + FontMin;
        }

        return newFont;
    }

    /**
     * Prints all the HTML tags for the body along with their contents which is
     * required to build an HTML page.
     *
     * @param folderPath
     *            file to be written to
     * @param sortedValues
     *            the list sorted in numerical order
     * @param n
     *            the number of words to be displayed in the cloud
     *
     * @requires [{@code sortedValues} are sorted based on highest value to
     *           lowest value, {@code folderPath} is NOT null and is open, and
     *           {@code n} is greater than 0]
     * @ensures [{@code folderPath} will print all the HTML tags for the body
     *          and will set the correct font for each of the word that is
     *          displayed in the tag cloud]
     */
    public static void buildBody(PrintWriter folderPath,
            ArrayList<Map.Entry<String, Integer>> sortedValues, int n) {
        assert folderPath != null : "Violation of: folderPath is not null";
        assert sortedValues.size() != 0 : "Violation of: sortedKeys is not empty";

        ArrayList<Map.Entry<String, Integer>> sortedKeys;
        sortedKeys = new ArrayList<Map.Entry<String, Integer>>();
        //goes through the entire sortedValues to check for the minimum and
        //maximum counts in the list to create an average for the print out
        int maxCount = 0, minCount = 0;
        for (Map.Entry<String, Integer> entry : sortedValues) {
            if (entry.getValue() > maxCount) {
                maxCount = entry.getValue();
            }
            if (entry.getValue() < minCount) {
                minCount = entry.getValue();
            }
        }
        //transfers important pairs into sortedKeys from sortedValues
        sortByWords(sortedValues, sortedKeys, n);

        for (Map.Entry<String, Integer> entry : sortedKeys) {
            folderPath.println("<span style=\"cursor:default\" class=\"" + "f"
                    + fontBuilder(entry.getValue(), minCount, maxCount)
                    + "\" title=\"count: " + entry.getValue() + "\">" + entry.getKey()
                    + "</span>");
        }
    }

    /**
     * Prints all the HTML tags for the footer which are closing tags to
     * required to build an HTML page.
     *
     * @param folderPath
     *            the file to be written to
     * @requires [{@code folderPath} needs to be open and not null]
     * @ensures [{@code folderPath} will print all the HTML tags for the footer,
     *          closing the HTML page.]
     */
    public static void buildFooter(PrintWriter folderPath) {
        folderPath.println("</p>");
        folderPath.println("</div>");
        folderPath.println("</body>");
        folderPath.println("</html>");
    }

    /**
     * @param args
     *            the command line arguments
     */
    public static void main(String[] args) {

        BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
        String inputFile = "";
        System.out.println("Enter the address of the file to read: ");
        BufferedReader input = null;
        while (input == null) {
            try {
                inputFile = in.readLine();
                input = new BufferedReader(new FileReader(inputFile));
            } catch (IOException e) {
                System.out.println("Invalid file");
            }
        }
        String outputFile = "";
        System.out.print("Enter the name and path of the output file ");
        PrintWriter folderPath = null;
        while (folderPath == null) {
            try {
                outputFile = in.readLine();
                folderPath = new PrintWriter(
                        new BufferedWriter(new FileWriter(outputFile)));
            } catch (IOException e) {
                System.out.println("Invalid file");
            }
        }
        int n = 0;
        System.out.print("Enter how many words to print: ");
        try {
            n = Integer.parseInt(in.readLine());
        } catch (NumberFormatException e) {
            System.err.println("Invalid number");
        } catch (IOException e) {
            System.err.println("Invalid input");
        }

        Map<String, Integer> countMap = new HashMap<String, Integer>();
        createMapCounts(countMap, input);

        ArrayList<Map.Entry<String, Integer>> sortedValues;
        sortedValues = new ArrayList<Map.Entry<String, Integer>>();

        sortByCounts(countMap, sortedValues);

        buildHeader(folderPath, inputFile, n);
        buildBody(folderPath, sortedValues, n);
        buildFooter(folderPath);

        try {
            folderPath.close();
            in.close();
        } catch (IOException e) {
            System.err.println("Error closing streams.");
        }
    }

}
