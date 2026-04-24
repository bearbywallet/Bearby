// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter_test/flutter_test.dart';
import 'package:bearby/config/ftokens.dart';
import 'package:bearby/mixins/qrcode.dart';

const _evmAddress = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';
const _evmToken = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const _zilScillaAddress = 'zil1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs2r9r9';
const _zilScillaToken = 'zil1ylqqqqqqqqqqqqqqqqqqqqqqqqqqqqqfjdgq';

void main() {
  group('parseCryptoUrl', () {
    group('per-chain address-only', () {
      final cases = <String, (String chain, String address)>{
        'BTC:bc1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5sspknck9': (
          'BTC',
          'bc1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5sspknck9',
        ),
        'ETH:$_evmAddress': ('ETH', _evmAddress),
        'TRX:T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb': (
          'TRX',
          'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb',
        ),
        'SOL:11111111111111111111111111111111': (
          'SOL',
          '11111111111111111111111111111111',
        ),
        'BNB:$_evmAddress': ('BNB', _evmAddress),
        'ZIL:$_zilScillaAddress': ('ZIL', _zilScillaAddress),
        'AVAX:$_evmAddress': ('AVAX', _evmAddress),
        'BASE:$_evmAddress': ('BASE', _evmAddress),
        'ARB:$_evmAddress': ('ARB', _evmAddress),
        'POL:$_evmAddress': ('POL', _evmAddress),
        'KAIA:$_evmAddress': ('KAIA', _evmAddress),
        'OP:$_evmAddress': ('OP', _evmAddress),
        'S:$_evmAddress': ('S', _evmAddress),
      };

      for (final entry in cases.entries) {
        final input = entry.key;
        final (expectedChain, expectedAddress) = entry.value;
        test('$expectedChain address-only', () {
          final result = parseCryptoUrl(input);
          expect(result['chain'], expectedChain);
          expect(result['address'], expectedAddress);
          expect(result['token'], isNull);
          expect(result['amount'], isNull);
        });
      }
    });

    group('query param cases', () {
      test('ETH with amount only', () {
        final result = parseCryptoUrl('ETH:$_evmAddress?amount=1.5');
        expect(result['chain'], 'ETH');
        expect(result['address'], _evmAddress);
        expect(result['amount'], '1.5');
        expect(result['token'], isNull);
      });

      test('ETH with token only', () {
        final result = parseCryptoUrl('ETH:$_evmAddress?token=$_evmToken');
        expect(result['chain'], 'ETH');
        expect(result['address'], _evmAddress);
        expect(result['token'], _evmToken);
        expect(result['amount'], isNull);
      });

      test('ETH with token and amount', () {
        final result =
            parseCryptoUrl('ETH:$_evmAddress?token=$_evmToken&amount=100');
        expect(result['chain'], 'ETH');
        expect(result['address'], _evmAddress);
        expect(result['token'], _evmToken);
        expect(result['amount'], '100');
      });

      test('ZIL Scilla token with amount', () {
        final result = parseCryptoUrl(
          'ZIL:$_zilScillaAddress?token=$_zilScillaToken&amount=50',
        );
        expect(result['chain'], 'ZIL');
        expect(result['address'], _zilScillaAddress);
        expect(result['token'], _zilScillaToken);
        expect(result['amount'], '50');
      });

      test('no colon returns empty map', () {
        expect(parseCryptoUrl('invalidstring'), isEmpty);
      });

      test('empty string returns empty map', () {
        expect(parseCryptoUrl(''), isEmpty);
      });
    });
  });

  group('parseQRSecretData', () {
    group('per-chain seed extraction', () {
      const chains = [
        'BTC',
        'ETH',
        'TRX',
        'SOL',
        'BNB',
        'ZIL',
        'AVAX',
        'BASE',
        'ARB',
        'POL',
        'KAIA',
        'OP',
        'S',
      ];

      for (final chain in chains) {
        test('$chain extracts chain key', () {
          final result = parseQRSecretData('$chain:?seed=abandon abandon');
          expect(result['chain'], chain);
          expect(result['seed'], 'abandon abandon');
        });
      }
    });

    group('param cases', () {
      test('seed only', () {
        final result = parseQRSecretData('ETH:?seed=word1 word2');
        expect(result['chain'], 'ETH');
        expect(result['seed'], 'word1 word2');
        expect(result.containsKey('key'), isFalse);
      });

      test('key only', () {
        final result = parseQRSecretData('ETH:?key=0xprivkey');
        expect(result['chain'], 'ETH');
        expect(result['key'], '0xprivkey');
        expect(result.containsKey('seed'), isFalse);
      });

      test('seed and key', () {
        final result =
            parseQRSecretData('ETH:?seed=abandon abandon&key=0xpriv');
        expect(result['chain'], 'ETH');
        expect(result['seed'], 'abandon abandon');
        expect(result['key'], '0xpriv');
      });

      test('invalid format (no :?) returns empty map', () {
        expect(parseQRSecretData('ETH:$_evmAddress'), isEmpty);
      });

      test('empty string returns empty map', () {
        expect(parseQRSecretData(''), isEmpty);
      });
    });
  });

  group('generateCryptoUrl', () {
    group('per-chain address-only', () {
      final cases = <String, String>{
        'BTC': 'bc1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5sspknck9',
        'ETH': _evmAddress,
        'TRX': 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb',
        'SOL': '11111111111111111111111111111111',
        'BNB': _evmAddress,
        'ZIL': _zilScillaAddress,
        'AVAX': _evmAddress,
        'BASE': _evmAddress,
        'ARB': _evmAddress,
        'POL': _evmAddress,
        'KAIA': _evmAddress,
        'OP': _evmAddress,
        'S': _evmAddress,
      };

      for (final entry in cases.entries) {
        final chain = entry.key;
        final address = entry.value;
        test('$chain produces chain:address', () {
          final result = generateCryptoUrl(chain: chain, address: address);
          expect(result, '$chain:$address');
        });
      }
    });

    group('amount handling', () {
      test('with non-zero amount appends ?amount=', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          amount: '1.5',
        );
        expect(result, 'ETH:$_evmAddress?amount=1.5');
      });

      test('amount "0" is omitted', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          amount: '0',
        );
        expect(result, 'ETH:$_evmAddress');
      });

      test('empty amount is omitted', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          amount: '',
        );
        expect(result, 'ETH:$_evmAddress');
      });
    });

    group('token handling', () {
      test('non-zero EVM token appends ?token=', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          token: _evmToken,
        );
        expect(result, 'ETH:$_evmAddress?token=$_evmToken');
      });

      test('non-zero token with amount appends both', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          token: _evmToken,
          amount: '5',
        );
        expect(result, 'ETH:$_evmAddress?token=$_evmToken&amount=5');
      });

      test('zeroEVM token is omitted', () {
        final result = generateCryptoUrl(
          chain: 'ETH',
          address: _evmAddress,
          token: zeroEVM,
        );
        expect(result, 'ETH:$_evmAddress');
      });

      test('zeroZIL token is omitted', () {
        final result = generateCryptoUrl(
          chain: 'ZIL',
          address: _zilScillaAddress,
          token: zeroZIL,
        );
        expect(result, 'ZIL:$_zilScillaAddress');
      });

      test('zeroZIL token with amount — amount still appended without token',
          () {
        final result = generateCryptoUrl(
          chain: 'ZIL',
          address: _zilScillaAddress,
          token: zeroZIL,
          amount: '10',
        );
        expect(result, 'ZIL:$_zilScillaAddress?amount=10');
      });
    });
  });

  group('generateQRSecretData', () {
    group('per-chain prefix', () {
      const chains = [
        'BTC',
        'ETH',
        'TRX',
        'SOL',
        'BNB',
        'ZIL',
        'AVAX',
        'BASE',
        'ARB',
        'POL',
        'KAIA',
        'OP',
        'S',
      ];

      for (final chain in chains) {
        test('$chain starts with $chain:?', () {
          final result = generateQRSecretData(
            chain: chain,
            seedPhrase: 'abandon abandon',
          );
          expect(result, startsWith('$chain:?'));
        });
      }
    });

    group('param cases', () {
      test('seed only', () {
        final result = generateQRSecretData(
          chain: 'ETH',
          seedPhrase: 'word1 word2',
        );
        expect(result, 'ETH:?seed=word1 word2');
      });

      test('key only', () {
        final result = generateQRSecretData(
          chain: 'ETH',
          privateKey: '0xpriv',
        );
        expect(result, 'ETH:?key=0xpriv');
      });

      test('seed and key', () {
        final result = generateQRSecretData(
          chain: 'ETH',
          seedPhrase: 'abandon abandon',
          privateKey: '0xpriv',
        );
        expect(result, 'ETH:?seed=abandon abandon&key=0xpriv');
      });

      test('neither seed nor key', () {
        final result = generateQRSecretData(chain: 'ETH');
        expect(result, 'ETH:?');
      });
    });
  });

  group('round-trip tests', () {
    const chainAddresses = <String, String>{
      'BTC': 'bc1pmfr3p9j00pfxjh0zmgp99y8zftmd3s5pmedqhyptwy6lm87hf5sspknck9',
      'ETH': _evmAddress,
      'TRX': 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb',
      'SOL': '11111111111111111111111111111111',
      'BNB': _evmAddress,
      'ZIL': _zilScillaAddress,
      'AVAX': _evmAddress,
      'BASE': _evmAddress,
      'ARB': _evmAddress,
      'POL': _evmAddress,
      'KAIA': _evmAddress,
      'OP': _evmAddress,
      'S': _evmAddress,
    };

    group('parseCryptoUrl(generateCryptoUrl(...))', () {
      for (final entry in chainAddresses.entries) {
        final chain = entry.key;
        final address = entry.value;

        test('$chain address-only round-trip', () {
          final url = generateCryptoUrl(chain: chain, address: address);
          final parsed = parseCryptoUrl(url);
          expect(parsed['chain'], chain);
          expect(parsed['address'], address);
        });

        test('$chain address+amount round-trip', () {
          final url = generateCryptoUrl(
            chain: chain,
            address: address,
            amount: '5',
          );
          final parsed = parseCryptoUrl(url);
          expect(parsed['chain'], chain);
          expect(parsed['address'], address);
          expect(parsed['amount'], '5');
        });
      }
    });

    group('parseQRSecretData(generateQRSecretData(...))', () {
      for (final chain in chainAddresses.keys) {
        test('$chain seed round-trip', () {
          final url = generateQRSecretData(
            chain: chain,
            seedPhrase: 'abandon abandon abandon',
          );
          final parsed = parseQRSecretData(url);
          expect(parsed['chain'], chain);
          expect(parsed['seed'], 'abandon abandon abandon');
        });

        test('$chain key round-trip', () {
          final url = generateQRSecretData(
            chain: chain,
            privateKey: '0xdeadbeef',
          );
          final parsed = parseQRSecretData(url);
          expect(parsed['chain'], chain);
          expect(parsed['key'], '0xdeadbeef');
        });
      }
    });
  });

  // ─── parseAnyQrSecret ──────────────────────────────────────────────────────

  group('parseAnyQrSecret', () {
    const _chains = [
      'BTC',
      'ETH',
      'TRX',
      'SOL',
      'BNB',
      'ZIL',
      'AVAX',
      'BASE',
      'ARB',
      'POL',
      'KAIA',
      'OP',
      'S',
    ];
    const _mnemonic12 =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const _mnemonic15 =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon address';
    const _mnemonic18 =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon agent';
    const _mnemonic21 =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon admit';
    const _mnemonic24 =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
    const _hex64 =
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
    // Realistic pattern-valid WIF strings (correct prefix + length + base58 charset)
    const _wifK = 'KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn';
    const _wifL = 'L1aW4aubDFB7yfras2S1mN3bqg9nwySY8nkoLmJebSLD5BWv3ENZ';
    const _wif5 = '5KYZdUEo39z3FPrtuX2QbbwGnNP5zTd7yyr2SC1j299sBCnWjss';

    // ── bearby format ────────────────────────────────────────────────────────

    group('bearby format', () {
      for (final chain in _chains) {
        test('$chain:?seed=... → bearby, chain=$chain', () {
          final r = parseAnyQrSecret('$chain:?seed=abandon abandon abandon');
          expect(r.kind, QrSecretKind.bearby);
          expect(r.chain, chain);
          expect(r.payload, isNull);
        });

        test('$chain:?key=... → bearby, chain=$chain', () {
          final r = parseAnyQrSecret('$chain:?key=$_hex64');
          expect(r.kind, QrSecretKind.bearby);
          expect(r.chain, chain);
        });

        test('$chain:?seed=...&key=... → bearby', () {
          final r = parseAnyQrSecret('$chain:?seed=word one&key=ab12');
          expect(r.kind, QrSecretKind.bearby);
          expect(r.chain, chain);
        });
      }

      test(
          'round-trip: generateQRSecretData seed → parseAnyQrSecret → parseQRSecretData recovers seed',
          () {
        const raw =
            'ETH:?seed=abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        final r = parseAnyQrSecret(raw);
        expect(r.kind, QrSecretKind.bearby);
        final inner = parseQRSecretData(raw);
        expect(inner['seed'], startsWith('abandon'));
      });

      test(
          'round-trip: generateQRSecretData key → parseAnyQrSecret → parseQRSecretData recovers key',
          () {
        final raw = generateQRSecretData(chain: 'ETH', privateKey: _hex64);
        final r = parseAnyQrSecret(raw);
        expect(r.kind, QrSecretKind.bearby);
        expect(parseQRSecretData(raw)['key'], _hex64);
      });
    });

    // ── BIP39 mnemonic ───────────────────────────────────────────────────────

    group('bip39 mnemonic', () {
      test('12 words → bip39Mnemonic', () {
        final r = parseAnyQrSecret(_mnemonic12);
        expect(r.kind, QrSecretKind.bip39Mnemonic);
        expect(r.payload, _mnemonic12);
      });

      test('15 words → bip39Mnemonic', () {
        expect(parseAnyQrSecret(_mnemonic15).kind, QrSecretKind.bip39Mnemonic);
      });

      test('18 words → bip39Mnemonic', () {
        expect(parseAnyQrSecret(_mnemonic18).kind, QrSecretKind.bip39Mnemonic);
      });

      test('21 words → bip39Mnemonic', () {
        expect(parseAnyQrSecret(_mnemonic21).kind, QrSecretKind.bip39Mnemonic);
      });

      test('24 words → bip39Mnemonic', () {
        expect(parseAnyQrSecret(_mnemonic24).kind, QrSecretKind.bip39Mnemonic);
      });

      test('multi-space/leading/trailing whitespace → payload normalized', () {
        final r = parseAnyQrSecret(
          '  abandon  abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about  ',
        );
        expect(r.kind, QrSecretKind.bip39Mnemonic);
        expect(r.payload, _mnemonic12);
      });

      test('11 words → unknown', () {
        const eleven =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';
        expect(parseAnyQrSecret(eleven).kind, QrSecretKind.unknown);
      });

      test('13 words → unknown', () {
        const thirteen =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about extra';
        expect(parseAnyQrSecret(thirteen).kind, QrSecretKind.unknown);
      });

      test('12 words with a digit → unknown', () {
        const withDigit =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon 12345';
        expect(parseAnyQrSecret(withDigit).kind, QrSecretKind.unknown);
      });

      test('12 uppercase words → unknown', () {
        const upper =
            'ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABANDON ABOUT';
        expect(parseAnyQrSecret(upper).kind, QrSecretKind.unknown);
      });
    });

    // ── WIF private key ───────────────────────────────────────────────────────

    group('WIF private key', () {
      test('compressed WIF starting with K → wifPrivateKey', () {
        final r = parseAnyQrSecret(_wifK);
        expect(r.kind, QrSecretKind.wifPrivateKey);
        expect(r.payload, _wifK);
      });

      test('compressed WIF starting with L → wifPrivateKey', () {
        final r = parseAnyQrSecret(_wifL);
        expect(r.kind, QrSecretKind.wifPrivateKey);
        expect(r.payload, _wifL);
      });

      test('uncompressed WIF starting with 5 → wifPrivateKey', () {
        final r = parseAnyQrSecret(_wif5);
        expect(r.kind, QrSecretKind.wifPrivateKey);
        expect(r.payload, _wif5);
      });

      test('WIF with surrounding whitespace → trimmed payload', () {
        final r = parseAnyQrSecret('  $_wifK  ');
        expect(r.kind, QrSecretKind.wifPrivateKey);
        expect(r.payload, _wifK);
      });

      test('K-prefix but 51 chars → unknown', () {
        final short = _wifK.substring(0, 51); // one char short
        expect(parseAnyQrSecret(short).kind, QrSecretKind.unknown);
      });

      test('K-prefix but 53 chars → unknown', () {
        final long = '${_wifK}X';
        expect(parseAnyQrSecret(long).kind, QrSecretKind.unknown);
      });

      test('5-prefix but 52 chars → unknown', () {
        final wrong = '${_wif5}X';
        expect(parseAnyQrSecret(wrong).kind, QrSecretKind.unknown);
      });

      test('invalid base58 char 0 in WIF → unknown', () {
        // Replace last char with '0' (not in base58 alphabet)
        final invalid = '${_wifK.substring(0, 51)}0';
        expect(parseAnyQrSecret(invalid).kind, QrSecretKind.unknown);
      });
    });

    // ── hex private key ───────────────────────────────────────────────────────

    group('hex private key', () {
      test('64 lowercase hex → hexPrivateKey, payload preserved', () {
        final r = parseAnyQrSecret(_hex64);
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload, _hex64);
      });

      test('64 uppercase hex → hexPrivateKey, payload normalized to lowercase',
          () {
        final r = parseAnyQrSecret(_hex64.toUpperCase());
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload, _hex64);
      });

      test('64 mixed-case hex → hexPrivateKey, payload normalized', () {
        final mixed = _hex64.replaceRange(0, 4, 'DEAD');
        final r = parseAnyQrSecret(mixed);
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload, _hex64);
      });

      test('0x-prefixed 64 hex → hexPrivateKey, 0x stripped', () {
        final r = parseAnyQrSecret('0x$_hex64');
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload, _hex64);
        expect(r.payload!.length, 64);
      });

      test('0X-prefixed 64 hex → hexPrivateKey', () {
        final r = parseAnyQrSecret('0X$_hex64');
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload!.length, 64);
      });

      test('hex with surrounding whitespace → hexPrivateKey', () {
        final r = parseAnyQrSecret('  $_hex64  ');
        expect(r.kind, QrSecretKind.hexPrivateKey);
        expect(r.payload, _hex64);
      });

      test('63 hex chars → unknown', () {
        expect(
            parseAnyQrSecret(_hex64.substring(1)).kind, QrSecretKind.unknown);
      });

      test('65 hex chars → unknown', () {
        expect(parseAnyQrSecret('${_hex64}f').kind, QrSecretKind.unknown);
      });

      test('64 chars with non-hex char → unknown', () {
        final bad = 'x${_hex64.substring(1)}';
        expect(parseAnyQrSecret(bad).kind, QrSecretKind.unknown);
      });

      test('0x + 63 hex chars → unknown', () {
        expect(
          parseAnyQrSecret('0x${_hex64.substring(1)}').kind,
          QrSecretKind.unknown,
        );
      });
    });

    // ── unknown / edge cases ─────────────────────────────────────────────────

    group('unknown and edge cases', () {
      test('empty string → unknown', () {
        expect(parseAnyQrSecret('').kind, QrSecretKind.unknown);
      });

      test('whitespace-only → unknown', () {
        expect(parseAnyQrSecret('   ').kind, QrSecretKind.unknown);
      });

      test('plain payment URL with address → unknown', () {
        expect(
          parseAnyQrSecret('ETH:0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045')
              .kind,
          QrSecretKind.unknown,
        );
      });

      test('payment URL with amount → unknown', () {
        expect(
          parseAnyQrSecret('ETH:0xaddress?amount=1.5').kind,
          QrSecretKind.unknown,
        );
      });

      test('random text → unknown', () {
        expect(parseAnyQrSecret('hello world').kind, QrSecretKind.unknown);
      });

      test('https URL → unknown', () {
        expect(
          parseAnyQrSecret('https://example.com/wallet?seed=test').kind,
          QrSecretKind.unknown,
        );
      });

      test('JSON string → unknown', () {
        expect(parseAnyQrSecret('{"key": "value"}').kind, QrSecretKind.unknown);
      });

      test('single BIP39 word → unknown', () {
        expect(parseAnyQrSecret('abandon').kind, QrSecretKind.unknown);
      });

      test('32-char hex (too short for private key) → unknown', () {
        expect(parseAnyQrSecret('deadbeefdeadbeefdeadbeefdeadbeef').kind,
            QrSecretKind.unknown);
      });
    });

    // ── format priority / disambiguation ─────────────────────────────────────

    group('format priority', () {
      test('bearby with 12-word seed beats bip39 detection', () {
        const raw =
            'ETH:?seed=abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        final r = parseAnyQrSecret(raw);
        expect(r.kind, QrSecretKind.bearby);
        expect(r.chain, 'ETH');
      });

      test('bearby with 64-char hex key beats hex detection', () {
        final r = parseAnyQrSecret('ETH:?key=$_hex64');
        expect(r.kind, QrSecretKind.bearby);
      });

      test('all-hex 64-char string → hexPrivateKey, not wifPrivateKey', () {
        // All-hex chars cannot satisfy WIF prefix (K/L/5) + base58 charset rules
        const allHex =
            'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
        final r = parseAnyQrSecret(allHex);
        expect(r.kind, QrSecretKind.hexPrivateKey);
      });
    });

    // ── per-chain bearby round-trips ──────────────────────────────────────────

    group('per-chain bearby round-trips', () {
      for (final chain in _chains) {
        test('$chain seed round-trip', () {
          final qr =
              generateQRSecretData(chain: chain, seedPhrase: _mnemonic12);
          final r = parseAnyQrSecret(qr);
          expect(r.kind, QrSecretKind.bearby);
          expect(r.chain, chain);
          expect(parseQRSecretData(qr)['seed'], _mnemonic12);
        });

        test('$chain key round-trip', () {
          final qr = generateQRSecretData(chain: chain, privateKey: _hex64);
          final r = parseAnyQrSecret(qr);
          expect(r.kind, QrSecretKind.bearby);
          expect(r.chain, chain);
          expect(parseQRSecretData(qr)['key'], _hex64);
        });
      }
    });
  });
}
