public class $BASENAME {
  public static void main(String... args) {
    // All paths are relative to the source root unless specified otherwise.
    System.out.println("FILEPATH: ${FILEPATH}"); // This file's path
    System.out.println("REALPATH: ${REALPATH}"); // This file's absolute path
    System.out.println("FILENAME: ${FILENAME}"); // This file's name
    System.out.println("DIRNAME: ${DIRNAME}"); // This file's directory name
    System.out.println("DATE: ${DATE}"); // The current date mm/dd/yyyy
    System.out.println("TIME: ${TIME}"); // The current time hh:mm 24hr
    System.out.println("EXTENSION: ${EXTENSION}"); // This file's extension (last!)
    System.out.println("BASENAME: ${BASENAME}"); // This file's name without extension
    System.out.println("ROOT: ${ROOT}"); // The name of root (project)
    System.out.println("Hello World!");
  }
}
