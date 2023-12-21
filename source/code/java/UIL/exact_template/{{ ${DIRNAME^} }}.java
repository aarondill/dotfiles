:DELIMS tag="{{ }}" stmt="#@" comment="%#"
#@ CLASS_NAME="${BASENAME^}"
import java.util.Scanner;

public class {{ $CLASS_NAME }} {
  public static void main(String... args) {
    try (Scanner dataScanner = new Scanner({{ $CLASS_NAME }}.class.getResourceAsStream("./{{ ${CLASS_NAME,} }}.dat"))) {
      int dataCount = dataScanner.nextInt();
      dataScanner.nextLine();
      for (int i = 0; i < dataCount; i++) {
        // Do Some Stuff
      }
    }

  }
}
