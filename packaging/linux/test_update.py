"""Exercise the privileged helper in a mount/user namespace with no host writes."""

import hashlib
import pathlib
import shutil
import subprocess
import tempfile
import unittest


class UpdateHelperTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sora-helper-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.downloads = self.root / "downloads"
        self.downloads.mkdir()
        shutil.copyfile(pathlib.Path(__file__).with_name("sora-update"), self.root / "sora-update")

    def script(self, name, body):
        target = self.root / name
        target.write_text("#!/bin/sh\nset -eu\n" + body + "\n")
        target.chmod(0o755)
        return target

    def prepare(self, format):
        files = {
            "deb": ["sora-core_1.0.5_amd64.deb", "sora_1.0.5_amd64.deb"],
            "rpm": ["sora-core-1.0.5-1.x86_64.rpm", "sora-1.0.5-1.x86_64.rpm"],
            "arch": ["sora-core-1.0.5-1-x86_64.pkg.tar.zst", "sora-1.0.5-1-x86_64.pkg.tar.zst"],
        }[format]
        checksums = []
        for name in files:
            data = ("Package fixture " + name).encode()
            (self.downloads / name).write_bytes(data)
            checksums.append(hashlib.sha256(data).hexdigest() + "  " + name + "\n")
        (self.downloads / "SHA256SUMS").write_text("".join(checksums))
        return files

    def run_helper(self, format, version="1.0.5", bad_metadata=False, zypper=False, dependency_failure=False):
        recorder = 'printf "%s\\n" "$@" > /tmp/test/calls'
        scripts = {
            "dpkg-query": 'case "$1" in -S) echo "sora: /usr/lib/sora/app/sora";; -W) echo installed;; *) exit 1;; esac',
            "dpkg-deb": 'case "$3" in Package) name=${2##*/}; echo "${name%%_*}";; Version) echo "${TEST_VERSION:-1.0.5}";; Architecture) echo amd64;; esac',
            "rpm": 'case "$1" in -qf) echo sora;; -q) printf "sora\\nsora-core\\n";; -qp) name=${4##*/}; printf "%s %s-1 x86_64\\n" "${name%-1.0.5-1.x86_64.rpm}" "${TEST_VERSION:-1.0.5}";; *) exit 1;; esac',
            "pacman": 'case "$1" in -Qoq) echo sora;; -Q) printf "sora\\nsora-core\\n";; -Qp) name=${2##*/}; printf "%s %s-1\\n" "${name%-1.0.5-1-x86_64.pkg.tar.zst}" "${TEST_VERSION:-1.0.5}";; -S) printf "%s\\n" "$@" > /tmp/test/dependencies; [ "${TEST_DEPENDENCY_FAILURE:-0}" = 0 ];; -U) ' + recorder + ';; *) exit 1;; esac',
            "apt-get": recorder,
            "zypper" if zypper else "dnf": recorder,
        }
        command = [
            "bwrap", "--unshare-all", "--share-net", "--uid", "0", "--gid", "0", "--die-with-parent",
            "--ro-bind", "/", "/", "--tmpfs", "/run", "--tmpfs", "/tmp",
            "--dev", "/dev",
            "--tmpfs", "/var/tmp", "--tmpfs", "/usr/bin", "--bind", str(self.root), "/tmp/test",
        ]
        for name in ["sh", "id", "uname", "cp", "rm", "grep", "awk", "mktemp", "sha256sum"]:
            command += ["--ro-bind", str(pathlib.Path(shutil.which(name)).resolve()), "/usr/bin/" + name]
        for name, body in scripts.items():
            command += ["--ro-bind", str(self.script(name, body)), "/usr/bin/" + name]
        if bad_metadata:
            command += ["--setenv", "TEST_VERSION", "1.0.4"]
        if dependency_failure:
            command += ["--setenv", "TEST_DEPENDENCY_FAILURE", "1"]
        command += ["--", "/bin/sh", "/tmp/test/sora-update", format, version, "/tmp/test/downloads"]
        return subprocess.run(command, capture_output=True, text=True, timeout=10)

    def test_pair_in_one_transaction_for_every_manager(self):
        for format, zypper in [("deb", False), ("rpm", False), ("rpm", True), ("arch", False)]:
            with self.subTest(format=format, zypper=zypper):
                files = self.prepare(format)
                result = self.run_helper(format, zypper=zypper)
                self.assertEqual(result.returncode, 0, result.stderr)
                arguments = (self.root / "calls").read_text().splitlines()
                packages = [item for item in arguments if item.startswith("/var/tmp/")]
                self.assertEqual([pathlib.Path(item).name for item in packages], files)
                self.assertEqual(len(packages), 2)
                (self.root / "calls").unlink()

    def test_arch_dependency_failure_leaves_the_installed_pair_untouched(self):
        self.prepare("arch")
        result = self.run_helper("arch", dependency_failure=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "calls").exists())
        arguments = (self.root / "dependencies").read_text().splitlines()
        self.assertEqual(arguments, ["-S", "--noconfirm", "--needed", "gst-plugins-good"])

    def test_reject_corrupt_missing_duplicate_and_symlink_inputs(self):
        for problem in ["corrupt", "missing", "duplicate", "symlink", "metadata", "version", "format"]:
            with self.subTest(problem=problem):
                for item in self.downloads.iterdir():
                    item.unlink()
                files = self.prepare("deb")
                sums = self.downloads / "SHA256SUMS"
                if problem == "corrupt":
                    (self.downloads / files[0]).write_bytes(b"corrupt")
                elif problem == "missing":
                    (self.downloads / files[1]).unlink()
                elif problem == "duplicate":
                    sums.write_text(sums.read_text() * 2)
                elif problem == "symlink":
                    target = self.downloads / files[0]
                    target.unlink()
                    target.symlink_to(files[1])
                result = self.run_helper(
                    "unknown" if problem == "format" else "deb",
                    version="1.0.5;touch /tmp/test/escaped" if problem == "version" else "1.0.5",
                    bad_metadata=problem == "metadata",
                )
                self.assertNotIn("bwrap:", result.stderr)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse((self.root / "calls").exists())
                self.assertFalse((self.root / "escaped").exists())


if __name__ == "__main__":
    unittest.main()
