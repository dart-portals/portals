import '../utils.dart';
import 'phrase_generator.dart';

class WordsPhraseGenerator implements PhraseGenerator {
  const WordsPhraseGenerator();

  /// 256 adjectives chosen from various sources, including the top 1000
  /// english adjectives by usage, "Harry Potter" and "How I Met Your Mother".
  static const _adjectives = [
    ...['red', 'green', 'blue', 'pink', 'yellow', 'orange', 'purple', 'black'],
    ...['white', 'brown', 'cute', 'fluffy', 'squishy', 'sunny', 'intelligent'],
    ...['creative', 'colorful', 'tired', 'stylish', 'thick', 'clear', 'basic'],
    ...['suitable', 'existing', 'boring', 'logical', 'distinct', 'reasonable'],
    ...['easy', 'free', 'full', 'good', 'great', 'fit', 'high', 'comfortable'],
    ...['little', 'new', 'old', 'public', 'right', 'strong', 'whole', 'angry'],
    ...['different', 'used', 'important', 'every', 'large', 'popular', 'safe'],
    ...['hot', 'useful', 'scared', 'healthy', 'hard', 'traditional', 'bloody'],
    ...['big', 'happy', 'helpful', 'nice', 'wonderful', 'impressive', 'local'],
    ...['serious', 'huge', 'rare', 'technical', 'typical', 'critical', 'ugly'],
    ...['electronic', 'global', 'yawning', 'relevant', 'capable', 'dangerous'],
    ...['dramatic', 'efficient', 'powerful', 'foreign', 'loving', 'realistic'],
    ...['mysterious', 'stumbling', 'legendary', 'yielding', 'near', 'shining'],
    ...['automatic', 'demanding', 'whomping', 'whirring', 'wonderous', 'sick'],
    ...['brilliant', 'massive', 'visible', 'melodic', 'pleasant', 'throbbing'],
    ...['friendly', 'lucky', 'hungry', 'hairy', 'sleeping', 'legal', 'normal'],
    ...['quick', 'metallic', 'terrible', 'sneezing', 'confident', 'conscious'],
    ...['thumping', 'guilty', 'decent', 'sparkling', 'beautiful', 'screaming'],
    ...['zooming', 'slurping', 'secure', 'connected', 'whooshing', 'familiar'],
    ...['walking', 'glorious', 'thinking', 'laughing', 'cooking', 'fantastic'],
    ...['physical', 'digital', 'single', 'working', 'warm', 'wet', 'positive'],
    ...['smart', 'stupid', 'ideal', 'swimming', 'honest', 'illegal', 'annual'],
    ...['sour', 'fluent', 'dancing', 'living', 'harmonic', 'precious', 'mean'],
    ...['pliant', 'proper', 'complex', 'content', 'regular', 'smooth', 'slow'],
    ...['amazing', 'busy', 'dead', 'round', 'sharp', 'wise', 'proud', 'light'],
    ...['snoring', 'yelling', 'lonely', 'gray', 'woofing', 'natural', 'solid'],
    ...['tight', 'deathly', 'reading', 'brave', 'talking', 'dirty', 'magical'],
    ...['fast', 'yummy', 'tasteful', 'grand', 'sneaking', 'chemical', 'beefy'],
    ...['wooden', 'pretty', 'classic', 'excellent', 'separate', 'sad', 'rich'],
    ...['loose', 'loud', 'quiet', 'former', 'empty', 'neat', 'silly', 'weird'],
    ...['mad', 'nervous', 'odd', 'tall', 'tiny', 'general', 'sweet', 'cloudy'],
    ...['sleepy', 'long', 'small', 'certain', 'common', 'ordinary', 'rickety'],
    ...['perfect', 'external', 'drawing', 'sensitive', 'late', 'dry', 'tough'],
    ...['nasty', 'bright', 'flat', 'young', 'heavy', 'fresh', 'secret', 'fun'],
    ...['thin', 'fine', 'dark', 'gross', 'soft', 'strange', 'rough', 'hollow'],
    ...['wild', 'crazy', 'lying', 'usual', 'funny', 'sudden', 'cool', 'clean'],
    ...['bad', 'holistic', 'fair', 'calm', 'bitter'],
  ];

