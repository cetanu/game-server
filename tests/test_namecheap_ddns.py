import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

spec = importlib.util.spec_from_file_location("ddns", Path(__file__).resolve().parents[1] / "scripts/namecheap_ddns.py")
ddns = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ddns)
SUCCESS = b'<interface-response><ErrCount>0</ErrCount><Done>true</Done><IP>8.8.8.8</IP></interface-response>'


class DDNSTest(unittest.TestCase):
    def test_updates_both_hosts_with_encoded_password_and_detected_ip(self):
        with patch.dict(ddns.os.environ, NAMECHEAP_DDNS_PASSWORD="secret&+?"), patch.object(ddns, "fetch", side_effect=[b"8.8.8.8", SUCCESS, SUCCESS]) as fetch:
            with contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(ddns.main([]), 0)
        for call, host in zip(fetch.call_args_list[1:], ddns.HOSTS):
            query = parse_qs(urlsplit(call.args[0]).query)
            self.assertEqual(query, dict(host=[host], domain=["vsyrakis.dev"], password=["secret&+?"], ip=["8.8.8.8"]))
        self.assertNotIn("secret", output.getvalue())

    def test_utf16_declaration_with_utf8_bytes_and_genuine_utf16(self):
        text = '<?xml version="1.0" encoding="utf-16"?>' + SUCCESS.decode("ascii")
        for payload in (text.encode("utf-8"), text.encode("utf-16")):
            with self.subTest(payload=payload[:40]), patch.object(ddns, "fetch", return_value=payload):
                ddns.update("valheim", "secret", "8.8.8.8")

    def test_provider_rejection_does_not_hide_failure_or_skip_other_host(self):
        rejected = b'<interface-response><ErrCount>1</ErrCount><Done>false</Done><Err1>secret</Err1></interface-response>'
        with patch.dict(ddns.os.environ, NAMECHEAP_DDNS_PASSWORD="secret"), patch.object(ddns, "fetch", side_effect=[rejected, SUCCESS]) as fetch:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()) as errors:
                self.assertEqual(ddns.main(["--ip", "8.8.8.8"]), 1)
            self.assertEqual(fetch.call_count, 2)
            self.assertNotIn("secret", errors.getvalue())

    def test_malformed_or_incomplete_xml_is_not_success(self):
        for response in (b"not XML", b"<interface-response><ErrCount>0</ErrCount></interface-response>"):
            with patch.object(ddns, "fetch", return_value=response):
                with self.assertRaises(ddns.UpdateError):
                    ddns.update("valheim", "secret", "8.8.8.8")

    def test_missing_credential_fails_without_network(self):
        with tempfile.TemporaryDirectory() as folder:
            config = Path(folder, "config.json")
            config.write_text('{"ddns_password": ""}')
            with patch.dict(ddns.os.environ, NAMECHEAP_DDNS_PASSWORD=""), patch.object(ddns, "fetch") as fetch:
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(ddns.main(["--config", str(config)]), 1)
                fetch.assert_not_called()

    def test_check_reads_config_without_network(self):
        with tempfile.TemporaryDirectory() as folder:
            config = Path(folder, "config.json")
            config.write_text('{"ddns_password": "secret"}')
            with patch.dict(ddns.os.environ, NAMECHEAP_DDNS_PASSWORD=""), patch.object(ddns, "fetch") as fetch:
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(ddns.main(["--config", str(config), "--check"]), 0)
                fetch.assert_not_called()

    def test_bad_or_private_ip_is_rejected(self):
        for value in ("no-ip", "192.168.1.1", "::1"):
            with self.assertRaises(ddns.UpdateError):
                ddns.ipv4(value)

    def test_transport_error_does_not_leak_url(self):
        with patch.object(ddns.urllib.request, "urlopen", side_effect=OSError("https://example/?password=secret")):
            with self.assertRaises(ddns.UpdateError) as error:
                ddns.fetch("https://example/?password=secret")
            self.assertNotIn("secret", str(error.exception))


if __name__ == "__main__":
    unittest.main()
