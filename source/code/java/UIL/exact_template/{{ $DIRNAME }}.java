:DELIMS tag="{{ }}" stmt="#@" comment="%#"
import java.util.Scanner;

public class {{ $BASENAME }} {
  public static void main(String... args) {
    try (Scanner dataScanner = new Scanner({{ $BASENAME }}.class.getResourceAsStream("./{{ ${BASENAME,} }}.dat"))) {
      int dataCount = dataScanner.nextInt();
      dataScanner.nextLine();
      for (int i = 0; i < dataCount; i++) {
        // Do Some Stuff
      }
    }

  }
}
