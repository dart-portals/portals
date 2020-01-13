## 0.0.9 – 2020-01-13

- Add binary serializer: Now you can send anything through portals!
- Updated readme. It now contains a "How it works" section.
- Fix analysis issues. (A file wasn't saved yet and showed no errors in the editor.)

## 0.0.8 – 2020-01-02

- Revise this changelog.
- Revise readme.
- Add `waitForPhrase` helper method.
- More code reusage in helper methods.
- Offer getter for `key`.
- Implement `close` method.

## 0.0.7 – 2019-12-31

- Export all the necessary stuff from the package: Not only the `Portal`, but also several phrase generators, events and errors.
- Make it impossible for both sides to choose the same side id.

## 0.0.6 – 2019-12-31

- Don't transfer `Version`s anymore, but rather more generic info `String`s. Users can still exchange versions, but also human-readable display names or something like that. It just makes portals more flexible and the API surface easier to understand.
- Remove `version` dependency.
- Rename *code* to *phrase*. The term *code generator* conflicts with actual Dart code generators.
- The reversibility of the `PhraseGenerator` now gets verified whenever a phrase gets generated in debug mode.
- Added several utility methods and functions to make the code more readable and succinct.
- The default phrase generator is now the new `WordsPhraseGenerator`, which turns both the nameplate and the key into a string of human-readable words.

## 0.0.5 – 2019-12-29

- Laxen dependencies on `collection` so the package can be used together with Flutter.
- Fix some analysis issues.

## 0.0.4 – 2019-12-29

- Laxen dependencies on `pedantic` so the package can be used together with Flutter.
- Fix `version` parameter in readme.
- Fix some analysis issues.

## 0.0.3 – 2019-12-29

- Add boilerplate for example.
- Fix some analysis issues.

## 0.0.2 – 2019-12-29

- Add this changelog.
- Make package description longer.
- Point to correct GitHub repository.
- Add pedantic analysis.
- Clean up readme.
- Fix some analysis issues.

## 0.0.1 – 2019-12-29

- Initial version. You can connect portals on devices that can see each other and then transfer bytes.
