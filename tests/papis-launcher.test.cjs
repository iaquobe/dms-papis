const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

test('lists and searches documents returned by papis', () => {
    const repo = path.join(__dirname, '..');
    const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'dms-papis-launcher-'));
    try {
        fs.copyFileSync(path.join(repo, 'PapisLauncher.qml'), path.join(fixture, 'PapisLauncher.qml'));
        fs.copyFileSync(path.join(__dirname, 'shell.qml'), path.join(fixture, 'shell.qml'));
        fs.mkdirSync(path.join(fixture, 'Services'));
        fs.writeFileSync(path.join(fixture, 'Services/qmldir'), 'module qs.Services\nsingleton ToastService 1.0 ToastService.qml\n');
        fs.writeFileSync(path.join(fixture, 'Services/ToastService.qml'), 'pragma Singleton\nimport QtQuick\nQtObject { function showInfo(message) {} }\n');

        // Fake papis: verify the arguments and print tab-separated documents.
        const bin = path.join(fixture, 'bin');
        fs.mkdirSync(bin);
        fs.writeFileSync(path.join(bin, 'papis'), [
            '#!/bin/sh',
            '[ "$1 $2" = "list --all" ] || { echo "unexpected args: $*" >&2; exit 2; }',
            'printf "id1\\tAttention Is All You Need\\tVaswani, Ashish\\t2017\\n"',
            'printf "id2\\tThe Art of Computer Programming\\tKnuth, Donald\\t1968\\n"',
            'printf "id3\\tUnrelated paper on attention spans\\t\\t\\n"',
            'echo "[INFO] noise on stderr" >&2',
        ].join('\n') + '\n', {mode: 0o755});

        const result = spawnSync('qs', ['-p', path.join(fixture, 'shell.qml')], {
            encoding: 'utf8', timeout: 60000,
            env: {...process.env, PATH: bin + ':' + process.env.PATH, QT_QPA_PLATFORM: 'offscreen',
                  PAPIS_TEST_RESULT: path.join(fixture, 'result.txt')},
        });
        assert.ifError(result.error);
        assert.equal(result.status, 0, result.stdout + result.stderr);
        assert.equal(fs.readFileSync(path.join(fixture, 'result.txt'), 'utf8'), 'passed');
    } finally {
        fs.rmSync(fixture, {recursive: true});
    }
});
