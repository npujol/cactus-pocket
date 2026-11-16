# Third-party notices

The root [`LICENSE`](LICENSE) applies to original Cactus Pocket project code. It does not relicense the third-party components listed here. The Apache-2.0 license text is included at [`LICENSES/Apache-2.0.txt`](LICENSES/Apache-2.0.txt).

## Cactus native runtime

- Component: Cactus 4.1.1 Android ARM64 static library (`libcactus.a`), linked into `libcactus_jni.so`.
- Source: [Cactus-Compute/cactus, revision `d2c5cd70432ed78345f3ba6b620bff2feeec6c86`](https://huggingface.co/Cactus-Compute/cactus/tree/d2c5cd70432ed78345f3ba6b620bff2feeec6c86/releases/4.1.1).
- Vendored archive: [`cactus_pocket/android/app/src/main/native-libs/arm64-v8a/libcactus.a`](cactus_pocket/android/app/src/main/native-libs/arm64-v8a/libcactus.a), 2,822,132 bytes, SHA-256 `01b91dae81d7e94ce55691376838d8b10453d33d7433ddd1b59bf4a9669012b9`.
- License: Apache License 2.0. The included license text was copied from the pinned upstream revision's `releases/4.1.1/LICENSE`; its SHA-256 matches the canonical Apache license text.
- The pinned upstream tree was checked for a `NOTICE` file; none was present.

## Mirage model

- Component: `mirage.cact`, downloaded at runtime; it is not vendored in this repository.
- Source: [Cactus-Compute/mirage, revision `76c1e9e53381aca8fc3843c636216c96ff220122`](https://huggingface.co/Cactus-Compute/mirage/tree/76c1e9e53381aca8fc3843c636216c96ff220122).
- Artifact: 21,611,043 bytes, SHA-256 `4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237`.
- License: the pinned model repository metadata declares Apache-2.0. The Apache-2.0 text is included in [`LICENSES/Apache-2.0.txt`](LICENSES/Apache-2.0.txt).
- The pinned model repository tree contains no separate `NOTICE` file.

This notice records the artifact provenance and license metadata verified for the pinned revisions. Review the corresponding upstream license metadata again whenever either revision changes.