  /// 256 nouns chosen from various sources, including "Harry Potter",
  /// "Lord of the Rings", "Dirk Gently", "Final Space" and "Portal 2".
  static const _nouns = [
    ...['cloud', 'wall', 'code', 'beard', 'bread', 'butter', 'crown', 'snake'],
    ...['unicorn', 'hair', 'wizard', 'gold', 'coin', 'elve', 'cloak', 'stone'],
    ...['nose', 'vinegar', 'coke', 'tea', 'chocolate', 'hill', 'snow', 'rain'],
    ...['butterfly', 'sunshine', 'spaceship', 'scyscraper', 'salad', 'shield'],
    ...['cookie', 'wand', 'island', 'planet', 'lamp', 'soup', 'stew', 'coast'],
    ...['astronaut', 'robot', 'tomb', 'nougat', 'present', 'quark', 'shimmer'],
    ...['pineapple', 'waterfall', 'teleporter', 'roundabout', 'spoon', 'kiwi'],
    ...['neurotoxin', 'brownie', 'cinnamon', 'pumpkin', 'counter', 'universe'],
    ...['deluminator', 'platform', 'fireplace', 'marshmallow', 'axe', 'knife'],
    ...['detective', 'whillow', 'bacteria', 'coconut', 'trapdoor', 'elevator'],
    ...['lightning', 'sticker', 'galaxy', 'armchair', 'potato', 'nail', 'egg'],
    ...['computer', 'banana', 'hobbit', 'lemon', 'vampire', 'treasure', 'cow'],
    ...['keyboard', 'blanket', 'window', 'burrito', 'pizza', 'knight', 'cage'],
    ...['shark', 'piano', 'shirt', 'doe', 'stick', 'donkey', 'dice', 'waffle'],
    ...['mountain', 'portal', 'horcrux', 'penguin', 'monster', 'bird', 'scar'],
    ...['cabinet', 'badger', 'goblin', 'hallow', 'eraser', 'device', 'camera'],
    ...['moon', 'sun', 'city', 'town', 'donut', 'hourglass', 'octopus', 'ice'],
    ...['sand', 'table', 'cup', 'spike', 'sword', 'vault', 'tooth', 'popcorn'],
    ...['gun', 'stair', 'onion', 'candy', 'dragon', 'chair', 'sugar', 'sushi'],
    ...['dwarf', 'ring', 'thing', 'tower', 'water', 'glass', 'floo', 'powder'],
    ...['house', 'cake', 'cube', 'wood', 'chicken', 'train', 'light', 'grave'],
    ...['mirror', 'hat', 'car', 'tree', 'pear', 'grapes', 'turret', 'picture'],
    ...['chain', 'bell', 'fire', 'steam', 'apple', 'peanut', 'mango', 'frame'],
    ...['lion', 'raven', 'claw', 'book', 'school', 'plant', 'flower', 'glove'],
    ...['noodle', 'tomato', 'pen', 'door', 'room', 'path', 'carrot', 'carpet'],
    ...['bottle', 'broom', 'castle', 'diary', 'rope', 'ink', 'basket', 'mars'],
    ...['bridge', 'hand', 'ball', 'square', 'spider', 'giant', 'clock', 'goo'],
    ...['alien', 'thunder', 'dust', 'map', 'earth', 'sensor', 'tape', 'smoke'],
    ...['ear', 'tear', 'closet', 'zombie', 'money', 'wind', 'crisps', 'photo'],
    ...['cactus', 'shadow', 'glue', 'yoghurt', 'chips', 'pig', 'bolt', 'atom'],
    ...['brick', 'cape', 'sock', 'hut', 'note', 'wolf', 'rat', 'maze', 'cave'],
    ...['mixer', 'ape', 'ghost', 'suit', 'air', 'letter', 'object', 'toaster'],
    ...['bed', 'paper', 'eye', 'bomb', 'orc', 'cat', 'dog', 'mouse', 'button'],
    ...['hippo', 'coala', 'paint', 'laser', 'bus', 'box'],
  ];

  @override
  String payloadToPhrase(PhrasePayload payload) {
    // First, merge both Uint8Lists into one list. Because the key has a static
    // length, we can just concatenate the two lists and then translate each
    // the byte of the resulting list into words.
    final bytes = payload.nameplate + payload.key;

    final adjectives =
        bytes.sublist(0, bytes.length - 1).map((i) => _adjectives[i]);
    final noun = _nouns[bytes.last];
    return [...adjectives, noun].join(' ');
  }

  @override
  PhrasePayload phraseToPayload(String phrase) {
    final words = phrase.split(' ');
    final adjectiveBytes =
        words.sublist(0, words.length - 1).map(_adjectives.indexOf);
    final nounByte = _nouns.indexOf(words.last);

    final bytes = [...adjectiveBytes, nounByte];
    final keyOffset = bytes.length - PhrasePayload.keyLength;

    return PhrasePayload(
      nameplate: bytes.sublist(0, keyOffset).toBytes(),
      key: bytes.sublist(keyOffset).toBytes(),
    );
  }
}
