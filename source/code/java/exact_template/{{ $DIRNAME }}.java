:DELIMS tag="{{ }}" stmt="#@" comment="%#"
/**
 * Primary java class: {{ $BASENAME }}
 *
 * <pre>
 * Author:  Aaron Dill
 * Date:    {{ $DATE }}
 * Course:  Computer Science I AP
 * Period:  3rd
 * </pre>
 *
 * Summary of file:
 *
 */
public class {{ $BASENAME }} {
  public static void main(String... args) {
    %# // All paths are relative to the source root unless specified otherwise.
    %# // FILEPATH: {{ $FILEPATH }} - This file's path
    %# // REALPATH: {{ $REALPATH }} - This file's absolute path
    %# // FILENAME: {{ $FILENAME }} - This file's name
    %# // DIRNAME: {{ $DIRNAME }} - This file's directory name
    %# // DATE: {{ $DATE }} - The current date mm/dd/yyyy
    %# // TIME: {{ $TIME }} - The current time hh:mm 24hr
    %# // EXTENSION: {{ $EXTENSION }} - This file's extension (last!)
    %# // BASENAME: {{ $BASENAME }} - This file's name without extension
    %# // ROOT: {{ $ROOT }} - The name of root (project)
    System.out.println("Hello World!");
  }
}
