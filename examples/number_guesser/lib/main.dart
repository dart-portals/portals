import 'dart:io';

enum Mode { thinkOfNumber, guessNumber }

void main() {
  Mode mode;
  while (mode == null) {
    print('Do you want to think of a number or guess a number?');
    final answer = stdin.readLineSync();
    switch (answer) {
      case 'think':
      case 't':
        mode = Mode.thinkOfNumber;
        break;
      case 'guess':
      case 'g':
        mode = Mode.guessNumber;
        break;
      default:
        print('Unknown mode "$answer". Enter either "think" or "guess"!');
    }
  }

  // TODO: implement actual game
}
